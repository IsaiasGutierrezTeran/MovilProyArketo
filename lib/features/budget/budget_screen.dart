import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api.dart';
import '../../core/auth.dart';
import '../../core/models.dart';
import '../../core/theme.dart';

/// HU-12 — Ver y generar presupuesto de obra (consulta + creación).
class BudgetScreen extends StatefulWidget {
  final int projectId;
  const BudgetScreen({super.key, required this.projectId});
  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  List<Budget> _budgets = [];
  List<MaterialItem> _materials = [];
  bool _loading = true;
  int? _modelId; // modelo 3D actual del proyecto (para estimar)

  Api get _api => context.read<Api>();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final b = await _api.page(
      '/budgets/',
      query: {'project': widget.projectId},
    );
    final m = await _api.page('/materials/', query: {'page_size': 100});
    final mods = await _api.page(
      '/models3d/',
      query: {'project': widget.projectId},
    );
    int? mid;
    for (final x in mods.items) {
      if (x['is_current'] == true) {
        mid = x['id'] as int?;
        break;
      }
    }
    mid ??= mods.items.isNotEmpty ? mods.items.first['id'] as int? : null;
    setState(() {
      _budgets = b.items.map((e) => Budget.fromJson(e)).toList();
      _materials = m.items.map((e) => MaterialItem.fromJson(e)).toList();
      _modelId = mid;
      _loading = false;
    });
  }

  /// Estima materiales desde la geometría del modelo 3D y crea un borrador (Bs).
  Future<void> _estimate() async {
    final mid = _modelId;
    if (mid == null) return;
    try {
      await _api.post('/budgets/estimate/', {'model3d': mid});
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Borrador estimado creado desde el modelo 3D.'),
          ),
        );
      }
    } on ApiError catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _create() async {
    if (_materials.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay materiales en el catálogo.')),
      );
      return;
    }
    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: kSurface,
      builder: (_) => _NewBudgetSheet(
        projectId: widget.projectId,
        materials: _materials,
        api: _api,
      ),
    );
    if (created == true) _load();
  }

  /// HU-13 — enviar a revisión (autor) o revisar (ingeniero).
  Future<void> _submit(Budget b) async {
    try {
      await _api.post('/budgets/${b.id}/submit/', {});
      _load();
    } on ApiError catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  Future<void> _review(Budget b, String decision) async {
    final ctrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: kSurface,
        title: Text(
          {
            'approved': 'Aprobar',
            'observed': 'Observar',
            'rejected': 'Rechazar',
          }[decision]!,
        ),
        content: TextField(
          controller: ctrl,
          maxLines: 3,
          decoration: const InputDecoration(labelText: 'Comentarios'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    if (decision != 'approved' && ctrl.text.trim().isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Agrega un comentario para observar/rechazar.'),
          ),
        );
      }
      return;
    }
    try {
      await _api.post('/budgets/${b.id}/review/', {
        'decision': decision,
        'comments': ctrl.text.trim(),
      });
      _load();
    } on ApiError catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  /// Botones de acción de un presupuesto según rol y estado (HU-13).
  List<Widget> _actions(Budget b) {
    final isEngineer =
        context.read<AuthService>().user?.hasRole(['ingeniero']) ?? false;
    final children = <Widget>[];
    if (b.status == 'draft' || b.status == 'observed') {
      children.add(
        OutlinedButton(
          onPressed: () => _submit(b),
          child: const Text('Enviar a revisión'),
        ),
      );
    }
    if (isEngineer && b.status == 'submitted') {
      children.addAll([
        FilledButton(
          onPressed: () => _review(b, 'approved'),
          child: const Text('Aprobar'),
        ),
        OutlinedButton(
          onPressed: () => _review(b, 'observed'),
          child: const Text('Observar'),
        ),
        OutlinedButton(
          onPressed: () => _review(b, 'rejected'),
          style: OutlinedButton.styleFrom(foregroundColor: kDanger),
          child: const Text('Rechazar'),
        ),
      ]);
    }
    if (children.isEmpty) return const [];
    return [
      const SizedBox(height: 10),
      Wrap(spacing: 8, runSpacing: 8, children: children),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Presupuesto')),
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
                  Card(
                    child: ListTile(
                      leading: const Icon(
                        Icons.calculate_outlined,
                        color: kPrimary2,
                      ),
                      title: const Text('Estimar desde el modelo 3D'),
                      subtitle: Text(
                        _modelId == null
                            ? 'Genera primero el modelo 3D del proyecto'
                            : 'Calcula materiales y cantidades automáticamente (Bs)',
                      ),
                      trailing: FilledButton(
                        onPressed: _modelId == null ? null : _estimate,
                        child: const Text('Estimar'),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (_budgets.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        'Sin presupuestos. Crea el primero.',
                        style: TextStyle(color: kMuted),
                      ),
                    ),
                  ..._budgets.map(
                    (b) => Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'Total: ${b.total} ${b.currency}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                                StatusChip(b.status),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Materiales: Bs ${b.materialsCost} · Mano de obra: Bs ${b.laborCost} (${b.laborPeople} pers.)',
                              style: const TextStyle(color: kMuted),
                            ),
                            ..._actions(b),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _NewBudgetSheet extends StatefulWidget {
  final int projectId;
  final List<MaterialItem> materials;
  final Api api;
  const _NewBudgetSheet({
    required this.projectId,
    required this.materials,
    required this.api,
  });
  @override
  State<_NewBudgetSheet> createState() => _NewBudgetSheetState();
}

class _Row {
  int? material;
  final qty = TextEditingController(text: '1');
}

class _NewBudgetSheetState extends State<_NewBudgetSheet> {
  final List<_Row> _rows = [_Row()];
  final _people = TextEditingController(text: '0');
  final _laborCost = TextEditingController(text: '0');
  bool _saving = false;
  String? _error;

  Future<void> _save() async {
    final items = _rows
        .where(
          (r) => r.material != null && (double.tryParse(r.qty.text) ?? 0) > 0,
        )
        .map((r) => {'material': r.material, 'quantity': r.qty.text})
        .toList();
    if (items.isEmpty) {
      setState(() => _error = 'Añade al menos un material.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.api.post('/budgets/', {
        'project': widget.projectId,
        'labor_people': int.tryParse(_people.text) ?? 0,
        'labor_cost': _laborCost.text,
        'items': items,
      });
      if (mounted) Navigator.pop(context, true);
    } on ApiError catch (e) {
      setState(() {
        _error = e.message;
        _saving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Nuevo presupuesto',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            ..._rows.asMap().entries.map((e) {
              final r = e.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: DropdownButtonFormField<int>(
                        initialValue: r.material,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Material',
                        ),
                        dropdownColor: kSurface2,
                        items: widget.materials
                            .map(
                              (m) => DropdownMenuItem(
                                value: m.id,
                                child: Text(
                                  '${m.name} (Bs ${m.unitPrice}/${m.unit})',
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (v) => setState(() => r.material = v),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 1,
                      child: TextField(
                        controller: r.qty,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Cant.'),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: _rows.length > 1
                          ? () => setState(() => _rows.removeAt(e.key))
                          : null,
                    ),
                  ],
                ),
              );
            }),
            TextButton.icon(
              onPressed: () => setState(() => _rows.add(_Row())),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Añadir material'),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _people,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Mano de obra (personas)',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _laborCost,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Costo mano de obra',
                    ),
                  ),
                ),
              ],
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(_error!, style: const TextStyle(color: kDanger)),
              ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _saving ? null : _save,
                child: Text(_saving ? 'Calculando…' : 'Crear presupuesto'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
