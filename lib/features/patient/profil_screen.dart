// lib/features/patient/profil_screen.dart
// ConfidantSanté — Profil Patient connecté à SQLite via PatientProvider
// Auteur : Christian Ngoy Tshikwata — UDBL Lubumbashi

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/l10n/app_translations.dart';
import '../../core/providers/patient_provider.dart';
import '../../core/providers/messages_provider.dart';
import '../../core/services/session_service.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/database_service.dart';
import 'profile/parametres_screen.dart';

class ProfilScreen extends StatefulWidget {
  const ProfilScreen({super.key});

  @override
  State<ProfilScreen> createState() => _ProfilScreenState();
}

class _ProfilScreenState extends State<ProfilScreen> {

  // ── MÉTHODES ──────────────────────────────────────────────────────────────

  void _ouvrirParametres() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ParametresScreen()),
    );
  }

  void _deconnecter() {
    final t = AppTranslations.t;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(t('deconnecter'),
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
        content: const Text(
          'Vous devrez vous reconnecter avec votre numéro de téléphone.',
          style: TextStyle(fontSize: 14, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(t('annuler'),
                style: const TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              await AuthService().deconnecter();
              await SessionService().deconnecter();
              await context.read<MessagesProvider>().arreter();
              if (!context.mounted) return;
              context.read<PatientProvider>().reinitialiser();
              if (!mounted) return;
              Navigator.of(context).pushNamedAndRemoveUntil(
                '/role', (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(t('deconnecter')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {

    // ── Données depuis PatientProvider (SQLite) ──────────────────────────
    final patient = context.watch<PatientProvider>();
    final t = AppTranslations.t;

    final initiales = patient.nom.isNotEmpty
        ? patient.nom.trim().split(' ')
        .map((e) => e.isNotEmpty ? e[0] : '')
        .take(2).join().toUpperCase()
        : 'CS';

    final observance = patient.observance / 100;
    final joursActifs = patient.joursActifs;
    final totalPrises = patient.historique.length;
    final priseManquees = totalPrises - joursActifs;

    // Construit l'historique depuis les prises SQLite
    final historiqueMap = patient.historique;
    // Agrège par jour (une seule case par date, même avec plusieurs protocoles).
    final joursHisto = DatabaseService.grouperParJour(historiqueMap);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      body: CustomScrollView(
        slivers: [

          // ── En-tête ─────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF0D47A1),
                    Color(0xFF1565C0),
                    Color(0xFF1976D2),
                  ],
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(28),
                  bottomRight: Radius.circular(28),
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
                  child: Column(
                    children: [

                      // Titre + paramètres
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            t('profil'),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          GestureDetector(
                            onTap: _ouvrirParametres,
                            child: Container(
                              width: 38, height: 38,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.settings_outlined,
                                color: Colors.white, size: 20,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // Avatar + nom + numéro
                      Row(
                        children: [
                          Container(
                            width: 70, height: 70,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withValues(alpha: 0.2),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.4),
                                width: 2,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                initiales,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  patient.nom.isNotEmpty
                                      ? patient.nom
                                      : 'Patient',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  patient.numero.isNotEmpty
                                      ? '+243 ${patient.numero}'
                                      : '--',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.7),
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: Colors.white.withValues(alpha: 0.3),
                                    ),
                                  ),
                                  child: Text(
                                    '${t('observance')} ${patient.observance.toInt()}%',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── Contenu ──────────────────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([

                // Stats
                Row(
                  children: [
                    _CarteStatProfil(
                      valeur: '$joursActifs',
                      label: t('jours_actifs'),
                      icone: Icons.check_circle_outline,
                      couleur: AppColors.success,
                      fond: const Color(0xFFE8F5E9),
                    ),
                    const SizedBox(width: 12),
                    _CarteStatProfil(
                      valeur: '${priseManquees < 0 ? 0 : priseManquees}',
                      label: t('prises_manquees'),
                      icone: Icons.cancel_outlined,
                      couleur: AppColors.danger,
                      fond: const Color(0xFFFFEBEE),
                    ),
                    const SizedBox(width: 12),
                    _CarteStatProfil(
                      valeur: '${joursHisto.length}',
                      label: t('jours_total'),
                      icone: Icons.calendar_month_outlined,
                      couleur: AppColors.primary,
                      fond: AppColors.primaryPale,
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Mon traitement
                _TitreSec(t('mon_traitement')),
                const SizedBox(height: 12),

                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE0E7EF)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      _LigneInfo(
                        icone: Icons.medication_outlined,
                        label: 'Protocole',
                        valeur: patient.traitements.isNotEmpty
                            ? (patient.traitements.first['nom_medicament']
                        as String? ??
                            '—')
                            : '—',
                        dernier: false,
                      ),
                      _LigneInfo(
                        icone: Icons.person_outline,
                        label: 'Soignant',
                        valeur: 'Dr. Ndetereyuwe',
                        dernier: false,
                      ),
                      _LigneInfo(
                        icone: Icons.local_hospital_outlined,
                        label: 'Hôpital',
                        valeur: 'C.H. Congo-Chine',
                        dernier: true,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Historique 30 jours
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _TitreSec(t('historique')),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primaryPale,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${patient.observance.toInt()}% ${t('observance')}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE0E7EF)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: historiqueMap.isEmpty
                      ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        'Aucune prise enregistrée',
                        style: const TextStyle(
                            color: AppColors.textSecondary),
                      ),
                    ),
                  )
                      : Column(
                    children: [
                      // Jours de la semaine
                      Row(
                        children: ['L', 'M', 'M', 'J', 'V', 'S', 'D']
                            .map((j) => Expanded(
                          child: Center(
                            child: Text(
                              j,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ))
                            .toList(),
                      ),
                      const SizedBox(height: 8),
                      // Grille depuis les vraies prises SQLite
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 7,
                          crossAxisSpacing: 4,
                          mainAxisSpacing: 4,
                        ),
                        itemCount: joursHisto.length,
                        itemBuilder: (context, i) {
                          final j = joursHisto[i];
                          final date = j['date'] as DateTime;
                          final taux = j['taux'] as double;
                          // Couleur graduée : vert (tout pris), ambre (partiel),
                          // rouge (rien).
                          final couleur = taux >= 1.0
                              ? AppColors.success
                              : (taux <= 0.0
                                  ? AppColors.danger
                                  : AppColors.warning);
                          return Tooltip(
                            message:
                                '${date.day}/${date.month} — ${(taux * 100).round()}% (${j['pris']}/${j['total']})',
                            child: Container(
                              decoration: BoxDecoration(
                                color: couleur,
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: Center(
                                child: Text(
                                  '${date.day}',
                                  style: const TextStyle(
                                    fontSize: 9,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      // Légende
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _LegendeCal(AppColors.success, 'Pris'),
                          const SizedBox(width: 16),
                          _LegendeCal(AppColors.warning, 'Partiel'),
                          const SizedBox(width: 16),
                          _LegendeCal(AppColors.danger, 'Manqué'),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Bouton déconnexion
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: OutlinedButton.icon(
                    onPressed: _deconnecter,
                    icon: const Icon(Icons.logout,
                        size: 18, color: AppColors.danger),
                    label: Text(
                      t('deconnecter'),
                      style: const TextStyle(
                        color: AppColors.danger,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(
                          color: AppColors.danger, width: 1.5),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),

                const SizedBox(height: 100),

              ]),
            ),
          ),

        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Widgets utilitaires
// ─────────────────────────────────────────────────────────────────────────────

class _TitreSec extends StatelessWidget {
  final String texte;
  const _TitreSec(this.texte);

  @override
  Widget build(BuildContext context) => Text(
    texte,
    style: const TextStyle(
      fontSize: 15,
      fontWeight: FontWeight.w700,
      color: AppColors.textPrimary,
      letterSpacing: 0.2,
    ),
  );
}

class _LigneInfo extends StatelessWidget {
  final IconData icone;
  final String label, valeur;
  final bool dernier;

  const _LigneInfo({
    required this.icone,
    required this.label,
    required this.valeur,
    required this.dernier,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    decoration: BoxDecoration(
      border: dernier
          ? null
          : const Border(
          bottom:
          BorderSide(color: Color(0xFFF0F4F8), width: 1)),
    ),
    child: Row(
      children: [
        Icon(icone, size: 18, color: AppColors.primary),
        const SizedBox(width: 12),
        Text(label,
            style: const TextStyle(
                fontSize: 13, color: AppColors.textSecondary)),
        const Spacer(),
        Text(valeur,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            )),
      ],
    ),
  );
}

class _CarteStatProfil extends StatelessWidget {
  final String valeur, label;
  final IconData icone;
  final Color couleur, fond;

  const _CarteStatProfil({
    required this.valeur,
    required this.label,
    required this.icone,
    required this.couleur,
    required this.fond,
  });

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE0E7EF)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: fond,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icone, size: 18, color: couleur),
          ),
          const SizedBox(height: 8),
          Text(valeur,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: couleur,
              )),
          const SizedBox(height: 3),
          Text(label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 10,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              )),
        ],
      ),
    ),
  );
}

class _LegendeCal extends StatelessWidget {
  final Color couleur;
  final String label;
  final Color? textColor;

  const _LegendeCal(this.couleur, this.label, {this.textColor});

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        width: 12, height: 12,
        decoration: BoxDecoration(
          color: couleur,
          borderRadius: BorderRadius.circular(3),
        ),
      ),
      const SizedBox(width: 6),
      Text(label,
          style: TextStyle(
            fontSize: 12,
            color: textColor ?? AppColors.textSecondary,
          )),
    ],
  );
}