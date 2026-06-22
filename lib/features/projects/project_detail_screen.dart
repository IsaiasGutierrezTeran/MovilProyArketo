import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/api.dart';
import '../../core/auth.dart';
import '../../core/models.dart';
import '../../core/theme.dart';

class ProjectDetailScreen extends StatefulWidget {
  final int id;
  const ProjectDetailScreen({super.key, required this.id});
  @override
  State<ProjectDetailScreen> createState() => _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends State<ProjectDetailScreen> {
  Project? _project;
  List<Plan> _plans = [];
  Model3D? _current;
  List<Budget> _budgets = [];
  RiskAnalysis? _risk;
  bool _loading = true;
  int? _running;
  bool _analyzing = false;
  bool _uploading = false;
  bool _importing = false;
  String _detector = 'mock'; // mock | maskrcnn (real Mask R-CNN via floorplan-api)

  Api get _api => context.read<Api>();

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() => _loading = true);
    _project = Project.fromJson(await _api.get('/projects/${widget.id}/'));
    await _reloadPlansModels();
    final b = await _api.page('/budgets/', query: {'project': widget.id});
    _budgets = b.items.map((e) => Budget.fromJson(e)).toList();
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _reloadPlansModels() async {
    final p = await _api.page('/plans/', query: {'project': widget.id});
    final m = await _api.page('/models3d/', query: {'project': widget.id});
    _plans = p.items.map((e) => Plan.fromJson(e)).toList();
    final models = m.items.map((e) => Model3D.fromJson(e)).toList();
    Model3D? cur;
    for (final x in models) {
      if (x.isCurrent) { cur = x; break; }
    }
    _current = cur ?? (models.isNotEmpty ? models.first : null);
    if (mounted) setState(() {});
  }

  // HU-4 — subir/capturar plano (galería o cámara).
  Future<void> _uploadPlan(ImageSource source) async {
    try {
      final picked = await ImagePicker().pickImage(source: source, imageQuality: 90);
      if (picked == null) return;
      setState(() => _uploading = true);
      final form = FormData.fromMap({
        'project': widget.id,
        'file': await MultipartFile.fromFile(picked.path, filename: picked.name),
      });
      await _api.postForm('/plans/', form);
      await _reloadPlansModels();
      _snack('Plano subido.');
    } on ApiError catch (e) {
      _snack(e.message);
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  void _pickUploadSource() {
    showModalBottomSheet(
      context: context, backgroundColor: kSurface,
      builder: (ctx) => SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [
        ListTile(leading: const Icon(Icons.photo_camera_outlined), title: const Text('Cámara'),
            onTap: () { Navigator.pop(ctx); _uploadPlan(ImageSource.camera); }),
        ListTile(leading: const Icon(Icons.photo_library_outlined), title: const Text('Galería'),
            onTap: () { Navigator.pop(ctx); _uploadPlan(ImageSource.gallery); }),
      ])),
    );
  }

  Future<void> _generate(Plan plan) async {
    setState(() => _running = plan.id);
    try {
      await _api.post('/detection/run', {'plan': plan.id, 'detector': _detector});
      await _reloadPlansModels();
    } on ApiError catch (e) {
      _snack(e.message);
    } finally {
      if (mounted) setState(() => _running = null);
    }
  }

  // HU-8 — importar modelo 3D externo (GLB/GLTF).
  Future<void> _importGlb() async {
    try {
      final res = await FilePicker.pickFiles(
        type: FileType.custom, allowedExtensions: ['glb', 'gltf'],
      );
      final path = res?.files.single.path;
      if (path == null) return;
      setState(() => _importing = true);
      final form = FormData.fromMap({
        'project': widget.id,
        'file': await MultipartFile.fromFile(path, filename: res!.files.single.name),
      });
      await _api.postForm('/models3d/import/', form);
      await _reloadPlansModels();
      _snack('Modelo importado.');
    } on ApiError catch (e) {
      _snack(e.message);
    } finally {
      if (mounted) setState(() => _importing = false);
    }
  }

  // HU-8 — exportar (abrir la URL del GLB).
  Future<void> _exportGlb() async {
    final url = _current?.glbUrl;
    if (url == null) return;
    final ok = await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    if (!ok) _snack('No se pudo abrir el modelo.');
  }

  Future<void> _analyze() async {
    if (_current == null) return;
    setState(() => _analyzing = true);
    try {
      _risk = RiskAnalysis.fromJson(await _api.post('/risk/analyze', {'model3d': _current!.id}));
    } on ApiError catch (e) {
      _snack(e.message);
    } finally {
      if (mounted) setState(() => _analyzing = false);
    }
  }

  void _snack(String m) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  @override
  Widget build(BuildContext context) {
    // Diseñar/modelar (subir plano, generar/importar 3D) es exclusivo del arquitecto.
    final canDesign = context.read<AuthService>().user?.hasRole(['arquitecto']) ?? false;
    return Scaffold(
      appBar: AppBar(title: Text(_project?.name ?? 'Proyecto'), actions: [
        IconButton(
          tooltip: 'Colaboración',
          icon: const Icon(Icons.group_outlined),
          onPressed: () => context.push('/projects/${widget.id}/collab'),
        ),
      ]),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: kPrimary))
          : RefreshIndicator(
            onRefresh: _loadAll,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Row(children: [
                  Expanded(child: Text(_project!.description.isEmpty ? 'Sin descripción' : _project!.description,
                      style: const TextStyle(color: kMuted))),
                  StatusChip(_project!.status),
                ]),
                const SizedBox(height: 16),

                Row(children: [
                  Expanded(child: _section('Modelo 3D')),
                  if (_current?.glbUrl != null)
                    IconButton(tooltip: 'Exportar .glb', icon: const Icon(Icons.download_outlined), onPressed: _exportGlb),
                  if (canDesign)
                    IconButton(
                      tooltip: 'Importar .glb',
                      icon: _importing
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.upload_file_outlined),
                      onPressed: _importing ? null : _importGlb,
                    ),
                ]),
                Card(child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: _current?.glbUrl != null
                      ? Column(children: [
                          SizedBox(
                            height: 280,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: ModelViewer(
                                src: _current!.glbUrl!,
                                alt: 'Modelo 3D',
                                autoRotate: true,
                                cameraControls: true,
                                disableZoom: false,
                                backgroundColor: const Color(0xFF0B0E13),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text('${_current!.elementCount} elementos', style: const TextStyle(color: kMuted)),
                        ])
                      : const Padding(padding: EdgeInsets.all(16),
                          child: Text('Sin modelo 3D. Genera uno desde un plano o importa un .glb.', style: TextStyle(color: kMuted))),
                )),
                const SizedBox(height: 16),

                Row(children: [
                  Expanded(child: _section('Planos')),
                  if (canDesign) ...[
                    const Text('Detector ', style: TextStyle(color: kMuted, fontSize: 12)),
                    DropdownButton<String>(
                      value: _detector,
                      dropdownColor: kSurface2,
                      underline: const SizedBox.shrink(),
                      items: const [
                        DropdownMenuItem(value: 'mock', child: Text('Mock')),
                        DropdownMenuItem(value: 'maskrcnn', child: Text('Mask R-CNN')),
                      ],
                      onChanged: (v) => setState(() => _detector = v ?? 'mock'),
                    ),
                  ],
                ]),
                if (canDesign) ...[
                  const SizedBox(height: 4),
                  SizedBox(width: double.infinity, child: OutlinedButton.icon(
                    onPressed: _uploading ? null : _pickUploadSource,
                    icon: _uploading
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.add_a_photo_outlined),
                    label: Text(_uploading ? 'Subiendo…' : 'Subir / capturar plano'),
                  )),
                ] else
                  const Padding(padding: EdgeInsets.only(top: 4, bottom: 4),
                      child: Text('Solo un arquitecto puede subir planos y generar el 3D.', style: TextStyle(color: kMuted, fontSize: 12))),
                const SizedBox(height: 8),
                ..._plans.map((pl) => Card(child: ListTile(
                      leading: const Icon(Icons.description_outlined),
                      title: Text(pl.format.toUpperCase()),
                      subtitle: Text(pl.status),
                      trailing: !canDesign
                          ? null
                          : (_running == pl.id
                              ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2))
                              : FilledButton(onPressed: () => _generate(pl), child: const Text('Generar 3D'))),
                    ))),
                if (_plans.isEmpty)
                  const Padding(padding: EdgeInsets.all(12), child: Text('Sin planos.', style: TextStyle(color: kMuted))),
                const SizedBox(height: 16),

                Row(children: [
                  Expanded(child: _section('Presupuesto')),
                  TextButton.icon(
                    onPressed: () => context.push('/projects/${widget.id}/budget'),
                    icon: const Icon(Icons.calculate_outlined, size: 18),
                    label: const Text('Ver / crear'),
                  ),
                ]),
                ..._budgets.take(3).map((b) => Card(child: ListTile(
                      title: Text('Total: ${b.total} ${b.currency}'),
                      subtitle: Text('Materiales ${b.materialsCost} · Mano de obra ${b.laborPeople} pers.'),
                      trailing: StatusChip(b.status),
                    ))),
                if (_budgets.isEmpty)
                  const Padding(padding: EdgeInsets.all(12), child: Text('Sin presupuestos.', style: TextStyle(color: kMuted))),
                const SizedBox(height: 16),

                _section('Riesgos'),
                Card(child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    GradientButton(_analyzing ? 'Analizando…' : 'Analizar riesgos (IA)',
                        icon: Icons.warning_amber_rounded,
                        onPressed: (_current == null || _analyzing) ? null : _analyze),
                    if (_risk != null) ...[
                      const SizedBox(height: 10),
                      Text(_risk!.summary, style: const TextStyle(color: kMuted)),
                      ..._risk!.findings.map((f) => Padding(
                            padding: const EdgeInsets.only(top: 10),
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Row(children: [
                                Expanded(child: Text(f.category, style: const TextStyle(fontWeight: FontWeight.w600))),
                                StatusChip(f.severity),
                              ]),
                              Text(f.description),
                              if (f.suggestion.isNotEmpty)
                                Text(f.suggestion, style: const TextStyle(color: kMuted)),
                            ]),
                          )),
                    ],
                  ]),
                )),
              ],
            ),
          ),
    );
  }

  Widget _section(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(t, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
      );
}
