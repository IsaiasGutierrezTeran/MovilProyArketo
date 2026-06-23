import 'package:flutter/material.dart';

const kBg = Color(0xFF0B0F17);
const kSurface = Color(0xFF121826);
const kSurface2 = Color(0xFF1A2233);
const kBorder = Color(0xFF25304A);
const kPrimary = Color(0xFF5B8CFF);
const kPrimary2 = Color(0xFF7AA2FF);
const kPrimaryD = Color(0xFF3F6FE0);
const kMuted = Color(0xFF93A0B8);
const kFaint = Color(0xFF66728C);
const kSuccess = Color(0xFF46C97A);
const kWarn = Color(0xFFE0A83A);
const kDanger = Color(0xFFF3636B);

const kBrandGradient = LinearGradient(
  begin: Alignment.topLeft, end: Alignment.bottomRight,
  colors: [kPrimary2, kPrimaryD],
);

/// Subtle page background with a top accent glow.
const kBgGradient = LinearGradient(
  begin: Alignment.topRight, end: Alignment.bottomLeft,
  colors: [Color(0xFF131C30), kBg],
  stops: [0.0, 0.5],
);

ThemeData buildTheme() {
  final base = ThemeData.dark(useMaterial3: true);
  return base.copyWith(
    scaffoldBackgroundColor: kBg,
    colorScheme: base.colorScheme.copyWith(
      primary: kPrimary, surface: kSurface, error: kDanger,
    ),
    textTheme: base.textTheme.apply(bodyColor: const Color(0xFFE8EDF6), displayColor: const Color(0xFFE8EDF6)),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(fontSize: 19, fontWeight: FontWeight.w700, color: Color(0xFFE8EDF6)),
    ),
    cardTheme: const CardThemeData(
      color: kSurface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: kBorder),
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
      margin: EdgeInsets.only(bottom: 12),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: kSurface,
      indicatorColor: kPrimary.withValues(alpha: 0.18),
      elevation: 0,
      height: 64,
      labelTextStyle: WidgetStateProperty.all(const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
      iconTheme: WidgetStateProperty.resolveWith((s) =>
          IconThemeData(color: s.contains(WidgetState.selected) ? kPrimary2 : kMuted)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: kSurface2,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(11), borderSide: const BorderSide(color: kBorder)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(11), borderSide: const BorderSide(color: kBorder)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(11), borderSide: const BorderSide(color: kPrimary, width: 1.5)),
      labelStyle: const TextStyle(color: kMuted),
    ),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: kSurface2,
      behavior: SnackBarBehavior.floating,
      contentTextStyle: TextStyle(color: Color(0xFFE8EDF6)),
    ),
    dividerColor: kBorder,
  );
}

Color statusColor(String s) {
  switch (s) {
    case 'active': case 'approved': case 'completed': case 'registered': return kSuccess;
    case 'submitted': case 'observed': case 'processing': case 'pending': case 'medium': return kWarn;
    case 'failed': case 'canceled': case 'high': case 'critical': return kDanger;
    default: return kMuted;
  }
}

/// Brand logo tile (rounded gradient "A").
class BrandLogo extends StatelessWidget {
  final double size;
  const BrandLogo({super.key, this.size = 52});
  @override
  Widget build(BuildContext context) => Container(
        width: size, height: size,
        decoration: BoxDecoration(
          gradient: kBrandGradient,
          borderRadius: BorderRadius.circular(size * 0.27),
          boxShadow: [BoxShadow(color: kPrimaryD.withValues(alpha: 0.45), blurRadius: size * 0.4, offset: Offset(0, size * 0.12))],
        ),
        child: Center(child: Text('A', style: TextStyle(fontSize: size * 0.5, fontWeight: FontWeight.w800, color: Colors.white))),
      );
}

/// Primary CTA with the brand gradient.
class GradientButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  const GradientButton(this.label, {super.key, this.onPressed, this.icon});
  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return Opacity(
      opacity: enabled ? 1 : 0.55,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onPressed,
          child: Ink(
            decoration: BoxDecoration(
              gradient: kBrandGradient,
              borderRadius: BorderRadius.circular(12),
              boxShadow: enabled ? [BoxShadow(color: kPrimaryD.withValues(alpha: 0.35), blurRadius: 16, offset: const Offset(0, 6))] : null,
            ),
            child: Container(
              height: 50, alignment: Alignment.center,
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                if (icon != null) ...[Icon(icon, size: 18, color: Colors.white), const SizedBox(width: 8)],
                Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

/// Traduce códigos de estado/severidad del backend a español para mostrarlos.
String estadoEs(String s) {
  const map = {
    'draft': 'Borrador', 'active': 'Activo', 'archived': 'Archivado',
    'submitted': 'Enviado', 'approved': 'Aprobado', 'observed': 'Observado', 'rejected': 'Rechazado',
    'canceled': 'Cancelada', 'cancelled': 'Cancelada', 'incomplete': 'Pendiente de pago', 'past_due': 'Vencida',
    'pending': 'Pendiente', 'accepted': 'Aceptada',
    'completed': 'Completado', 'processing': 'Procesando', 'error': 'Error', 'failed': 'Falló',
    'uploaded': 'Subido', 'processed': 'Procesado', 'valid': 'Válido', 'invalid': 'Inválido',
    'generado': 'Generado', 'generated': 'Generado',
    'high': 'Alta', 'medium': 'Media', 'low': 'Baja', 'critical': 'Crítica',
  };
  return map[s.toLowerCase()] ?? s;
}

class StatusChip extends StatelessWidget {
  final String label;
  const StatusChip(this.label, {super.key});
  @override
  Widget build(BuildContext context) {
    final c = statusColor(label);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: c.withValues(alpha: 0.4)),
      ),
      child: Text(estadoEs(label), style: TextStyle(color: c, fontSize: 11, fontWeight: FontWeight.w700)),
    );
  }
}

/// Page background gradient wrapper.
class GradientBackground extends StatelessWidget {
  final Widget child;
  const GradientBackground({super.key, required this.child});
  @override
  Widget build(BuildContext context) =>
      DecoratedBox(decoration: const BoxDecoration(gradient: kBgGradient), child: child);
}
