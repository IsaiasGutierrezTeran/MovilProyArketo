import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api.dart';
import '../../core/models.dart';
import '../../core/theme.dart';

/// HU-14 — bandeja del invitado: invitaciones pendientes para aceptar/rechazar.
class InvitationsScreen extends StatefulWidget {
  const InvitationsScreen({super.key});
  @override
  State<InvitationsScreen> createState() => _InvitationsScreenState();
}

class _InvitationsScreenState extends State<InvitationsScreen> {
  List<Invitation> _invites = [];
  bool _loading = true;
  int? _busy;

  Api get _api => context.read<Api>();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final r = await _api.get('/invitations/');
      setState(() {
        _invites = (r as List).map((e) => Invitation.fromJson(e)).toList();
        _loading = false;
      });
    } on ApiError catch (e) {
      setState(() => _loading = false);
      _snack(e.message);
    }
  }

  Future<void> _accept(Invitation inv) async {
    setState(() => _busy = inv.id);
    try {
      await _api.post('/invitations/${inv.id}/accept/', {});
      setState(() {
        _invites.removeWhere((x) => x.id == inv.id);
        _busy = null;
      });
      _snack('Te uniste a "${inv.projectName}".');
    } on ApiError catch (e) {
      setState(() => _busy = null);
      _snack(e.message);
    }
  }

  Future<void> _decline(Invitation inv) async {
    setState(() => _busy = inv.id);
    try {
      await _api.post('/invitations/${inv.id}/decline/', {});
      setState(() {
        _invites.removeWhere((x) => x.id == inv.id);
        _busy = null;
      });
    } on ApiError catch (e) {
      setState(() => _busy = null);
      _snack(e.message);
    }
  }

  void _snack(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Invitaciones')),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: kPrimary))
          : RefreshIndicator(
              onRefresh: _load,
              child: _invites.isEmpty
                  ? ListView(
                      children: const [
                        Padding(
                          padding: EdgeInsets.all(24),
                          child: Text(
                            'No tienes invitaciones pendientes.',
                            style: TextStyle(color: kMuted),
                          ),
                        ),
                      ],
                    )
                  : ListView(
                      padding: const EdgeInsets.all(16),
                      children: _invites.map((inv) {
                        final busy = _busy == inv.id;
                        return Card(
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  inv.projectName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Te invitó ${inv.invitedByEmail ?? inv.ownerEmail} · rol ${inv.role}',
                                  style: const TextStyle(
                                    color: kMuted,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    TextButton(
                                      onPressed: busy
                                          ? null
                                          : () => _decline(inv),
                                      child: const Text('Rechazar'),
                                    ),
                                    const SizedBox(width: 8),
                                    FilledButton(
                                      onPressed: busy
                                          ? null
                                          : () => _accept(inv),
                                      child: Text(busy ? '…' : 'Aceptar'),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
            ),
    );
  }
}
