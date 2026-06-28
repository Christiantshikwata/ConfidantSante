
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/l10n/app_translations.dart';
import '../../core/services/icon_service.dart';

class _Apparence {
  final String id;
  final IconData icone;
  final String nom;
  final String description;
  final Color couleur;

  const _Apparence({
    required this.id,
    required this.icone,
    required this.nom,
    required this.description,
    required this.couleur,
  });
}

class DiscretionScreen extends StatefulWidget {
  const DiscretionScreen({super.key});

  @override
  State<DiscretionScreen> createState() => _DiscretionScreenState();
}

class _DiscretionScreenState extends State<DiscretionScreen>
    with SingleTickerProviderStateMixin {

  bool _camouflageActif = false;
  String _apparenceChoisie = 'calculatrice';
  bool _enChargement = false;

  late AnimationController _animController;
  late Animation<double> _animation;

  final List<_Apparence> _apparences = const [
    _Apparence(
      id: 'calculatrice',
      icone: Icons.calculate_outlined,
      nom: 'Calculatrice',
      description: 'L\'app ressemble à une calculatrice',
      couleur: Color(0xFF1565C0),
    ),
    _Apparence(
      id: 'meteo',
      icone: Icons.wb_sunny_outlined,
      nom: 'Météo',
      description: 'L\'app ressemble à une app météo',
      couleur: Color(0xFFF57F17),
    ),
    _Apparence(
      id: 'notes',
      icone: Icons.note_outlined,
      nom: 'Notes',
      description: 'L\'app ressemble à un bloc-notes',
      couleur: Color(0xFF6A1B9A),
    ),
    _Apparence(
      id: 'minuteur',
      icone: Icons.timer_outlined,
      nom: 'Minuteur',
      description: 'L\'app ressemble à un minuteur',
      couleur: Color(0xFF00897B),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _animation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeInOut,
    );
    _chargerEtat();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _chargerEtat() async {
    final actif = await IconService().isCamouflageActif();
    final apparence = await IconService().getApparenceActive();
    if (mounted) {
      setState(() {
        _camouflageActif = actif;
        _apparenceChoisie = apparence == 'normal' ? 'calculatrice' : apparence;
      });
      if (actif) _animController.forward();
    }
  }

  Future<void> _toggleCamouflage(bool valeur) async {
    setState(() {
      _camouflageActif = valeur;
      _enChargement = true;
    });

    if (valeur) {
      _animController.forward();

      // Change l'icône externe
      final succes = await IconService().changerIcone(_apparenceChoisie);

      setState(() => _enChargement = false);

      if (mounted) _afficherConfirmation(succes);
    } else {
      _animController.reverse();

      // Revient à l'icône normale
      await IconService().desactiverCamouflage();
      setState(() => _enChargement = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Mode discrétion désactivé — icône normale restaurée'),
            backgroundColor: AppColors.textSecondary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    }
  }

  Future<void> _changerApparenceActive(String nouvelleApparence) async {
    setState(() => _apparenceChoisie = nouvelleApparence);

    // Si le camouflage est actif, change l'icône immédiatement
    if (_camouflageActif) {
      setState(() => _enChargement = true);
      await IconService().changerIcone(nouvelleApparence);
      setState(() => _enChargement = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppTranslations.t('icone_changee')} → ${_apparences.firstWhere((a) => a.id == nouvelleApparence).nom}'),
            backgroundColor: AppColors.primary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _afficherConfirmation(bool iconeChangee) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.shield, color: AppColors.primary, size: 24),
            SizedBox(width: 10),
            Text('Mode activé',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Le mode discrétion est actif.',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            if (iconeChangee)
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.check_circle_outline,
                        color: AppColors.success, size: 16),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Icône externe changée dans le launcher.',
                        style: TextStyle(fontSize: 12, color: AppColors.success),
                      ),
                    ),
                  ],
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF8E1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.warning_amber_outlined,
                        color: AppColors.warning, size: 16),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Façade activée à l\'intérieur. Le changement d\'icône launcher peut nécessiter un redémarrage.',
                        style: TextStyle(fontSize: 12, color: Color(0xFFE65100)),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 10),
            const Text(
              'Votre code PIN sera requis pour retrouver l\'interface réelle.',
              style: TextStyle(fontSize: 13, height: 1.5),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Compris'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppTranslations.t;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      body: Column(
        children: [

          // En-tête animé
          AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            decoration: BoxDecoration(
              color: _camouflageActif
                  ? const Color(0xFF263238)
                  : AppColors.primary,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
                child: Row(
                  children: [
                    Container(
                      width: 48, height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        _camouflageActif
                            ? Icons.shield
                            : Icons.shield_outlined,
                        color: Colors.white, size: 26,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            t('discretion'),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            _camouflageActif
                                ? 'Protection active'
                                : 'Protection désactivée',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Badge ON/OFF
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _camouflageActif
                            ? AppColors.success.withValues(alpha: 0.2)
                            : Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _camouflageActif
                              ? AppColors.success.withValues(alpha: 0.5)
                              : Colors.white.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        _camouflageActif ? 'ON' : 'OFF',
                        style: TextStyle(
                          color: _camouflageActif
                              ? AppColors.success
                              : Colors.white.withValues(alpha: 0.7),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [

                // Toggle principal
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _camouflageActif
                          ? const Color(0xFF263238).withValues(alpha: 0.3)
                          : const Color(0xFFE0E7EF),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44, height: 44,
                        decoration: BoxDecoration(
                          color: _camouflageActif
                              ? const Color(0xFF263238).withValues(alpha: 0.1)
                              : AppColors.primaryPale,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.visibility_off_outlined,
                          color: _camouflageActif
                              ? const Color(0xFF263238)
                              : AppColors.primary,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Activer le camouflage',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              _enChargement
                                  ? 'Changement en cours...'
                                  : 'Change l\'icône dans le launcher',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      _enChargement
                          ? const SizedBox(
                        width: 24, height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: AppColors.primary,
                        ),
                      )
                          : Switch(
                        value: _camouflageActif,
                        onChanged: _toggleCamouflage,
                        activeColor: AppColors.primary,
                        activeTrackColor: AppColors.primaryPale,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Section apparence
                const Text(
                  'Apparence choisie',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'L\'icône du launcher et l\'interface changeront selon ce choix.',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 14),

                // Grille des apparences
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.3,
                  ),
                  itemCount: _apparences.length,
                  itemBuilder: (_, i) {
                    final app = _apparences[i];
                    final estChoisie = _apparenceChoisie == app.id;

                    return GestureDetector(
                      onTap: () => _changerApparenceActive(app.id),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: estChoisie
                              ? app.couleur.withValues(alpha: 0.08)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: estChoisie
                                ? app.couleur
                                : const Color(0xFFE0E7EF),
                            width: estChoisie ? 1.5 : 1,
                          ),
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
                            Row(
                              children: [
                                Icon(
                                  app.icone,
                                  color: estChoisie
                                      ? app.couleur
                                      : AppColors.textSecondary,
                                  size: 24,
                                ),
                                const Spacer(),
                                if (estChoisie)
                                  Container(
                                    width: 18, height: 18,
                                    decoration: BoxDecoration(
                                      color: app.couleur,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.check,
                                      color: Colors.white, size: 11,
                                    ),
                                  ),
                              ],
                            ),
                            const Spacer(),
                            Text(
                              app.nom,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: estChoisie
                                    ? app.couleur
                                    : AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 20),

                // Avertissement
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF8E1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: AppColors.warning.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.warning_amber_outlined,
                          color: AppColors.warning, size: 18),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'Le changement d\'icône peut prendre quelques secondes sur Android. '
                              'Votre code PIN sera requis pour accéder à ConfidantSanté depuis le mode camouflage.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFFE65100),
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Info icônes requises
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.primaryPale,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.info_outline,
                              color: AppColors.primary, size: 16),
                          SizedBox(width: 8),
                          Text(
                            'Icônes requises dans le projet',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Pour que le changement d\'icône fonctionne, ajoute ces fichiers dans android/app/src/main/res/mipmap-xxxhdpi/ :',
                        style: TextStyle(
                            fontSize: 12, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 6),
                      ...['ic_launcher_calculatrice.png',
                        'ic_launcher_meteo.png',
                        'ic_launcher_notes.png',
                        'ic_launcher_minuteur.png']
                          .map((f) => Padding(
                        padding:
                        const EdgeInsets.only(top: 3),
                        child: Row(
                          children: [
                            const Icon(Icons.image_outlined,
                                size: 12,
                                color: AppColors.primary),
                            const SizedBox(width: 6),
                            Text(f,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontFamily: 'monospace',
                                  color: AppColors.textPrimary,
                                )),
                          ],
                        ),
                      )),
                    ],
                  ),
                ),

                const SizedBox(height: 80),

              ],
            ),
          ),

        ],
      ),
    );
  }
}