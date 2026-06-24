import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/api.dart';
import '../../core/auth.dart';
import '../../core/models.dart';
import '../../core/theme.dart';

/// Pantalla de pago (checkout) para activar un plan. Pago de demostración.
class CheckoutScreen extends StatefulWidget {
  final SubscriptionPlan plan;
  const CheckoutScreen({super.key, required this.plan});
  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _card = TextEditingController(text: '4242 4242 4242 4242');
  final _exp = TextEditingController(text: '12/30');
  final _cvc = TextEditingController(text: '123');
  final _name = TextEditingController();
  bool _busy = false;
  String? _error;

  Future<void> _pay() async {
    if (_card.text.replaceAll(' ', '').length < 13) {
      setState(
        () => _error = 'Revisa el número de tarjeta (usa 4242 4242 4242 4242).',
      );
      return;
    }
    final api = context.read<Api>();
    final auth = context.read<AuthService>();
    setState(() {
      _busy = true;
      _error = null;
    });
    await Future.delayed(
      const Duration(milliseconds: 1600),
    ); // simula el procesamiento
    try {
      await api.post('/billing/subscribe', {'plan': widget.plan.code});
      await auth.refreshUser();
      if (mounted) context.pop(true);
    } on ApiError catch (e) {
      if (mounted)
        setState(() {
          _error = e.message;
          _busy = false;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.plan;
    return Scaffold(
      appBar: AppBar(title: const Text('Pago')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              title: Text(
                'Plan ${p.name}',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              trailing: Text(
                'Bs ${p.price}/mes',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: kPrimary2,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: const LinearGradient(
                colors: [Color(0xFF3F6FE0), Color(0xFF6D4BFF)],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Tarjeta',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
                const SizedBox(height: 12),
                Text(
                  _card.text.isEmpty ? '•••• •••• •••• ••••' : _card.text,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _name.text.isEmpty ? 'NOMBRE APELLIDO' : _name.text,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      _exp.text.isEmpty ? 'MM/AA' : _exp.text,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _card,
            keyboardType: TextInputType.number,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(labelText: 'Número de tarjeta'),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _exp,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    labelText: 'Vencimiento (MM/AA)',
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _cvc,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'CVC'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _name,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              labelText: 'Nombre en la tarjeta',
            ),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(_error!, style: const TextStyle(color: kDanger)),
            ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _busy ? null : _pay,
              child: Text(_busy ? 'Procesando pago…' : 'Pagar Bs ${p.price}'),
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(top: 10),
            child: Text(
              'Pago de demostración — no se cobra dinero real. Tarjeta de prueba: 4242 4242 4242 4242.',
              style: TextStyle(color: kMuted, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
