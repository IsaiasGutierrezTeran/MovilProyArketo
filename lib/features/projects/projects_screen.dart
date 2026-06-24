import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/api.dart';
import '../../core/models.dart';
import '../../core/sync_service.dart';
import '../../core/theme.dart';

class ProjectsScreen extends StatefulWidget {
  const ProjectsScreen({super.key});
  @override
  State<ProjectsScreen> createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends State<ProjectsScreen> {
  List<Project> _projects = [];
  bool _loading = true;
  bool _syncing = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  // HU-16 — sincronización incremental (delta) bajo demanda.
  Future<void> _sync() async {
    setState(() => _syncing = true);
    try {
      final r = await SyncService(context.read<Api>()).syncProjects();
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              r.count == 0
                  ? 'Todo al día.'
                  : '${r.count} proyecto(s) sincronizado(s).',
            ),
          ),
        );
      }
    } on ApiError catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _syncing = false);
    }
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final r = await context.read<Api>().page('/projects/');
    setState(() {
      _projects = r.items.map((e) => Project.fromJson(e)).toList();
      _loading = false;
    });
  }

  Future<void> _create() async {
    final api = context.read<Api>();
    final name = TextEditingController();
    final desc = TextEditingController();
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: kSurface,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Nuevo proyecto',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: name,
              decoration: const InputDecoration(labelText: 'Nombre'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: desc,
              decoration: const InputDecoration(labelText: 'Descripción'),
              maxLines: 2,
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Crear'),
              ),
            ),
          ],
        ),
      ),
    );
    if (ok == true && name.text.trim().isNotEmpty) {
      final p = await api.post('/projects/', {
        'name': name.text.trim(),
        'description': desc.text.trim(),
      });
      setState(() => _projects.insert(0, Project.fromJson(p)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: kPrimary,
        onPressed: _create,
        icon: const Icon(Icons.add),
        label: const Text('Nuevo'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: kPrimary))
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Proyectos',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Sincronizar',
                        onPressed: _syncing ? null : _sync,
                        icon: _syncing
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.sync),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (_projects.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        'No hay proyectos.',
                        style: TextStyle(color: kMuted),
                      ),
                    ),
                  ..._projects.map(
                    (p) => Card(
                      child: ListTile(
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: kPrimary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(11),
                          ),
                          child: const Icon(
                            Icons.home_work_outlined,
                            color: kPrimary2,
                            size: 20,
                          ),
                        ),
                        title: Text(p.name),
                        subtitle: Text(
                          p.ownerEmail,
                          style: const TextStyle(fontSize: 12),
                        ),
                        trailing: StatusChip(p.status),
                        onTap: () => context.push('/projects/${p.id}'),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
