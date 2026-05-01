import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

// Les apparences disponibles pour le mode camouflage
class _Apparence {
  final String id;
  final IconData icone;
  final String nom;
  final String description;

  const _Apparence({
    required this.id,
    required this.icone,
    required this.nom,
    required this.description,
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

  // Animation pour la transition quand on active le camouflage
  late AnimationController _animController;
  late Animation<double> _animation;

  final List<_Apparence> _apparences = const [
    _Apparence(
      id: 'calculatrice',
      icone: Icons.calculate_outlined,
      nom: 'Calculatrice',
      description: 'L\'app ressemble à une calculatrice standard',
    ),
    _Apparence(
      id: 'meteo',
      icone: Icons.wb_sunny_outlined,
      nom: 'Météo',
      description: 'L\'app ressemble à une app météo',
    ),
    _Apparence(
      id: 'notes',
      icone: Icons.note_outlined,
      nom: 'Notes',
      description: 'L\'app ressemble à un bloc-notes',
    ),
    _Apparence(
      id: 'minuteur',
      icone: Icons.timer_outlined,
      nom: 'Minuteur',
      description: 'L\'app ressemble à un minuteur',
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
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  // Active ou désactive le mode camouflage
  void _toggleCamouflage(bool valeur) {
    setState(() => _camouflageActif = valeur);
    if (valeur) {
      _animController.forward();
      // Simule l'activation du mode camouflage
      Future.delayed(const Duration(milliseconds: 600), () {
        if (!mounted) return;
        _afficherConfirmation();
      });
    } else {
      _animController.reverse();
    }
  }

  // Message de confirmation quand le camouflage s'active
  void _afficherConfirmation() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Row(
          children: [
            Icon(Icons.shield, color: AppColors.primary, size: 24),
            SizedBox(width: 10),
            Text(
              'Mode activé',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        content: const Text(
          'Le mode discrétion est actif. L\'application '
              'se masquera automatiquement quand quelqu\'un '
              'prendra votre téléphone.\n\n'
              'Votre code PIN sera requis pour y revenir.',
          style: TextStyle(fontSize: 14, height: 1.5),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Compris'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      body: Column(
        children: [

          // En-tête — change de couleur selon l'état
          AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            decoration: BoxDecoration(
              color: _camouflageActif
                  ? const Color(0xFF263238)  // gris foncé si actif
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    // Icône et titre
                    Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(
                            _camouflageActif
                                ? Icons.shield
                                : Icons.shield_outlined,
                            color: Colors.white,
                            size: 26,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Mode discrétion',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 3),
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
                        // Badge statut
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6,
                          ),
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

                  ],
                ),
              ),
            ),
          ),

          // Contenu
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
                        width: 44,
                        height: 44,
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
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Activer le camouflage',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            SizedBox(height: 3),
                            Text(
                              'Masque l\'app en public',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch(
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
                  'L\'app prendra cette apparence quand '
                      'quelqu\'un prend votre téléphone.',
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
                    childAspectRatio: 1.4,
                  ),
                  itemCount: _apparences.length,
                  itemBuilder: (context, index) {
                    final app = _apparences[index];
                    final estChoisie = _apparenceChoisie == app.id;

                    return GestureDetector(
                      onTap: () {
                        setState(() => _apparenceChoisie = app.id);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: estChoisie
                              ? AppColors.primaryPale
                              : Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: estChoisie
                                ? AppColors.primary
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
                                      ? AppColors.primary
                                      : AppColors.textSecondary,
                                  size: 24,
                                ),
                                const Spacer(),
                                if (estChoisie)
                                  Container(
                                    width: 18,
                                    height: 18,
                                    decoration: const BoxDecoration(
                                      color: AppColors.primary,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.check,
                                      color: Colors.white,
                                      size: 11,
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
                                    ? AppColors.primary
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
                      color: AppColors.warning.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.warning_amber_outlined,
                        color: AppColors.warning,
                        size: 18,
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'Votre code PIN sera requis pour '
                              'revenir à ConfidantSanté depuis '
                              'le mode camouflage.',
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

                // Infos sur la protection
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFFE0E7EF),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Comment ça fonctionne',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 14),
                      _etapeInfo(
                        numero: '1',
                        texte: 'Activez le mode discrétion '
                            'depuis cet écran.',
                      ),
                      _etapeInfo(
                        numero: '2',
                        texte: 'Choisissez l\'apparence '
                            'qui remplacera l\'app.',
                      ),
                      _etapeInfo(
                        numero: '3',
                        texte: 'L\'app se masque '
                            'automatiquement en public.',
                      ),
                      _etapeInfo(
                        numero: '4',
                        texte: 'Utilisez votre PIN pour '
                            'retrouver l\'interface réelle.',
                        dernier: true,
                      ),
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

  Widget _etapeInfo({
    required String numero,
    required String texte,
    bool dernier = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: const BoxDecoration(
                color: AppColors.primaryPale,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  numero,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
            if (!dernier)
              Container(
                width: 1,
                height: 28,
                color: const Color(0xFFE0E7EF),
              ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 16),
            child: Text(
              texte,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
          ),
        ),
      ],
    );
  }
}