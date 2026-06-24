import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'api.dart';
import 'models.dart';

class SyncResult {
  final int count;
  final List<Project> changed;
  SyncResult(this.count, this.changed);
}

/// HU-16 — Sincronización incremental.
/// Persiste el `server_time` de la última sync y pide al backend solo lo que
/// cambió desde entonces (delta) vía GET /projects/sync/?since=.
class SyncService {
  final Api api;
  final _storage = const FlutterSecureStorage();
  static const _key = 'arketo.lastSync';

  SyncService(this.api);

  Future<SyncResult> syncProjects() async {
    final since = await _storage.read(key: _key);
    final d = await api.get(
      '/projects/sync/',
      query: {if (since != null) 'since': since},
    );
    if (d['server_time'] != null) {
      await _storage.write(key: _key, value: '${d['server_time']}');
    }
    final changed = ((d['changed'] ?? []) as List)
        .map((e) => Project.fromJson(e))
        .toList();
    return SyncResult(d['count'] ?? changed.length, changed);
  }

  Future<void> reset() => _storage.delete(key: _key);
}
