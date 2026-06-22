import 'package:flutter/material.dart';

/// Pastille rouge affichant un nombre de messages non lus (max « 9+ »).
class BadgeNonLus extends StatelessWidget {
  final int nombre;
  const BadgeNonLus({super.key, required this.nombre});

  @override
  Widget build(BuildContext context) {
    if (nombre <= 0) return const SizedBox.shrink();
    final texte = nombre > 9 ? '9+' : '$nombre';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
      decoration: BoxDecoration(
        color: const Color(0xFFE53935),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: Colors.white, width: 1.5),
      ),
      child: Center(
        child: Text(
          texte,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            height: 1.1,
          ),
        ),
      ),
    );
  }
}
