import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/api.dart';
import '../../core/auth.dart';
import '../../core/theme.dart';

/// HU-3 — Editar perfil (nombre y teléfono) vía PATCH /auth/me.
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});
  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late final TextEditingController _name;
  late final TextEditingController _phone;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final u = context.read<AuthService>().user;
    _name = TextEditingController(text: u?.fullName ?? '');
    _phone = TextEditingController(text: u?.phone ?? '');
  }

  Future<void> _save() async {
    setState(() { _saving = true; _error = null; });
    try {
      await context.read<AuthService>().updateProfile({
        'full_name': _name.text.trim(),
        'phone': _phone.text.trim(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Perfil actualizado.')));
        context.pop();
      }
    } on ApiError catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Editar perfil')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_error != null)
            Padding(padding: const EdgeInsets.only(bottom: 12), child: Text(_error!, style: const TextStyle(color: kDanger))),
          TextField(controller: _name, decoration: const InputDecoration(labelText: 'Nombre completo')),
          const SizedBox(height: 12),
          TextField(controller: _phone, keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Teléfono')),
          const SizedBox(height: 18),
          GradientButton(_saving ? 'Guardando…' : 'Guardar cambios', icon: Icons.save_outlined,
              onPressed: _saving ? null : _save),
        ],
      ),
    );
  }
}
