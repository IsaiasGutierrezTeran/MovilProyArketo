import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/api.dart';
import '../../core/auth.dart';
import '../../core/models.dart';
import '../../core/theme.dart';

/// HU-17 — Planes y pagos (Stripe). Lista planes, muestra la suscripción actual,
/// suscribe (abre el checkout de Stripe si el backend devuelve checkout_url) y cancela.
class BillingScreen extends StatefulWidget {
  const BillingScreen({super.key});
  @override
  State<BillingScreen> createState() => _BillingScreenState();
}

class _BillingScreenState extends State<BillingScreen> {
  List<SubscriptionPlan> _plans = [];
  Subscription? _subscription;
  bool _loading = true;
  String? _busyCode;

  Api get _api => context.read<Api>();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final p = await _api.page('/billing/plans/', query: {'page_size': 100});
    _plans = p.items.map((e) => SubscriptionPlan.fromJson(e)).toList();
    try {
      _subscription = Subscription.fromJson(
        await _api.get('/billing/subscription'),
      );
    } catch (_) {
      /* sin suscripción aún */
    }
    if (mounted) setState(() => _loading = false);
  }

  /// Plan de pago -> pantalla de checkout. Plan gratis -> activación directa.
  Future<void> _choose(SubscriptionPlan plan) async {
    final price = double.tryParse(plan.price) ?? 0;
    if (price <= 0) {
      await _subscribe(plan);
      return;
    }
    final ok = await context.push<bool>('/billing/checkout', extra: plan);
    if (ok == true && mounted) {
      await _load();
      if (mounted) await context.read<AuthService>().refreshUser();
      _snack('Pago aprobado. Plan activado.');
    }
  }

  Future<void> _subscribe(SubscriptionPlan plan) async {
    setState(() => _busyCode = plan.code);
    try {
      final d = await _api.post('/billing/subscribe', {'plan': plan.code});
      final checkoutUrl = d is Map ? d['checkout_url'] as String? : null;
      if (checkoutUrl != null && checkoutUrl.isNotEmpty) {
        // Stripe real: abrir el checkout en el navegador.
        await launchUrl(
          Uri.parse(checkoutUrl),
          mode: LaunchMode.externalApplication,
        );
      }
      await _load();
      if (mounted)
        await context
            .read<AuthService>()
            .refreshUser(); // refleja el nuevo plan
      _snack(
        checkoutUrl != null
            ? 'Completa el pago en el navegador.'
            : 'Suscripción activada.',
      );
    } on ApiError catch (e) {
      _snack(e.message);
    } finally {
      if (mounted) setState(() => _busyCode = null);
    }
  }

  Future<void> _cancel() async {
    try {
      await _api.post('/billing/cancel', {});
      await _load();
      if (mounted) await context.read<AuthService>().refreshUser();
      _snack('Suscripción cancelada.');
    } on ApiError catch (e) {
      _snack(e.message);
    }
  }

  void _snack(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  @override
  Widget build(BuildContext context) {
    final activeCode = _subscription?.planCode;
    return Scaffold(
      appBar: AppBar(title: const Text('Planes y pagos')),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: kPrimary))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (_subscription != null)
                  Card(
                    child: ListTile(
                      leading: const Icon(
                        Icons.workspace_premium_outlined,
                        color: kPrimary2,
                      ),
                      title: Text('Plan actual: ${activeCode ?? '—'}'),
                      subtitle: Text('Estado: ${_subscription!.status}'),
                      trailing: _subscription!.status == 'active'
                          ? TextButton(
                              onPressed: _cancel,
                              child: const Text(
                                'Cancelar',
                                style: TextStyle(color: kDanger),
                              ),
                            )
                          : null,
                    ),
                  ),
                const SizedBox(height: 8),
                const Text(
                  'Planes disponibles',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                ..._plans.map((p) {
                  final isCurrent = p.code == activeCode;
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  p.name,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              Text(
                                'Bs ${p.price}/${p.interval == 'year' ? 'año' : 'mes'}',
                                style: const TextStyle(
                                  color: kPrimary2,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                          if (p.features.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            ...p.features.map(
                              (f) => Padding(
                                padding: const EdgeInsets.only(bottom: 2),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.check,
                                      size: 15,
                                      color: kSuccess,
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        '$f',
                                        style: const TextStyle(
                                          color: kMuted,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton(
                              onPressed: (isCurrent || _busyCode != null)
                                  ? null
                                  : () => _choose(p),
                              child: Text(
                                isCurrent
                                    ? 'Plan actual'
                                    : (_busyCode == p.code
                                          ? 'Procesando…'
                                          : 'Elegir plan'),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
                if (_plans.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'No hay planes disponibles.',
                      style: TextStyle(color: kMuted),
                    ),
                  ),
              ],
            ),
    );
  }
}
