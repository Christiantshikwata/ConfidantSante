import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../auth/role_screen.dart';
// Les données de chaque slide
// On les définit ici pour ne pas encombrer le widget principal
class _SlideData {
  final IconData icone;
  final String titre;
  final String description;
  final Color couleurIcone;

  const _SlideData({
    required this.icone,
    required this.titre,
    required this.description,
    required this.couleurIcone,
  });
}

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {

  // PageController : gère le défilement entre les slides
  final PageController _pageController = PageController();

  // L'index de la slide actuellement visible (0, 1 ou 2)
  int _slideActuel = 0;

  // Les 3 slides de l'onboarding
  final List<_SlideData> _slides = const [
    _SlideData(
      icone: Icons.notifications_active_outlined,
      titre: 'Rappels intelligents',
      description:
      'Ne manquez plus jamais une prise. ConfidantSanté vous envoie '
          'des rappels au bon moment, même sans connexion internet.',
      couleurIcone: Color(0xFF1565C0),
    ),
    _SlideData(
      icone: Icons.shield_outlined,
      titre: 'Vie privée protégée',
      description:
      'Vos données médicales restent sur votre appareil. '
          'Le mode discrétion masque l\'application d\'un simple geste '
          'pour protéger votre confidentialité en public.',
      couleurIcone: Color(0xFF0277BD),
    ),
    _SlideData(
      icone: Icons.cloud_off_outlined,
      titre: 'Fonctionne hors ligne',
      description:
      'Pas de réseau ? Aucun problème. L\'application continue '
          'de fonctionner normalement et synchronise vos données '
          'dès que la connexion est rétablie.',
      couleurIcone: Color(0xFF2E7D32),
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // Aller au slide suivant ou terminer l'onboarding
  void _slidesSuivant() {
    if (_slideActuel < _slides.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    } else {
      // Dernier slide — on navigue vers le choix de rôle
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const RoleScreen(),
        ),
      );
    }
  }

  // Passer directement à la fin
  void _passer() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const RoleScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      body: SafeArea(
        child: Column(
          children: [

            // Bouton Passer en haut à droite
            Padding(
              padding: const EdgeInsets.only(
                top: 12,
                right: 20,
              ),
              child: Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _passer,
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.textSecondary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                  ),
                  child: const Text(
                    'Passer',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),

            // Zone des slides — prend tout l'espace disponible
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _slides.length,
                // onPageChanged : appelé quand l'utilisateur
                // swipe vers un autre slide
                onPageChanged: (index) {
                  setState(() {
                    _slideActuel = index;
                  });
                },
                itemBuilder: (context, index) {
                  return _SlideWidget(slide: _slides[index]);
                },
              ),
            ),

            // Zone inférieure : indicateurs + bouton
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
              child: Column(
                children: [

                  // Indicateurs de progression (les petits points)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _slides.length,
                          (index) => _IndicateurPoint(
                        estActif: index == _slideActuel,
                      ),
                    ),
                  ),

                  const SizedBox(height: 28),

                  // Bouton Suivant / Commencer
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _slidesSuivant,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      // Le texte du bouton change au dernier slide
                      child: Text(
                        _slideActuel == _slides.length - 1
                            ? 'Commencer'
                            : 'Suivant',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ),

                ],
              ),
            ),

          ],
        ),
      ),
    );
  }
}

// Widget pour afficher le contenu d'un slide
class _SlideWidget extends StatelessWidget {
  final _SlideData slide;

  const _SlideWidget({required this.slide});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [

          // Illustration — icône dans un cercle
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              color: slide.couleurIcone.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: slide.couleurIcone.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  slide.icone,
                  size: 44,
                  color: slide.couleurIcone,
                ),
              ),
            ),
          ),

          const SizedBox(height: 48),

          // Titre
          Text(
            slide.titre,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              letterSpacing: 0.2,
              height: 1.3,
            ),
          ),

          const SizedBox(height: 16),

          // Description
          Text(
            slide.description,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              color: AppColors.textSecondary,
              height: 1.65,
              fontWeight: FontWeight.w400,
            ),
          ),

        ],
      ),
    );
  }
}

// Point indicateur de progression
class _IndicateurPoint extends StatelessWidget {
  final bool estActif;

  const _IndicateurPoint({required this.estActif});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: estActif ? 24 : 8,
      height: 8,
      decoration: BoxDecoration(
        // Point actif : bleu et allongé
        // Point inactif : gris et rond
        color: estActif
            ? AppColors.primary
            : const Color(0xFFCFD8DC),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

