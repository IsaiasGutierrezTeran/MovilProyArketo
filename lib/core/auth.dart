import 'package:flutter/foundation.dart';
import 'api.dart';
import 'models.dart';
import 'token_store.dart';

/// App-wide auth state + actions (mirrors the web Auth service).
class AuthService extends ChangeNotifier {
  final Api api;
  final TokenStore tokens;
  AuthService(this.api, this.tokens);

  User? user;
  bool ready = false;

  bool get isAuthed => user != null;

  Future<void> bootstrap() async {
    final t = await tokens.access;
    if (t != null) {
      try {
        user = User.fromJson(await api.get('/auth/me'));
      } catch (_) {
        await tokens.clear();
      }
    }
    ready = true;
    notifyListeners();
  }

  Future<void> login(String email, String password) async {
    final d = await api.post('/auth/login', {'email': email, 'password': password});
    await tokens.save(d['access'], d['refresh']);
    user = User.fromJson(d['user']);
    notifyListeners();
  }

  Future<void> register(Map<String, dynamic> body) async {
    await api.post('/auth/register', body);
  }

  /// HU-3 — edita el perfil (PATCH /auth/me) y refresca el usuario en memoria.
  Future<void> updateProfile(Map<String, dynamic> body) async {
    final d = await api.patch('/auth/me', body);
    user = User.fromJson(d);
    notifyListeners();
  }

  /// Refresca el usuario desde /auth/me (plan/rol actuales, p. ej. tras suscribir).
  Future<void> refreshUser() async {
    try {
      user = User.fromJson(await api.get('/auth/me'));
      notifyListeners();
    } catch (_) {/* mantiene el usuario actual */}
  }

  Future<void> logout() async {
    final r = await tokens.refresh;
    if (r != null) {
      try {
        await api.post('/auth/logout', {'refresh': r});
      } catch (_) {}
    }
    await tokens.clear();
    user = null;
    notifyListeners();
  }
}
