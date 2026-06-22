import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/l10n/app_translations.dart';
import '../../core/providers/patient_provider.dart';
import '../../core/providers/langue_provider.dart';
import '../../core/services/database_service.dart';
import '../messagerie/messagerie_screen.dart';
import 'agenda_screen.dart';
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
    context.watch<LangueProvider>();
    final t = AppTranslations.t;

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
          items: [
            BottomNavigationBarItem(
              icon: const Icon(Icons.home_outlined),
              activeIcon: const Icon(Icons.home),
              label: t('accueil'),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.alarm_outlined),
              activeIcon: const Icon(Icons.alarm),
              label: t('rappels'),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.shield_outlined),
              activeIcon: const Icon(Icons.shield),
              label: t('discretion'),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.person_outline),
              activeIcon: const Icon(Icons.person),
              label: t('profil'),
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

  static String _salutationCle() {
    final h = DateTime.now().hour;
    if (h < 12) return 'bonjour';
    if (h < 17) return 'bon_apres_midi';
    return 'bonsoir';
  }

  // Ouvre la conversation avec le médecin référent RÉEL du patient
  // (repli sur le médecin de démonstration si non renseigné).
  Future<void> _ouvrirMessagerie(
      BuildContext context, PatientProvider patient) async {
    final numero = patient.numero;
    if (numero.isEmpty) return;
    final row = await DatabaseService().getPatient(numero);
    final mat = (row?['soignant_matricule'] as String?)?.trim();
    final nomMed = (row?['soignant'] as String?)?.trim();
    final matricule = (mat != null && mat.isNotEmpty)
        ? mat
        : DatabaseService.soignantDemoMatricule;
    final destinataire = (nomMed != null && nomMed.isNotEmpty)
        ? nomMed
        : 'Dr. Yves Ndetereyuwe';
    if (!context.mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MessagerieScreen(
          conversationId: MessagerieScreen.conversationIdPour(
            patientNumero: numero,
            soignantMatricule: matricule,
          ),
          monId: numero,
          destinataireNom: destinataire,
          role: 'patient',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    context.watch<LangueProvider>();
    final t = AppTranslations.t;

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
                                    t(_salutationCle()),
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
                                        : t('patient'),
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

                            const SizedBox(width: 12),

                            // Bouton messagerie — coin haut-droite, bien visible
                            // (cercle blanc plein, icône contrastée).
                            GestureDetector(
                              onTap: () => _ouvrirMessagerie(context, patient),
                              child: Container(
                                width: 46, height: 46,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.15),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: const Center(
                                  child: Icon(
                                    Icons.chat_bubble_rounded,
                                    color: AppColors.primary,
                                    size: 22,
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
                                    t('observance'),
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
                                    '${patient.joursActifs} ${t('prises_effectuees')}',
                                    style: TextStyle(
                                      color: Colors.white
                                          .withValues(alpha: 0.65),
                                      fontSize: 11,
                                    ),
                                  ),
                                  Text(
                                    '${patient.historique.length - patient.joursActifs} ${t('manquees')}',
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
                        label: t('rappels_configures'),
                        couleur: AppColors.primary,
                        fondCouleur: AppColors.primaryPale,
                      ),
                      const SizedBox(width: 12),
                      _CarteStatistique(
                        icone: Icons.calendar_today_outlined,
                        valeur: '${patient.joursActifs}',
                        label: t('jours_actifs'),
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
                      Text(
                        t('medicaments_du_jour'),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const AgendaScreen()),
                        ),
                        child: Text(
                          'Voir l\'agenda',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w500,
                          ),
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
                          Text(
                            t('aucun_rappel'),
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            t('aucun_rappel_desc'),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    ...patient.rappels.map((rappel) =>
                        _CarteMedicamentSQLite(rappel: rappel),
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
class _CarteMedicamentSQLite extends StatelessWidget {
  final Map<String, dynamic> rappel;

  const _CarteMedicamentSQLite({required this.rappel});

  @override
  Widget build(BuildContext context) {
    final pris = context.select<PatientProvider, bool>(
      (p) => p.estPrisAujourdhui(rappel['id'] as int? ?? -1),
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: pris
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
              color: pris
                  ? AppColors.success.withValues(alpha: 0.1)
                  : AppColors.primaryPale,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.medication_outlined,
              color: pris ? AppColors.success : AppColors.primary,
              size: 22,
            ),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  rappel['nom_medicament'] ?? '',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: pris
                        ? AppColors.textSecondary
                        : AppColors.textPrimary,
                    decoration: pris
                        ? TextDecoration.lineThrough
                        : TextDecoration.none,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${rappel['dosage'] ?? ''} • ${rappel['heure'] ?? ''}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          // Bouton confirmer prise (idempotent : une fois par jour)
          GestureDetector(
            onTap: pris
                ? null
                : () async {
                    await context
                        .read<PatientProvider>()
                        .confirmerPrise(rappel['id'] as int? ?? 0);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('✓ ${rappel['nom_medicament']} pris'),
                          backgroundColor: AppColors.success,
                          duration: const Duration(seconds: 2),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          margin: const EdgeInsets.all(16),
                        ),
                      );
                    }
                  },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 40, height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: pris ? AppColors.success : Colors.transparent,
                border: Border.all(
                  color: pris ? AppColors.success : const Color(0xFFCFD8DC),
                  width: 1.5,
                ),
              ),
              child: pris
                  ? const Icon(Icons.check, color: Colors.white, size: 20)
                  : const Icon(Icons.medication_outlined,
                      color: AppColors.primary, size: 20),
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