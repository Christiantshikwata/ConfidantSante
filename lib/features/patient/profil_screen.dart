import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class ProfilScreen extends StatefulWidget {
  const ProfilScreen({super.key});

  @override
  State<ProfilScreen> createState() => _ProfilScreenState();
}

class _ProfilScreenState extends State<ProfilScreen> {

  // Données du patient — on les remplacera par Firebase plus tard
  final String _nom = 'Christian Ngoy';
  final String _telephone = '+243 8X XXX XXXX';
  final String _soignant = 'Dr. Ndetereyuwe';
  final String _hopital = 'Centre Hospitalier Congo-Chine';
  final String _dateDebut = '06 mars 2026';
  final String _prochainRdv = '20 avril 2026';
  final double _observance = 0.87;
  final int _joursActifs = 26;
  final int _totalJours = 30;

  // Historique simulé — true = pris, false = manqué
  final List<bool> _historique = [
    true, true, true, false, true, true, true,
    true, true, false, true, true, true, true,
    true, true, true, true, true, false, true,
    true, true, true, true, true, true, true,
    true, false,
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      body: CustomScrollView(
        slivers: [

          // En-tête avec avatar
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

                      // Ligne titre + paramètres
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Mon profil',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          GestureDetector(
                            onTap: _ouvrirParametres,
                            child: Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.settings_outlined,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // Avatar + infos
                      Row(
                        children: [

                          // Avatar initiales
                          Container(
                            width: 70,
                            height: 70,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withValues(alpha: 0.2),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.4),
                                width: 2,
                              ),
                            ),
                            child: const Center(
                              child: Text(
                                'CN',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(width: 16),

                          // Nom et badge
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _nom,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _telephone,
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.7),
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: Colors.white.withValues(alpha: 0.3),
                                    ),
                                  ),
                                  child: Text(
                                    'Observance ${(_observance * 100).toInt()}%',
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

          // Contenu
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([

                // Stats résumées
                Row(
                  children: [
                    _CarteStatProfil(
                      valeur: '$_joursActifs',
                      label: 'Jours actifs',
                      icone: Icons.check_circle_outline,
                      couleur: AppColors.success,
                      fond: const Color(0xFFE8F5E9),
                    ),
                    const SizedBox(width: 12),
                    _CarteStatProfil(
                      valeur: '${_totalJours - _joursActifs}',
                      label: 'Prises manquées',
                      icone: Icons.cancel_outlined,
                      couleur: AppColors.danger,
                      fond: const Color(0xFFFFEBEE),
                    ),
                    const SizedBox(width: 12),
                    _CarteStatProfil(
                      valeur: '$_totalJours',
                      label: 'Jours total',
                      icone: Icons.calendar_month_outlined,
                      couleur: AppColors.primary,
                      fond: AppColors.primaryPale,
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Mon traitement
                _titreSec('Mon traitement'),
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
                      _ligneInfo(
                        icone: Icons.medication_outlined,
                        label: 'Protocole',
                        valeur: 'Lam. + Efa. + Tén.',
                        dernier: false,
                      ),
                      _ligneInfo(
                        icone: Icons.calendar_today_outlined,
                        label: 'Début du traitement',
                        valeur: _dateDebut,
                        dernier: false,
                      ),
                      _ligneInfo(
                        icone: Icons.event_outlined,
                        label: 'Prochain RDV',
                        valeur: _prochainRdv,
                        couleurValeur: AppColors.primary,
                        dernier: false,
                      ),
                      _ligneInfo(
                        icone: Icons.person_outline,
                        label: 'Soignant',
                        valeur: _soignant,
                        dernier: false,
                      ),
                      _ligneInfo(
                        icone: Icons.local_hospital_outlined,
                        label: 'Hôpital',
                        valeur: _hopital,
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
                    _titreSec('Historique 30 jours'),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primaryPale,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${(_observance * 100).toInt()}% observance',
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
                  child: Column(
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

                      // Grille des 30 jours
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 7,
                          crossAxisSpacing: 4,
                          mainAxisSpacing: 4,
                        ),
                        itemCount: _historique.length,
                        itemBuilder: (context, index) {
                          final pris = _historique[index];
                          final jour = DateTime.now()
                              .subtract(Duration(
                            days: _historique.length - 1 - index,
                          ))
                              .day;

                          return Tooltip(
                            message: pris ? 'Pris' : 'Manqué',
                            child: Container(
                              decoration: BoxDecoration(
                                color: pris
                                    ? AppColors.primary
                                    : const Color(0xFFFFCDD2),
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: Center(
                                child: Text(
                                  '$jour',
                                  style: TextStyle(
                                    fontSize: 9,
                                    color: pris
                                        ? Colors.white
                                        : AppColors.danger,
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
                          _legendeCal(AppColors.primary, 'Pris'),
                          const SizedBox(width: 20),
                          _legendeCal(
                            const Color(0xFFFFCDD2),
                            'Manqué',
                            textColor: AppColors.danger,
                          ),
                        ],
                      ),

                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Paramètres
                _titreSec('Paramètres'),
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
                      _optionParametre(
                        icone: Icons.language_outlined,
                        couleurIcone: AppColors.primary,
                        fond: AppColors.primaryPale,
                        label: 'Langue de l\'application',
                        valeur: 'Français',
                        onTap: () {},
                        dernier: false,
                      ),
                      _optionParametre(
                        icone: Icons.shield_outlined,
                        couleurIcone: const Color(0xFF263238),
                        fond: const Color(0xFFECEFF1),
                        label: 'Mode discrétion',
                        valeur: 'Configuré',
                        onTap: () {},
                        dernier: false,
                      ),
                      _optionParametre(
                        icone: Icons.notifications_outlined,
                        couleurIcone: AppColors.warning,
                        fond: const Color(0xFFFFF8E1),
                        label: 'Notifications',
                        valeur: 'Activées',
                        onTap: () {},
                        dernier: false,
                      ),
                      _optionParametre(
                        icone: Icons.lock_outline,
                        couleurIcone: AppColors.success,
                        fond: const Color(0xFFE8F5E9),
                        label: 'Changer le PIN',
                        onTap: () {},
                        dernier: true,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Bouton déconnexion
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: OutlinedButton.icon(
                    onPressed: _deconnecter,
                    icon: const Icon(
                      Icons.logout,
                      size: 18,
                      color: AppColors.danger,
                    ),
                    label: const Text(
                      'Se déconnecter',
                      style: TextStyle(
                        color: AppColors.danger,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(
                        color: AppColors.danger,
                        width: 1.5,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
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

  // Ouvre les paramètres
  void _ouvrirParametres() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Paramètres — prochaine étape'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // Déconnexion avec confirmation
  void _deconnecter() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text(
          'Se déconnecter ?',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: const Text(
          'Vous devrez vous reconnecter avec '
              'votre numéro de téléphone.',
          style: TextStyle(fontSize: 14, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Annuler',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Navigation vers l'écran de rôle
              Navigator.of(context).pushNamedAndRemoveUntil(
                '/',
                    (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Se déconnecter'),
          ),
        ],
      ),
    );
  }

  // Helpers
  Widget _titreSec(String titre) {
    return Text(
      titre,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        letterSpacing: 0.2,
      ),
    );
  }

  Widget _ligneInfo({
    required IconData icone,
    required String label,
    required String valeur,
    Color? couleurValeur,
    required bool dernier,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 14,
      ),
      decoration: BoxDecoration(
        border: dernier
            ? null
            : const Border(
          bottom: BorderSide(
            color: Color(0xFFF0F4F8),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(icone, size: 18, color: AppColors.primary),
          const SizedBox(width: 12),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          const Spacer(),
          Text(
            valeur,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: couleurValeur ?? AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _optionParametre({
    required IconData icone,
    required Color couleurIcone,
    required Color fond,
    required String label,
    String? valeur,
    required VoidCallback onTap,
    required bool dernier,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        decoration: BoxDecoration(
          border: dernier
              ? null
              : const Border(
            bottom: BorderSide(
              color: Color(0xFFF0F4F8),
              width: 1,
            ),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: fond,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icone, size: 18, color: couleurIcone),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            if (valeur != null)
              Text(
                valeur,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            const SizedBox(width: 6),
            const Icon(
              Icons.chevron_right,
              size: 18,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _legendeCal(
      Color couleur,
      String label, {
        Color? textColor,
      }) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: couleur,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: textColor ?? AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

// Carte statistique du profil
class _CarteStatProfil extends StatelessWidget {
  final String valeur;
  final String label;
  final IconData icone;
  final Color couleur;
  final Color fond;

  const _CarteStatProfil({
    required this.valeur,
    required this.label,
    required this.icone,
    required this.couleur,
    required this.fond,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: 14,
          horizontal: 10,
        ),
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
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: fond,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icone, size: 18, color: couleur),
            ),
            const SizedBox(height: 8),
            Text(
              valeur,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: couleur,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 10,
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