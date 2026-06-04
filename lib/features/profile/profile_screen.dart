import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/auth.dart';
import '../../core/theme.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final u = auth.user;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const SizedBox(height: 8),
        Center(child: CircleAvatar(
          radius: 38, backgroundColor: kPrimary,
          child: Text(_initials(u?.fullName ?? u?.email ?? '?'),
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: Colors.white)),
        )),
        const SizedBox(height: 12),
        Center(child: Text(u?.fullName ?? '', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700))),
        Center(child: Text(u?.email ?? '', style: const TextStyle(color: kMuted))),
        const SizedBox(height: 20),
        Card(child: Column(children: [
          _row('Rol', u?.role ?? ''),
          const Divider(height: 1, color: kBorder),
          _row('Plan', u?.subscriptionPlan ?? 'free'),
          const Divider(height: 1, color: kBorder),
          _row('Teléfono', (u?.phone.isEmpty ?? true) ? '—' : u!.phone),
        ])),
        const SizedBox(height: 12),
        Card(child: Column(children: [
          ListTile(
            leading: const Icon(Icons.edit_outlined),
            title: const Text('Editar perfil'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/profile/edit'),
          ),
          const Divider(height: 1, color: kBorder),
          ListTile(
            leading: const Icon(Icons.workspace_premium_outlined),
            title: const Text('Planes y pagos'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/billing'),
          ),
        ])),
        const SizedBox(height: 20),
        FilledButton.icon(
          style: FilledButton.styleFrom(backgroundColor: kDanger),
          onPressed: () async {
            await auth.logout();
            if (context.mounted) context.go('/login');
          },
          icon: const Icon(Icons.logout),
          label: const Text('Cerrar sesión'),
        ),
      ],
    );
  }

  Widget _row(String k, String v) => ListTile(
        title: Text(k, style: const TextStyle(color: kMuted)),
        trailing: Text(v, style: const TextStyle(fontWeight: FontWeight.w600)),
      );

  String _initials(String s) {
    final parts = s.trim().split(RegExp(r'[\s@.]+')).where((e) => e.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    final a = parts[0].isNotEmpty ? parts[0][0] : '';
    final b = parts.length > 1 && parts[1].isNotEmpty ? parts[1][0] : '';
    return (a + b).toUpperCase();
  }
}
