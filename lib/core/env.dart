/// Base URL of the Django API (the only backend the app talks to).
///
/// Apuntando al backend desplegado en AWS (EC2 + Caddy HTTPS sslip.io) para
/// probar la app contra el server real. Al ser HTTPS no hay problema de
/// cleartext en Android (ya no se usa 10.0.2.2).
///
/// Para volver al backend local, descomenta el bloque de abajo:
///   if (kIsWeb) return 'http://localhost:8000/api';
///   if (defaultTargetPlatform == TargetPlatform.android) {
///     return 'http://10.0.2.2:8000/api';
///   }
///   return 'http://localhost:8000/api';
String apiBase() {
  return 'https://3-95-35-172.sslip.io/api';
}
