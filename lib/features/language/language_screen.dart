
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../onboarding/onboarding_screen.dart';
import '../../core/l10n/app_translations.dart';
import '../../core/services/session_service.dart';
import 'package:provider/provider.dart';
import '../../core/providers/langue_provider.dart';
class LanguageScreen extends StatefulWidget {
  const LanguageScreen({super.key});

  @override
  State<LanguageScreen> createState() => _LanguageScreenState();
}

class _LanguageScreenState extends State<LanguageScreen> {
  String _langueChoisie = 'fr';

  final List<Map<String, String>> _langues = [
    {
      'code': 'fr',
      'nom': 'Français',
      'indicatif': '+243',
      'region': 'RD Congo · Afrique centrale',
      'couleur': '0xFF1565C0',
    },
    {
      'code': 'en',
      'nom': 'English',
      'indicatif': 'EN',
      'region': 'International',
      'couleur': '0xFF1976D2',
    },
    {
      'code': 'sw',
      'nom': 'Kiswahili',
      'indicatif': 'SW',
      'region': 'Afrique de l\'Est · Grands Lacs',
      'couleur': '0xFF0277BD',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 20,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              const SizedBox(height: 32),

              // En-tête
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.primaryPale,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.language_outlined,
                      color: AppColors.primary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Langue / Language',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                            letterSpacing: 0.2,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Choisissez votre langue préférée',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 40),

              // Cartes de langue
              ..._langues.map((langue) => _CarteLangue(
                code: langue['code']!,
                nom: langue['nom']!,
                indicatif: langue['indicatif']!,
                region: langue['region']!,
                estSelectionnee: _langueChoisie == langue['code'],
                onTap: () {
                  setState(() {
                    _langueChoisie = langue['code']!;
                  });
                },
              )),

              const Spacer(),

              // Bouton Continuer
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () async {
                    // Change la langue via le Provider
                    await context.read<LangueProvider>().changerLangue(_langueChoisie);

                    if (!context.mounted) return;
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const OnboardingScreen(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Continuer',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Note de confidentialité
              Center(
                child: Text(
                  'Vos données restent confidentielles sur cet appareil',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary.withValues(alpha: 0.7),
                    letterSpacing: 0.1,
                  ),
                ),
              ),

              const SizedBox(height: 8),

            ],
          ),
        ),
      ),
    );
  }
}

// Carte de langue professionnelle
class _CarteLangue extends StatelessWidget {
  final String code;
  final String nom;
  final String indicatif;
  final String region;
  final bool estSelectionnee;
  final VoidCallback onTap;

  const _CarteLangue({
    required this.code,
    required this.nom,
    required this.indicatif,
    required this.region,
    required this.estSelectionnee,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        decoration: BoxDecoration(
          color: estSelectionnee
              ? AppColors.primaryPale
              : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: estSelectionnee
                ? AppColors.primary
                : const Color(0xFFE0E7EF),
            width: estSelectionnee ? 1.5 : 1,
          ),
          boxShadow: estSelectionnee
              ? [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ]
              : [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [

            // Badge indicatif
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: estSelectionnee
                    ? AppColors.primary
                    : const Color(0xFFEEF2F7),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  indicatif,
                  style: TextStyle(
                    fontSize: indicatif.length > 3 ? 11 : 13,
                    fontWeight: FontWeight.w700,
                    color: estSelectionnee
                        ? Colors.white
                        : AppColors.textSecondary,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ),

            const SizedBox(width: 16),

            // Nom et région
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    nom,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: estSelectionnee
                          ? AppColors.primary
                          : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    region,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),

            // Indicateur de sélection
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: estSelectionnee
                    ? AppColors.primary
                    : Colors.transparent,
                border: Border.all(
                  color: estSelectionnee
                      ? AppColors.primary
                      : const Color(0xFFCFD8DC),
                  width: 1.5,
                ),
              ),
              child: estSelectionnee
                  ? const Icon(
                Icons.check,
                color: Colors.white,
                size: 14,
              )
                  : null,
            ),

          ],
        ),
      ),
    );
  }
}

// Placeholder onboarding
