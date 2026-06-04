import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/api.dart';
import '../../core/auth.dart';
import '../../core/theme.dart';

class _QuickUser {
  final String label, email, password, initial;
  const _QuickUser(this.label, this.email, this.password, this.initial);
}

const _quickUsers = [
  _QuickUser('Administrador', 'admin@arketo.dev', 'Admin12345', 'A'),
  _QuickUser('Cliente', 'cliente@arketo.dev', 'Demo12345', 'C'),
  _QuickUser('Arquitecto', 'arquitecto@arketo.dev', 'Demo12345', 'Q'),
  _QuickUser('Ingeniero', 'ingeniero@arketo.dev', 'Demo12345', 'I'),
  _QuickUser('Arq. Carla', 'carla@arketo.dev', 'Demo12345', 'C'),
  _QuickUser('Ing. Sofía', 'sofia@arketo.dev', 'Demo12345', 'S'),
];

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;
  String? _error;

  void _pick(_QuickUser u) {
    _email.text = u.email;
    _password.text = u.password;
    setState(() => _error = null);
  }

  Future<void> _submit() async {
    setState(() { _loading = true; _error = null; });
    try {
      await context.read<AuthService>().login(_email.text.trim(), _password.text);
      if (mounted) context.go('/');
    } on ApiError catch (e) {
      setState(() => _error = e.status == 401 ? 'Credenciales inválidas.' : e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GradientBackground(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      const BrandLogo(),
                      const SizedBox(height: 14),
                      const Text('Arketo', style: TextStyle(fontSize: 27, fontWeight: FontWeight.w800)),
                      const Text('Inteligencia espacial para tus obras',
                          textAlign: TextAlign.center, style: TextStyle(color: kMuted)),
                      const SizedBox(height: 20),
                      if (_error != null) _ErrorBox(_error!),
                      TextField(controller: _email, keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.mail_outline))),
                      const SizedBox(height: 12),
                      TextField(controller: _password, obscureText: true,
                          decoration: const InputDecoration(labelText: 'Contraseña', prefixIcon: Icon(Icons.lock_outline))),
                      const SizedBox(height: 20),
                      GradientButton(_loading ? 'Entrando…' : 'Entrar', onPressed: _loading ? null : _submit),
                      TextButton(onPressed: () => context.go('/register'),
                          child: const Text('¿No tienes cuenta? Regístrate')),
                    ]),
                  ),
                ),
                const SizedBox(height: 12),
                _QuickAccess(onPick: _pick),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

class _QuickAccess extends StatelessWidget {
  final void Function(_QuickUser) onPick;
  const _QuickAccess({required this.onPick});
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Text('ACCESO RÁPIDO', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1, color: kMuted)),
            const SizedBox(width: 8),
            const StatusChip('active'), // green DEMO pill
          ]),
          const SizedBox(height: 12),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final u in _quickUsers)
              SizedBox(
                width: (MediaQuery.of(context).size.width.clamp(0, 420) - 32 - 8) / 2 - 1,
                child: Material(
                  color: kSurface2,
                  borderRadius: BorderRadius.circular(10),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () => onPick(u),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: kBorder),
                      ),
                      child: Row(children: [
                        Container(
                          width: 28, height: 28,
                          decoration: const BoxDecoration(gradient: kBrandGradient, shape: BoxShape.circle),
                          child: Center(child: Text(u.initial, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12))),
                        ),
                        const SizedBox(width: 8),
                        Expanded(child: Text(u.label, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
                      ]),
                    ),
                  ),
                ),
              ),
          ]),
          const Padding(
            padding: EdgeInsets.only(top: 10),
            child: Text('Elige un perfil para autocompletar, luego pulsa Entrar.', style: TextStyle(color: kFaint, fontSize: 12)),
          ),
        ]),
      ),
    );
  }
}

class _ErrorBox extends StatelessWidget {
  final String message;
  const _ErrorBox(this.message);
  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(11),
        decoration: BoxDecoration(
          color: kDanger.withValues(alpha: 0.12),
          border: Border.all(color: kDanger.withValues(alpha: 0.4)),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(message, style: const TextStyle(color: Color(0xFFFFB4B8))),
      );
}
