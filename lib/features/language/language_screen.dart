
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../onboarding/onboarding_screen.dart';
//import '../../core/l10n/app_translations.dart';
//import '../../core/services/session_service.dart';
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
      'passer':               'Passer',
      'suivant':              'Suivant',
      'commencer':            'Commencer',

      // Paramètres
      'parametres_titre':     'Paramètres',
      'changer_langue':       'Langue',
      'changer_langue_desc':  'Changer la langue de l\'application',
      'changer_pin':          'Changer le code PIN',
      'changer_pin_desc':     'Modifier votre code de sécurité',
      'notifs_rappels':       'Rappels médicaments',
      'notifs_rappels_desc':  'Recevoir des alertes pour vos prises',
      'securite':             'Sécurité',
      'a_propos':             'À propos',
      'version':              'Version',
      'udbl':                 'UDBL — MSI Lubumbashi',
      'centre_hospitalier':   'Centre Hospitalier Congo-Chine',

      // Agenda
      'agenda_titre':         'Mes rendez-vous',
      'ajouter_rdv':          'Ajouter un rendez-vous',
      'aucun_rdv_avenir':     'Aucun rendez-vous à venir.\nAppuyez sur + pour en créer un.',
      'aucun_rdv_passe':      'Aucun rendez-vous passé.',
      'motif_rdv':            'Motif du rendez-vous',
      'lieu_rdv':             'Lieu',
      'date_rdv':             'Date',
      'heure_rdv':            'Heure',
      'rdv_a_venir':          'À venir',
      'rdv_passes':           'Passés',
      'rdv_aujourd_hui':      'Aujourd\'hui',
      'lieu_hint':            'Ex. : Centre Hospitalier Congo-Chine',
      'motif_hint':           'Ex. : Consultation CD4',
      'choisir_date':         'Choisir une date',
      'choisir_heure':        'Choisir l\'heure',

      // Profil corrigé
      'mon_traitement':       'Mon traitement',
      'prochain_rdv':         'Prochain rendez-vous',
      'dernier_rdv':          'Dernier contrôle',
      'jours_actifs':         'Jours actifs',
      'prises_manquees':      'Prises manquées',
      'jours_total':          'Jours total',
      'choisir_langue_titre': 'Choisir la langue',
      'langue_actuelle':      'Langue actuelle',
      'francais':             'Français',
      'anglais':              'Anglais',
      'swahili':              'Kiswahili',
    },
    {
      'code': 'en',
      'nom': 'English',
      'indicatif': 'EN',
      'region': 'International',
      'couleur': '0xFF1976D2',
      'passer':               'Skip',
      'suivant':              'Next',
      'commencer':            'Get started',

      'parametres_titre':     'Settings',
      'changer_langue':       'Language',
      'changer_langue_desc':  'Change the app language',
      'changer_pin':          'Change PIN',
      'changer_pin_desc':     'Modify your security code',
      'notifs_rappels':       'Medication reminders',
      'notifs_rappels_desc':  'Receive alerts for your doses',
      'securite':             'Security',
      'a_propos':             'About',
      'version':              'Version',
      'udbl':                 'UDBL — MSI Lubumbashi',
      'centre_hospitalier':   'Congo-China Hospital Center',

      'agenda_titre':         'My appointments',
      'ajouter_rdv':          'Add appointment',
      'aucun_rdv_avenir':     'No upcoming appointments.\nTap + to create one.',
      'aucun_rdv_passe':      'No past appointments.',
      'motif_rdv':            'Reason',
      'lieu_rdv':             'Location',
      'date_rdv':             'Date',
      'heure_rdv':            'Time',
      'rdv_a_venir':          'Upcoming',
      'rdv_passes':           'Past',
      'rdv_aujourd_hui':      'Today',
      'lieu_hint':            'E.g. Congo-China Hospital Center',
      'motif_hint':           'E.g. CD4 consultation',
      'choisir_date':         'Choose a date',
      'choisir_heure':        'Choose time',

      'mon_traitement':       'My treatment',
      'prochain_rdv':         'Next appointment',
      'dernier_rdv':          'Last check-up',
      'jours_actifs':         'Active days',
      'prises_manquees':      'Missed doses',
      'jours_total':          'Total days',
      'choisir_langue_titre': 'Choose language',
      'langue_actuelle':      'Current language',
      'francais':             'French',
      'anglais':              'English',
      'swahili':              'Swahili',
    },
    {
      'code': 'sw',
      'nom': 'Kiswahili',
      'indicatif': 'SW',
      'region': 'Afrique de l\'Est · Grands Lacs',
      'couleur': '0xFF0277BD',
      'passer':               'Ruka',
      'suivant':              'Ifuatayo',
      'commencer':            'Anza',

      'parametres_titre':     'Mipangilio',
      'changer_langue':       'Lugha',
      'changer_langue_desc':  'Badilisha lugha ya programu',
      'changer_pin':          'Badilisha PIN',
      'changer_pin_desc':     'Badilisha msimbo wako wa usalama',
      'notifs_rappels':       'Vikumbusho vya dawa',
      'notifs_rappels_desc':  'Pokea tahadhari kwa dozi zako',
      'securite':             'Usalama',
      'a_propos':             'Kuhusu',
      'version':              'Toleo',
      'udbl':                 'UDBL — MSI Lubumbashi',
      'centre_hospitalier':   'Kituo cha Hospitali cha Congo-China',

      'agenda_titre':         'Miadi yangu',
      'ajouter_rdv':          'Ongeza miadi',
      'aucun_rdv_avenir':     'Hakuna miadi ijayo.\nBonyeza + kuunda moja.',
      'aucun_rdv_passe':      'Hakuna miadi iliyopita.',
      'motif_rdv':            'Sababu',
      'lieu_rdv':             'Mahali',
      'date_rdv':             'Tarehe',
      'heure_rdv':            'Wakati',
      'rdv_a_venir':          'Ijayo',
      'rdv_passes':           'Zilizopita',
      'rdv_aujourd_hui':      'Leo',
      'lieu_hint':            'Mfano: Kituo cha Hospitali cha Congo-China',
      'motif_hint':           'Mfano: Mashauriano ya CD4',
      'choisir_date':         'Chagua tarehe',
      'choisir_heure':        'Chagua wakati',

      'mon_traitement':       'Matibabu yangu',
      'prochain_rdv':         'Miadi ijayo',
      'dernier_rdv':          'Ukaguzi wa mwisho',
      'jours_actifs':         'Siku za kazi',
      'prises_manquees':      'Dozi zilizokosekana',
      'jours_total':          'Jumla ya siku',
      'choisir_langue_titre': 'Chagua lugha',
      'langue_actuelle':      'Lugha ya sasa',
      'francais':             'Kifaransa',
      'anglais':              'Kiingereza',
      'swahili':              'Kiswahili',
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
