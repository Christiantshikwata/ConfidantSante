import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/providers/patient_provider.dart';
import '../../core/services/database_service.dart';
import '../../core/services/session_service.dart';
import 'rappels_screen.dart';
import 'discretion_screen.dart';
import 'profil_screen.dart';

class DashboardPatientScreen extends StatefulWidget {
  const DashboardPatientScreen({super.key});

  @override
  State<DashboardPatientScreen> createState() =>
      _DashboardPatientScreenState();
}

class _DashboardPatientScreenState
    extends State<DashboardPatientScreen> {

  int _pageActive = 0;

  @override
  void initState() {
    super.initState();
    // Charge les données dès l'ouverture du dashboard
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PatientProvider>().chargerDonnees();
    });
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      const _PageAccueil(),
      const RappelsScreen(),
      const DiscretionScreen(),
      const ProfilScreen(),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      body: pages[_pageActive],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(
              color: const Color(0xFFE0E7EF),
              width: 0.5,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _pageActive,
          onTap: (i) => setState(() => _pageActive = i),
          backgroundColor: Colors.transparent,
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: const Color(0xFF94A3B8),
          selectedLabelStyle: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: const TextStyle(fontSize: 11),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Accueil',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.alarm_outlined),
              activeIcon: Icon(Icons.alarm),
              label: 'Rappels',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.shield_outlined),
              activeIcon: Icon(Icons.shield),
              label: 'Discrétion',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Profil',
            ),
          ],
        ),
      ),
    );
  }
}

// ── PAGE ACCUEIL CONNECTÉE À SQLITE ──────────────────────────────────────────

class _PageAccueil extends StatelessWidget {
  const _PageAccueil();

  static String _salutation() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Bonjour,';
    if (h < 17) return 'Bon après-midi,';
    return 'Bonsoir,';
  }

  @override
  Widget build(BuildContext context) {

    // Consumer écoute les changements du PatientProvider
    return Consumer<PatientProvider>(
      builder: (context, patient, _) {

        // Initiales du nom
        final initiales = patient.nom.isNotEmpty
            ? patient.nom.trim().split(' ')
            .map((e) => e.isNotEmpty ? e[0] : '')
            .take(2)
            .join()
            .toUpperCase()
            : 'CS';

        return CustomScrollView(
          slivers: [

            // En-tête dégradé
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
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [

                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _salutation(),
                                    style: TextStyle(
                                      color: Colors.white
                                          .withValues(alpha: 0.75),
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    // Affiche le vrai nom depuis SQLite
                                    patient.nom.isNotEmpty
                                        ? patient.nom
                                        : 'Patient',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Avatar avec vraies initiales
                            Container(
                              width: 42, height: 42,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.4),
                                  width: 1.5,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  initiales,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // Carte observance avec vraies données
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Observance du mois',
                                    style: TextStyle(
                                      color: Colors.white
                                          .withValues(alpha: 0.8),
                                      fontSize: 13,
                                    ),
                                  ),
                                  Text(
                                    // Vrai taux d'observance
                                    '${patient.observance.toInt()}%',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: patient.observance / 100,
                                  backgroundColor:
                                  Colors.white.withValues(alpha: 0.25),
                                  valueColor:
                                  const AlwaysStoppedAnimation(
                                      Colors.white),
                                  minHeight: 8,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '${patient.joursActifs} prises effectuées',
                                    style: TextStyle(
                                      color: Colors.white
                                          .withValues(alpha: 0.65),
                                      fontSize: 11,
                                    ),
                                  ),
                                  Text(
                                    '${patient.historique.length - patient.joursActifs} manquées',
                                    style: TextStyle(
                                      color: Colors.white
                                          .withValues(alpha: 0.65),
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Contenu
            SliverPadding(
              padding: const EdgeInsets.all(20),
              sliver: SliverList(
                delegate: SliverChildListDelegate([

                  // Stats
                  Row(
                    children: [
                      _CarteStatistique(
                        icone: Icons.alarm_outlined,
                        // Vrai nombre de rappels
                        valeur: '${patient.rappels.length}',
                        label: "Rappels configurés",
                        couleur: AppColors.primary,
                        fondCouleur: AppColors.primaryPale,
                      ),
                      const SizedBox(width: 12),
                      _CarteStatistique(
                        icone: Icons.calendar_today_outlined,
                        valeur: '${patient.joursActifs}',
                        label: 'Jours actifs',
                        couleur: AppColors.success,
                        fondCouleur: const Color(0xFFE8F5E9),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Section rappels du jour
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Médicaments du jour',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        'Voir tout',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // Liste des rappels depuis SQLite
                  if (patient.rappels.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: const Color(0xFFE0E7EF),
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.medication_outlined,
                            size: 40,
                            color: AppColors.primary.withValues(alpha: 0.3),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Aucun rappel configuré',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Ajoutez vos médicaments dans l\'onglet Rappels',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    ...patient.rappels.map((rappel) =>
                        _CarteMedicamentSQLite(
                          rappel: rappel,
                          patientId: patient.patientId!,
                        ),
                    ),

                  const SizedBox(height: 100),

                ]),
              ),
            ),

          ],
        );
      },
    );
  }
}

// Carte médicament connectée à SQLite
class _CarteMedicamentSQLite extends StatefulWidget {
  final Map<String, dynamic> rappel;
  final int patientId;

  const _CarteMedicamentSQLite({
    required this.rappel,
    required this.patientId,
  });

  @override
  State<_CarteMedicamentSQLite> createState() =>
      _CarteMedicamentSQLiteState();
}

class _CarteMedicamentSQLiteState
    extends State<_CarteMedicamentSQLite> {

  bool _pris = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _pris
              ? AppColors.success.withValues(alpha: 0.3)
              : const Color(0xFFE0E7EF),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [

          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: _pris
                  ? AppColors.success.withValues(alpha: 0.1)
                  : AppColors.primaryPale,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.medication_outlined,
              color: _pris ? AppColors.success : AppColors.primary,
              size: 22,
            ),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.rappel['nom_medicament'] ?? '',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _pris
                        ? AppColors.textSecondary
                        : AppColors.textPrimary,
                    decoration: _pris
                        ? TextDecoration.lineThrough
                        : TextDecoration.none,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${widget.rappel['dosage'] ?? ''} • ${widget.rappel['heure'] ?? ''}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          // Bouton confirmer prise
          GestureDetector(
            onTap: () async {
              setState(() => _pris = !_pris);
              if (_pris) {
                // Enregistre la prise dans SQLite
                await DatabaseService().enregistrerPrise(
                  traitementId: widget.rappel['id'] ?? 0,
                  patientId: widget.patientId,
                  statut: 'pris',
                );
                // Met à jour les stats
                if (context.mounted) {
                  context.read<PatientProvider>().chargerDonnees();
                }
              }
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 32, height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _pris ? AppColors.success : Colors.transparent,
                border: Border.all(
                  color: _pris
                      ? AppColors.success
                      : const Color(0xFFCFD8DC),
                  width: 1.5,
                ),
              ),
              child: _pris
                  ? const Icon(
                Icons.check,
                color: Colors.white, size: 16,
              )
                  : null,
            ),
          ),

        ],
      ),
    );
  }
}

// Carte statistique
class _CarteStatistique extends StatelessWidget {
  final IconData icone;
  final String valeur;
  final String label;
  final Color couleur;
  final Color fondCouleur;

  const _CarteStatistique({
    required this.icone,
    required this.valeur,
    required this.label,
    required this.couleur,
    required this.fondCouleur,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 38, height: 38,
              decoration: BoxDecoration(
                color: fondCouleur,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icone, color: couleur, size: 20),
            ),
            const SizedBox(height: 12),
            Text(
              valeur,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: couleur,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}