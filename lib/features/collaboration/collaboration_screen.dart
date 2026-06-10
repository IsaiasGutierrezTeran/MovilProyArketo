import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api.dart';
import '../../core/models.dart';
import '../../core/theme.dart';

/// HU-14 — Acceso compartido / colaboración: miembros + comentarios.
class CollaborationScreen extends StatefulWidget {
  final int projectId;
  const CollaborationScreen({super.key, required this.projectId});
  @override
  State<CollaborationScreen> createState() => _CollaborationScreenState();
}

class _CollaborationScreenState extends State<CollaborationScreen> {
  List<Member> _members = [];
  List<Comment> _comments = [];
  bool _loading = true;
  final _email = TextEditingController();
  String _role = 'editor';
  final _comment = TextEditingController();

  Api get _api => context.read<Api>();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final m = await _api.get('/projects/${widget.projectId}/members/');
    final c = await _api.page('/comments/', query: {'project': widget.projectId});
    setState(() {
      _members = (m as List).map((e) => Member.fromJson(e)).toList();
      _comments = c.items.map((e) => Comment.fromJson(e)).toList();
      _loading = false;
    });
  }

  Future<void> _invite() async {
    if (_email.text.trim().isEmpty) return;
    try {
      final d = await _api.post('/projects/${widget.projectId}/members/',
          {'email': _email.text.trim(), 'role': _role});
      setState(() { _members.add(Member.fromJson(d)); _email.clear(); });
    } on ApiError catch (e) {
      _snack(e.message);
    }
  }

  Future<void> _removeMember(Member m) async {
    try {
      await _api.delete('/projects/${widget.projectId}/members/${m.id}/');
      setState(() => _members.removeWhere((x) => x.id == m.id));
    } on ApiError catch (e) {
      _snack(e.message);
    }
  }

  Future<void> _addComment() async {
    if (_comment.text.trim().isEmpty) return;
    try {
      final d = await _api.post('/comments/', {'project': widget.projectId, 'body': _comment.text.trim()});
      setState(() { _comments.add(Comment.fromJson(d)); _comment.clear(); });
    } on ApiError catch (e) {
      _snack(e.message);
    }
  }

  void _snack(String m) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Colaboración')),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: kPrimary))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text('Colaboradores', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Row(children: [
                  Expanded(child: TextField(controller: _email, keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(labelText: 'Email del colaborador'))),
                  const SizedBox(width: 8),
                  DropdownButton<String>(
                    value: _role, dropdownColor: kSurface2, underline: const SizedBox.shrink(),
                    items: const [
                      DropdownMenuItem(value: 'editor', child: Text('Editor')),
                      DropdownMenuItem(value: 'viewer', child: Text('Lector')),
                    ],
                    onChanged: (v) => setState(() => _role = v ?? 'editor'),
                  ),
                  IconButton(icon: const Icon(Icons.person_add_alt_1), onPressed: _invite),
                ]),
                const SizedBox(height: 8),
                ..._members.map((m) => Card(child: ListTile(
                      leading: const Icon(Icons.person_outline),
                      title: Text(m.userEmail),
                      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                        StatusChip(m.role),
                        IconButton(icon: const Icon(Icons.delete_outline, color: kDanger),
                            onPressed: () => _removeMember(m)),
                      ]),
                    ))),
                if (_members.isEmpty)
                  const Padding(padding: EdgeInsets.all(8), child: Text('Aún sin colaboradores.', style: TextStyle(color: kMuted))),
                const SizedBox(height: 20),

                const Text('Comentarios', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                ..._comments.map((c) => Card(child: ListTile(
                      title: Text(c.body),
                      subtitle: Text(c.authorEmail, style: const TextStyle(fontSize: 12)),
                    ))),
                if (_comments.isEmpty)
                  const Padding(padding: EdgeInsets.all(8), child: Text('Sin comentarios.', style: TextStyle(color: kMuted))),
                const SizedBox(height: 8),
                Row(children: [
                  Expanded(child: TextField(controller: _comment,
                      decoration: const InputDecoration(labelText: 'Escribe un comentario…'))),
                  IconButton(icon: const Icon(Icons.send), onPressed: _addComment),
                ]),
              ],
            ),
    );
  }
}
