import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Persists JWT tokens securely on the device.
class TokenStore {
  static const _access = 'arketo.access';
  static const _refresh = 'arketo.refresh';
  final _storage = const FlutterSecureStorage();

  Future<String?> get access => _storage.read(key: _access);
  Future<String?> get refresh => _storage.read(key: _refresh);

  Future<void> save(String access, String refresh) async {
    await _storage.write(key: _access, value: access);
    await _storage.write(key: _refresh, value: refresh);
  }

  Future<void> saveAccess(String access) =>
      _storage.write(key: _access, value: access);

  Future<void> clear() async {
    await _storage.delete(key: _access);
    await _storage.delete(key: _refresh);
  }
}
