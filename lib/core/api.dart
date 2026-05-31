import 'package:dio/dio.dart';
import 'env.dart';
import 'token_store.dart';

/// Error surfaced to the UI: error.code / error.detail from the backend envelope.
class ApiError implements Exception {
  final String code;
  final dynamic detail;
  final int? status;
  ApiError(this.code, this.detail, this.status);

  String get message {
    if (detail is String) return detail as String;
    if (detail is Map) {
      final first = (detail as Map).values.first;
      if (first is List && first.isNotEmpty) return '${first.first}';
      return '$first';
    }
    return code;
  }

  @override
  String toString() => message;
}

const _authPaths = ['/auth/login', '/auth/register', '/auth/refresh'];

/// Thin HTTP layer that unwraps the `{success, data, meta}` envelope and
/// attaches the JWT (refreshing once on a 401).
class Api {
  late final Dio dio;
  final TokenStore tokens;

  Api(this.tokens) {
    dio = Dio(BaseOptions(
      baseUrl: apiBase(),
      connectTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 130), // model generation can be slow
    ));
    dio.interceptors.add(_AuthInterceptor(tokens, dio));
  }

  Future<dynamic> get(String path, {Map<String, dynamic>? query}) async {
    final r = await _wrap(() => dio.get(path, queryParameters: query));
    return r.data['data'];
  }

  Future<({List items, Map<String, dynamic>? pagination})> page(
      String path, {Map<String, dynamic>? query}) async {
    final r = await _wrap(() => dio.get(path, queryParameters: query));
    return (
      items: (r.data['data'] as List),
      pagination: (r.data['meta']?['pagination'] as Map<String, dynamic>?),
    );
  }

  Future<dynamic> post(String path, dynamic body) async {
    final r = await _wrap(() => dio.post(path, data: body));
    return r.data is Map ? r.data['data'] : null;
  }

  Future<dynamic> patch(String path, dynamic body) async {
    final r = await _wrap(() => dio.patch(path, data: body));
    return r.data is Map ? r.data['data'] : null;
  }

  Future<void> delete(String path) async {
    await _wrap(() => dio.delete(path));
  }

  Future<dynamic> postForm(String path, FormData form) async {
    final r = await _wrap(() => dio.post(path, data: form));
    return r.data is Map ? r.data['data'] : null;
  }

  Future<Response> _wrap(Future<Response> Function() call) async {
    try {
      return await call();
    } on DioException catch (e) {
      final data = e.response?.data;
      if (data is Map && data['error'] != null) {
        throw ApiError('${data['error']['code']}', data['error']['detail'], e.response?.statusCode);
      }
      throw ApiError('network_error', e.message ?? 'Sin conexión con el servidor', e.response?.statusCode);
    }
  }
}

class _AuthInterceptor extends Interceptor {
  final TokenStore tokens;
  final Dio dio;
  _AuthInterceptor(this.tokens, this.dio);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    if (!_authPaths.any((p) => options.path.contains(p))) {
      final t = await tokens.access;
      if (t != null) options.headers['Authorization'] = 'Bearer $t';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final isAuthCall = _authPaths.any((p) => err.requestOptions.path.contains(p));
    if (err.response?.statusCode == 401 && !isAuthCall) {
      final refresh = await tokens.refresh;
      if (refresh != null) {
        try {
          final bare = Dio(BaseOptions(baseUrl: apiBase()));
          final r = await bare.post('/auth/refresh', data: {'refresh': refresh});
          final data = r.data['data'];
          if (data['refresh'] != null) {
            await tokens.save(data['access'], data['refresh']);
          } else {
            await tokens.saveAccess(data['access']);
          }
          final req = err.requestOptions;
          req.headers['Authorization'] = 'Bearer ${data['access']}';
          final retried = await dio.fetch(req);
          return handler.resolve(retried);
        } catch (_) {
          await tokens.clear();
        }
      }
    }
    handler.next(err);
  }
}
