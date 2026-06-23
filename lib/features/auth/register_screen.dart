import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/api.dart';
import '../../core/auth.dart';
import '../../core/theme.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  String _role = 'cliente';
  bool _loading = false;
  String? _error;

  Future<void> _submit() async {
    setState(() { _loading = true; _error = null; });
    try {
      await context.read<AuthService>().register({
        'email': _email.text.trim(),
        'password': _password.text,
        'full_name': _name.text.trim(),
        'phone': _phone.text.trim(),
        'role': _role,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cuenta creada, inicia sesión.')));
        context.go('/login');
      }
    } on ApiError catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: GradientBackground(child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Text('Crea tu cuenta', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 16),
                  if (_error != null)
                    Container(
                      width: double.infinity, margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(11),
                      decoration: BoxDecoration(color: kDanger.withValues(alpha: 0.12),
                          border: Border.all(color: kDanger.withValues(alpha: 0.4)), borderRadius: BorderRadius.circular(10)),
                      child: Text(_error!, style: const TextStyle(color: Color(0xFFFFB4B8))),
                    ),
                  TextField(controller: _name, decoration: const InputDecoration(labelText: 'Nombre completo')),
                  const SizedBox(height: 12),
                  TextField(controller: _email, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Email')),
                  const SizedBox(height: 12),
                  TextField(controller: _phone, decoration: const InputDecoration(labelText: 'Teléfono (opcional)')),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _role,
                    dropdownColor: kSurface2,
                    decoration: const InputDecoration(labelText: 'Rol'),
                    items: const [
                      DropdownMenuItem(value: 'cliente', child: Text('Cliente')),
                      DropdownMenuItem(value: 'arquitecto', child: Text('Arquitecto')),
                      DropdownMenuItem(value: 'ingeniero', child: Text('Ingeniero')),
                    ],
                    onChanged: (v) => setState(() => _role = v ?? 'cliente'),
                  ),
                  const SizedBox(height: 12),
                  TextField(controller: _password, obscureText: true, decoration: const InputDecoration(labelText: 'Contraseña')),
                  const SizedBox(height: 18),
                  GradientButton(_loading ? 'Creando…' : 'Registrarme', onPressed: _loading ? null : _submit),
                  TextButton(onPressed: () => context.go('/login'), child: const Text('Ya tengo cuenta')),
                ]),
              ),
            ),
          ),
        ),
      )),
    );
  }
}
