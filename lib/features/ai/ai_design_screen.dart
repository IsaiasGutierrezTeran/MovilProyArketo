import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import 'package:provider/provider.dart';

import '../../core/api.dart';
import '../../core/models.dart';
import '../../core/theme.dart';

class AiDesignScreen extends StatefulWidget {
  const AiDesignScreen({super.key});
  @override
  State<AiDesignScreen> createState() => _AiDesignScreenState();
}

class _AiDesignScreenState extends State<AiDesignScreen> {
  final _prompt = TextEditingController(text: 'Casa de 6 x 4 metros con una puerta');
  List<Project> _projects = [];
  int? _project;
  bool _busy = false;
  DesignRequest? _result;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadProjects();
  }

  Future<void> _loadProjects() async {
    final r = await context.read<Api>().page('/projects/', query: {'page_size': 100});
    setState(() => _projects = r.items.map((e) => Project.fromJson(e)).toList());
  }

  Future<void> _generate() async {
    setState(() { _busy = true; _error = null; });
    try {
      final d = await context.read<Api>().post('/ai-design/text', {'prompt': _prompt.text, 'project': _project, 'provider': 'mock'});
      setState(() => _result = DesignRequest.fromJson(d));
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
        const Text('Diseñar con IA', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
        const Text('Genera un plano 3D desde una descripción.', style: TextStyle(color: kMuted)),
        const SizedBox(height: 14),
        TextField(controller: _prompt, maxLines: 3,
            decoration: const InputDecoration(labelText: 'Describe el plano (incluye medidas)')),
        const SizedBox(height: 12),
        DropdownButtonFormField<int?>(
          initialValue: _project,
          decoration: const InputDecoration(labelText: 'Proyecto destino (opcional)'),
          dropdownColor: kSurface2,
          items: [
            const DropdownMenuItem(value: null, child: Text('— vista previa —')),
            ..._projects.map((p) => DropdownMenuItem(value: p.id, child: Text(p.name, overflow: TextOverflow.ellipsis))),
          ],
          onChanged: (v) => setState(() => _project = v),
        ),
        const SizedBox(height: 14),
        GradientButton(_busy ? 'Generando…' : 'Generar', icon: Icons.auto_awesome, onPressed: _busy ? null : _generate),
        if (_error != null) Padding(padding: const EdgeInsets.only(top: 12), child: Text(_error!, style: const TextStyle(color: kDanger))),
        if (_result != null) ...[
          const SizedBox(height: 16),
          if (_result!.transcript.isNotEmpty) Text('“${_result!.transcript}”', style: const TextStyle(color: kMuted)),
          if (_result!.model?.glbUrl != null)
            Card(child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(children: [
                SizedBox(height: 280, child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: ModelViewer(
                    src: _result!.model!.glbUrl!,
                    alt: 'Modelo generado',
                    autoRotate: true, cameraControls: true,
                    backgroundColor: const Color(0xFF0B0E13),
                  ),
                )),
                const SizedBox(height: 8),
                Text('${_result!.model!.elementCount} elementos', style: const TextStyle(color: kMuted)),
              ]),
            ))
          else
            const Card(child: Padding(padding: EdgeInsets.all(16),
                child: Text('Vista previa generada. Elige un proyecto para guardar el modelo.', style: TextStyle(color: kMuted)))),
        ],
      ],
    );
  }
}
