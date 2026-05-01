import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import 'rappels_screen.dart';
import 'discretion_screen.dart';
import 'profil_screen.dart';

class DashboardPatientScreen extends StatefulWidget {
  const DashboardPatientScreen({super.key});

  @override
  State<DashboardPatientScreen> createState() =>
      _DashboardPatientScreenState();
}

class _DashboardPatientScreenState extends State<DashboardPatientScreen> {

  // Index de la page active dans la bottom navigation
  int _pageActive = 0;

  // Les pages de la bottom navigation
  final List<Widget> _pages = const [
    _PageAccueil(),
    _PageRappels(),
    _PageDiscretion(),
    _PageProfil(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),

      // Corps principal
      body: _pages[_pageActive],

      // Barre de navigation du bas
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
          onTap: (index) => setState(() => _pageActive = index),
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

// ── PAGE ACCUEIL ─────────────────────────────────────────────────────────────

class _PageAccueil extends StatelessWidget {
  const _PageAccueil();

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [

        // En-tête avec dégradé
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

                    // Ligne du haut : salutation + avatar
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _salutation(),
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.75),
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 2),
                              const Text(
                                'Christian 👋',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Avatar initiales
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.4),
                              width: 1.5,
                            ),
                          ),
                          child: const Center(
                            child: Text(
                              'CN',
                              style: TextStyle(
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

                    // Carte observance
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
                                  color: Colors.white.withValues(alpha: 0.8),
                                  fontSize: 13,
                                ),
                              ),
                              const Text(
                                '87%',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          // Barre de progression
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: 0.87,
                              backgroundColor:
                              Colors.white.withValues(alpha: 0.25),
                              valueColor:
                              const AlwaysStoppedAnimation(Colors.white),
                              minHeight: 8,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '26 / 30 prises effectuées',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.65),
                                  fontSize: 11,
                                ),
                              ),
                              Text(
                                '4 manquées',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.65),
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

        // Contenu scrollable
        SliverPadding(
          padding: const EdgeInsets.all(20),
          sliver: SliverList(
            delegate: SliverChildListDelegate([

              // Stats rapides
              Row(
                children: [
                  _CarteStatistique(
                    icone: Icons.alarm_outlined,
                    valeur: '3',
                    label: "Rappels aujourd'hui",
                    couleur: AppColors.primary,
                    fondCouleur: AppColors.primaryPale,
                  ),
                  const SizedBox(width: 12),
                  _CarteStatistique(
                    icone: Icons.calendar_today_outlined,
                    valeur: '26',
                    label: 'Jours actifs',
                    couleur: AppColors.success,
                    fondCouleur: const Color(0xFFE8F5E9),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Titre section rappels
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Prochains rappels',
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

              // Liste des médicaments
              _CarteMedicament(
                nom: 'Lamivudine 150mg',
                heure: 'Matin • 08h00',
                couleurIcone: AppColors.primary,
                estPris: true,
              ),
              const SizedBox(height: 10),
              _CarteMedicament(
                nom: 'Efavirenz 600mg',
                heure: 'Soir • 21h00',
                couleurIcone: AppColors.warning,
                estPris: false,
              ),
              const SizedBox(height: 10),
              _CarteMedicament(
                nom: 'Ténofovir 300mg',
                heure: 'Soir • 21h00',
                couleurIcone: const Color(0xFF7B1FA2),
                estPris: false,
              ),

              const SizedBox(height: 24),

              // Prochain rendez-vous
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFFE0E7EF),
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
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.primaryPale,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.event_outlined,
                        color: AppColors.primary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Prochain rendez-vous',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          SizedBox(height: 3),
                          Text(
                            '20 avril 2026 — Dr. Ndetereyuwe',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right,
                      color: AppColors.textSecondary,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 100),

            ]),
          ),
        ),

      ],
    );
  }

  // Retourne la salutation selon l'heure
  static String _salutation() {
    final heure = DateTime.now().hour;
    if (heure < 12) return 'Bonjour,';
    if (heure < 17) return 'Bon après-midi,';
    return 'Bonsoir,';
  }
}

// ── CARTE STATISTIQUE ────────────────────────────────────────────────────────

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
              width: 38,
              height: 38,
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

// ── CARTE MÉDICAMENT ─────────────────────────────────────────────────────────

class _CarteMedicament extends StatefulWidget {
  final String nom;
  final String heure;
  final Color couleurIcone;
  final bool estPris;

  const _CarteMedicament({
    required this.nom,
    required this.heure,
    required this.couleurIcone,
    required this.estPris,
  });

  @override
  State<_CarteMedicament> createState() => _CarteMedicamentState();
}

class _CarteMedicamentState extends State<_CarteMedicament> {
  late bool _pris;

  @override
  void initState() {
    super.initState();
    _pris = widget.estPris;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
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

          // Icône médicament
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: widget.couleurIcone.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.medication_outlined,
              color: widget.couleurIcone,
              size: 22,
            ),
          ),

          const SizedBox(width: 14),

          // Nom et heure
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.nom,
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
                  widget.heure,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          // Bouton confirmer la prise
          GestureDetector(
            onTap: () => setState(() => _pris = !_pris),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _pris
                    ? AppColors.success
                    : Colors.transparent,
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
                color: Colors.white,
                size: 16,
              )
                  : null,
            ),
          ),

        ],
      ),
    );
  }
}

// ── PAGES PLACEHOLDER ────────────────────────────────────────────────────────

class _PageRappels extends StatelessWidget {
  const _PageRappels();

  @override
  Widget build(BuildContext context) {
    return const RappelsScreen();
  }
}
class _PageDiscretion extends StatelessWidget {
  const _PageDiscretion();

  @override
  Widget build(BuildContext context) {
    return const DiscretionScreen();
  }
}

class _PageProfil extends StatelessWidget {
  const _PageProfil();

  @override
  Widget build(BuildContext context) {
    return const ProfilScreen();
  }
}

class _PageEnConstruction extends StatelessWidget {
  final String titre;
  final IconData icone;

  const _PageEnConstruction({
    required this.titre,
    required this.icone,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icone,
                size: 64,
                color: AppColors.primary.withValues(alpha: 0.4),
              ),
              const SizedBox(height: 20),
              Text(
                titre,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Prochaine étape...',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}