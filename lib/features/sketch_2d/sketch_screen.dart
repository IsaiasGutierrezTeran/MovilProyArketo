import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api.dart';
import '../../core/models.dart';
import '../../core/theme.dart';

/// HU-18 — Generar boceto 2D mediante prompt.
/// El usuario escribe un prompt y la IA devuelve un boceto/plano 2D (imagen).
/// Consume POST /api/sketch2d/generate y muestra `imagen_url`.
class SketchScreen extends StatefulWidget {
  const SketchScreen({super.key});
  @override
  State<SketchScreen> createState() => _SketchScreenState();
}

class _SketchScreenState extends State<SketchScreen> {
  final _prompt = TextEditingController(
    text: 'Plano de casa de 8 x 6 metros, 2 dormitorios',
  );
  List<Project> _projects = [];
  int? _project;
  bool _busy = false;
  String? _error;
  Boceto2D? _result;
  List<Boceto2D> _history = [];

  Api get _api => context.read<Api>();

  @override
  void initState() {
    super.initState();
    _loadProjects();
    _loadHistory();
  }

  Future<void> _loadProjects() async {
    try {
      final r = await _api.page('/projects/', query: {'page_size': 100});
      if (mounted)
        setState(
          () => _projects = r.items.map((e) => Project.fromJson(e)).toList(),
        );
    } catch (_) {
      /* lista opcional */
    }
  }

  Future<void> _loadHistory() async {
    try {
      final r = await _api.page('/sketch2d/', query: {'page_size': 20});
      if (mounted)
        setState(
          () => _history = r.items.map((e) => Boceto2D.fromJson(e)).toList(),
        );
    } catch (_) {
      /* historial opcional */
    }
  }

  Future<void> _generate() async {
    if (_prompt.text.trim().isEmpty) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final d = await _api.post('/sketch2d/generate', {
        'prompt': _prompt.text.trim(),
        'provider': 'mock',
        if (_project != null) 'project': _project,
      });
      final boceto = Boceto2D.fromJson(d);
      setState(() {
        _result = boceto;
        _history = [boceto, ..._history];
      });
    } on ApiError catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Boceto 2D',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
        ),
        const Text(
          'Describe el plano y la IA genera un boceto 2D.',
          style: TextStyle(color: kMuted),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _prompt,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Prompt (incluye medidas y ambientes)',
          ),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<int?>(
          initialValue: _project,
          decoration: const InputDecoration(
            labelText: 'Guardar en proyecto (opcional)',
          ),
          dropdownColor: kSurface2,
          items: [
            const DropdownMenuItem(
              value: null,
              child: Text('— sin proyecto —'),
            ),
            ..._projects.map(
              (p) => DropdownMenuItem(
                value: p.id,
                child: Text(p.name, overflow: TextOverflow.ellipsis),
              ),
            ),
          ],
          onChanged: (v) => setState(() => _project = v),
        ),
        const SizedBox(height: 14),
        GradientButton(
          _busy ? 'Generando…' : 'Generar boceto',
          icon: Icons.draw_outlined,
          onPressed: _busy ? null : _generate,
        ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(_error!, style: const TextStyle(color: kDanger)),
          ),

        if (_result != null) ...[
          const SizedBox(height: 16),
          _BocetoCard(_result!),
        ],

        if (_history.isNotEmpty) ...[
          const SizedBox(height: 20),
          const Text(
            'Anteriores',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          ..._history.map((b) => _BocetoCard(b, compact: true)),
        ],
      ],
    );
  }
}

class _BocetoCard extends StatelessWidget {
  final Boceto2D boceto;
  final bool compact;
  const _BocetoCard(this.boceto, {this.compact = false});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    boceto.prompt,
                    maxLines: compact ? 1 : 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                StatusChip(boceto.estado),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: AspectRatio(
                aspectRatio: 4 / 3,
                child: boceto.imagenUrl.isEmpty
                    ? const ColoredBox(
                        color: kSurface2,
                        child: Center(
                          child: Text(
                            'Sin imagen',
                            style: TextStyle(color: kMuted),
                          ),
                        ),
                      )
                    : Image.network(
                        boceto.imagenUrl,
                        fit: BoxFit.contain,
                        loadingBuilder: (ctx, child, progress) =>
                            progress == null
                            ? child
                            : const Center(
                                child: CircularProgressIndicator(
                                  color: kPrimary,
                                ),
                              ),
                        errorBuilder: (ctx, _, __) => const ColoredBox(
                          color: kSurface2,
                          child: Center(
                            child: Text(
                              'No se pudo cargar la imagen',
                              style: TextStyle(color: kMuted),
                            ),
                          ),
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Proveedor: ${boceto.proveedorIa}',
              style: const TextStyle(color: kFaint, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
