import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import 'login_patient_screen.dart';
import '../soignant/dashboard_soignant_screen.dart';
class RoleScreen extends StatefulWidget {
  const RoleScreen({super.key});

  @override
  State<RoleScreen> createState() => _RoleScreenState();
}

class _RoleScreenState extends State<RoleScreen> {

  // Le rôle sélectionné — null au départ
  String? _roleChoisi;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              const SizedBox(height: 40),

              // En-tête
              const Text(
                'Vous êtes ?',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  letterSpacing: 0.2,
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                'Choisissez votre profil pour accéder '
                    'à l\'interface adaptée à vos besoins.',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),

              const SizedBox(height: 40),

              // Carte Patient
              _CarteRole(
                titre: 'Patient',
                description:
                'Suivre mon traitement, '
                    'gérer mes rappels et '
                    'consulter mon historique.',
                icone: Icons.person_outline,
                estSelectionne: _roleChoisi == 'patient',
                onTap: () {
                  setState(() => _roleChoisi = 'patient');
                },
              ),

              const SizedBox(height: 14),

              // Carte Soignant
              _CarteRole(
                titre: 'Soignant',
                description:
                'Suivre l\'observance de mes patients '
                    'et gérer les protocoles de traitement.',
                icone: Icons.medical_services_outlined,
                estSelectionne: _roleChoisi == 'soignant',
                onTap: () {
                  setState(() => _roleChoisi = 'soignant');
                },
              ),

              const Spacer(),

              // Note de sécurité
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.primaryPale,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.lock_outline,
                      size: 16,
                      color: AppColors.primary.withValues(alpha: 0.7),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Votre choix détermine l\'interface '
                            'et les données accessibles.',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Bouton Continuer — désactivé si rien n'est choisi
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  // Si aucun rôle choisi, le bouton est désactivé
                  onPressed: _roleChoisi == null
                      ? null
                      : () {
                    if (_roleChoisi == 'patient') {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                          const LoginPatientScreen(),
                        ),
                      );
                    } else {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                          const LoginSoignantScreen(),
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    // Bouton grisé si désactivé
                    disabledBackgroundColor: const Color(0xFFCFD8DC),
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

            ],
          ),
        ),
      ),
    );
  }
}

// Widget carte de rôle
class _CarteRole extends StatelessWidget {
  final String titre;
  final String description;
  final IconData icone;
  final bool estSelectionne;
  final VoidCallback onTap;

  const _CarteRole({
    required this.titre,
    required this.description,
    required this.icone,
    required this.estSelectionne,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: estSelectionne
              ? AppColors.primaryPale
              : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: estSelectionne
                ? AppColors.primary
                : const Color(0xFFE0E7EF),
            width: estSelectionne ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: estSelectionne
                  ? AppColors.primary.withValues(alpha: 0.08)
                  : Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [

            // Icône dans un cercle
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: estSelectionne
                    ? AppColors.primary
                    : const Color(0xFFEEF2F7),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                icone,
                size: 26,
                color: estSelectionne
                    ? Colors.white
                    : AppColors.textSecondary,
              ),
            ),

            const SizedBox(width: 16),

            // Texte
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titre,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: estSelectionne
                          ? AppColors.primary
                          : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 12),

            // Indicateur de sélection
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: estSelectionne
                    ? AppColors.primary
                    : Colors.transparent,
                border: Border.all(
                  color: estSelectionne
                      ? AppColors.primary
                      : const Color(0xFFCFD8DC),
                  width: 1.5,
                ),
              ),
              child: estSelectionne
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

// Placeholders — on les codera dans les prochaines étapes


class LoginSoignantScreen extends StatelessWidget {
  const LoginSoignantScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) =>
                const DashboardSoignantScreen(),
              ),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0288D1),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(
              horizontal: 32, vertical: 16,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: const Text(
            'Accéder au tableau de bord soignant',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}