import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/api.dart';
import '../../core/models.dart';
import '../../core/theme.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late Future<DashboardSummary> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<DashboardSummary> _load() async =>
      DashboardSummary.fromJson(await context.read<Api>().get('/projects/dashboard/'));

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async => setState(() => _future = _load()),
      child: FutureBuilder<DashboardSummary>(
        future: _future,
        builder: (context, snap) {
          if (!snap.hasData) {
            return snap.hasError
                ? ListView(children: [Padding(padding: const EdgeInsets.all(24), child: Text('Error: ${snap.error}'))])
                : const Center(child: CircularProgressIndicator(color: kPrimary));
          }
          final d = snap.data!;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text('Dashboard', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
              const SizedBox(height: 14),
              Row(children: [
                _Stat('${d.total}', 'Proyectos', kPrimary, Icons.folder_rounded),
                const SizedBox(width: 12),
                _Stat('${d.byStatus['active'] ?? 0}', 'Activos', kSuccess, Icons.check_circle_rounded),
                const SizedBox(width: 12),
                _Stat('${d.byStatus['draft'] ?? 0}', 'Borradores', kMuted, Icons.edit_note_rounded),
              ]),
              const SizedBox(height: 20),
              const Text('Recientes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              ...d.recent.map((p) => Card(
                    child: ListTile(
                      leading: const _ProjIcon(),
                      title: Text(p.name),
                      subtitle: Text(p.description.isEmpty ? 'Sin descripción' : p.description,
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                      trailing: StatusChip(p.status),
                      onTap: () => context.push('/projects/${p.id}'),
                    ),
                  )),
              if (d.recent.isEmpty) const Padding(padding: EdgeInsets.all(16), child: Text('Aún no hay proyectos.', style: TextStyle(color: kMuted))),
            ],
          );
        },
      ),
    );
  }
}

class _ProjIcon extends StatelessWidget {
  const _ProjIcon();
  @override
  Widget build(BuildContext context) => Container(
        width: 40, height: 40,
        decoration: BoxDecoration(color: kPrimary.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(11)),
        child: const Icon(Icons.home_work_outlined, color: kPrimary2, size: 20),
      );
}

class _Stat extends StatelessWidget {
  final String value, label;
  final Color color;
  final IconData icon;
  const _Stat(this.value, this.label, this.color, this.icon);
  @override
  Widget build(BuildContext context) => Expanded(
        child: Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
            child: Column(children: [
              Container(
                width: 38, height: 38,
                decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(11)),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(height: 8),
              Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: color)),
              Text(label, style: const TextStyle(color: kMuted, fontSize: 12)),
            ]),
          ),
        ),
      );
}
