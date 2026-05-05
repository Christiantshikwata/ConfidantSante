import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../patient/dashboard_patient_screen.dart';
import '../../core/services/session_service.dart';
class MotDePasseScreen extends StatefulWidget {
  const MotDePasseScreen({super.key});

  @override
  State<MotDePasseScreen> createState() => _MotDePasseScreenState();
}

class _MotDePasseScreenState extends State<MotDePasseScreen> {

  final TextEditingController _mdpController     = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();
  final GlobalKey<FormState>  _formKey           = GlobalKey<FormState>();

  bool _mdpVisible     = false; // afficher/masquer le mot de passe
  bool _confirmVisible = false;
  bool _enChargement   = false;

  // Force du mot de passe : 0 faible, 1 moyen, 2 fort
  int _force = 0;

  @override
  void dispose() {
    _mdpController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  // Calcule la force du mot de passe en temps réel
  void _calculerForce(String valeur) {
    int score = 0;
    if (valeur.length >= 6) score++;
    if (valeur.contains(RegExp(r'[A-Z]'))) score++;
    if (valeur.contains(RegExp(r'[0-9]'))) score++;
    if (valeur.contains(RegExp(r'[!@#\$%^&*]'))) score++;
    setState(() => _force = score < 2 ? 0 : score < 4 ? 1 : 2);
  }

  Future<void> _valider() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _enChargement = true);
    await Future.delayed(const Duration(seconds: 1));
    if (!mounted) return;
    setState(() => _enChargement = false);
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const PinScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      body: Column(
        children: [

          // En-tête
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.only(
                bottomLeft:  Radius.circular(28),
                bottomRight: Radius.circular(28),
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 38, height: 38,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.arrow_back_ios_new,
                          color: Colors.white, size: 16,
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    Container(
                      width: 56, height: 56,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.lock_outline,
                        color: Colors.white, size: 28,
                      ),
                    ),

                    const SizedBox(height: 16),

                    const Text(
                      'Créer un mot de passe',
                      style: TextStyle(
                        color: Colors.white, fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    const SizedBox(height: 6),

                    Text(
                      'Ce mot de passe protège votre compte.\n'
                          'Minimum 6 caractères.',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.75),
                        fontSize: 14, height: 1.5,
                      ),
                    ),

                  ],
                ),
              ),
            ),
          ),

          // Formulaire
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    const SizedBox(height: 8),

                    // Champ mot de passe
                    _labelChamp('Mot de passe'),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _mdpController,
                      obscureText: !_mdpVisible,
                      onChanged: _calculerForce,
                      style: const TextStyle(
                        fontSize: 15,
                        color: AppColors.textPrimary,
                      ),
                      decoration: _decorationChamp(
                        hint: '••••••••',
                        suffixIcon: IconButton(
                          icon: Icon(
                            _mdpVisible
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: AppColors.textSecondary,
                            size: 20,
                          ),
                          onPressed: () => setState(
                                () => _mdpVisible = !_mdpVisible,
                          ),
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) {
                          return 'Veuillez entrer un mot de passe';
                        }
                        if (v.length < 6) {
                          return 'Minimum 6 caractères';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 12),

                    // Barre de force du mot de passe
                    _BarreForce(force: _force),

                    const SizedBox(height: 24),

                    // Champ confirmation
                    _labelChamp('Confirmer le mot de passe'),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _confirmController,
                      obscureText: !_confirmVisible,
                      style: const TextStyle(
                        fontSize: 15,
                        color: AppColors.textPrimary,
                      ),
                      decoration: _decorationChamp(
                        hint: '••••••••',
                        suffixIcon: IconButton(
                          icon: Icon(
                            _confirmVisible
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: AppColors.textSecondary,
                            size: 20,
                          ),
                          onPressed: () => setState(
                                () => _confirmVisible = !_confirmVisible,
                          ),
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) {
                          return 'Veuillez confirmer le mot de passe';
                        }
                        if (v != _mdpController.text) {
                          return 'Les mots de passe ne correspondent pas';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 32),

                    // Bouton valider
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _enChargement ? null : _valider,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: _enChargement
                            ? const SizedBox(
                          width: 22, height: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                            : const Text(
                          'Continuer',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),

                  ],
                ),
              ),
            ),
          ),

        ],
      ),
    );
  }

  // Helper : label au-dessus des champs
  Widget _labelChamp(String texte) {
    return Text(
      texte,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        letterSpacing: 0.2,
      ),
    );
  }

  // Helper : style commun des champs
  InputDecoration _decorationChamp({
    required String hint,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(
        color: Color(0xFFB0BEC5), fontSize: 15,
      ),
      filled: true,
      fillColor: Colors.white,
      suffixIcon: suffixIcon,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE0E7EF)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE0E7EF)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: AppColors.primary, width: 1.5,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.danger),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16, vertical: 16,
      ),
    );
  }
}

// Barre visuelle de force du mot de passe
class _BarreForce extends StatelessWidget {
  final int force; // 0 = faible, 1 = moyen, 2 = fort

  const _BarreForce({required this.force});

  @override
  Widget build(BuildContext context) {
    final couleurs = [
      AppColors.danger,
      AppColors.warning,
      AppColors.success,
    ];
    final labels = ['Faible', 'Moyen', 'Fort'];
    final couleur = couleurs[force];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 3 segments de barre
        Row(
          children: List.generate(3, (i) {
            return Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: 5,
                margin: EdgeInsets.only(right: i < 2 ? 4 : 0),
                decoration: BoxDecoration(
                  // Segment allumé si i <= force
                  color: i <= force ? couleur : const Color(0xFFE0E7EF),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 6),
        // Label force
        Text(
          'Sécurité : ${labels[force]}',
          style: TextStyle(
            fontSize: 12,
            color: couleur,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

// ── ÉCRAN PIN ────────────────────────────────────────────────────────────────

class PinScreen extends StatefulWidget {
  const PinScreen({super.key});

  @override
  State<PinScreen> createState() => _PinScreenState();
}

class _PinScreenState extends State<PinScreen> {

  String _pin = '';          // PIN saisi
  String _pinConfirm = '';   // PIN de confirmation
  bool   _enConfirmation = false; // true quand on est à l'étape confirmation
  bool   _erreur = false;

  // Ajoute un chiffre au PIN
  void _ajouterChiffre(String chiffre) {
    if (_enConfirmation) {
      if (_pinConfirm.length >= 4) return;
      setState(() {
        _pinConfirm += chiffre;
        _erreur = false;
      });
      if (_pinConfirm.length == 4) _verifierPin();
    } else {
      if (_pin.length >= 4) return;
      setState(() => _pin += chiffre);
      if (_pin.length == 4) {
        // Passe à la confirmation après 300ms
        Future.delayed(const Duration(milliseconds: 300), () {
          if (!mounted) return;
          setState(() => _enConfirmation = true);
        });
      }
    }
  }

  // Supprime le dernier chiffre
  void _supprimer() {
    setState(() {
      if (_enConfirmation) {
        if (_pinConfirm.isNotEmpty) {
          _pinConfirm = _pinConfirm.substring(0, _pinConfirm.length - 1);
        }
      } else {
        if (_pin.isNotEmpty) {
          _pin = _pin.substring(0, _pin.length - 1);
        }
      }
      _erreur = false;
    });
  }

  // Vérifie que les deux PIN correspondent
  void _verifierPin() {
    if (_pin == _pinConfirm) {
      // Sauvegarde le PIN dans le stockage sécurisé
      SessionService().sauvegarderPin(_pin).then((_) {
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const DashboardPatientScreen(),
          ),
        );
      });
    } else {
      setState(() {
        _erreur = true;
        _pinConfirm = '';
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    final pinActuel = _enConfirmation ? _pinConfirm : _pin;

    return Scaffold(
      backgroundColor: AppColors.primary,
      body: SafeArea(
        child: Column(
          children: [

            // En-tête
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      if (_enConfirmation) {
                        setState(() {
                          _enConfirmation = false;
                          _pinConfirm = '';
                          _erreur = false;
                        });
                      } else {
                        Navigator.pop(context);
                      }
                    },
                    child: Container(
                      width: 38, height: 38,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios_new,
                        color: Colors.white, size: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const Spacer(),

            // Icône cadenas
            Container(
              width: 64, height: 64,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(
                Icons.pin_outlined,
                color: Colors.white, size: 32,
              ),
            ),

            const SizedBox(height: 20),

            // Titre
            Text(
              _enConfirmation
                  ? 'Confirmez votre PIN'
                  : 'Créez votre PIN',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              _enConfirmation
                  ? 'Entrez à nouveau vos 4 chiffres'
                  : 'Ce code déverrouille l\'app sans internet',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 14,
              ),
            ),

            const SizedBox(height: 8),

            // Message erreur
            AnimatedOpacity(
              opacity: _erreur ? 1 : 0,
              duration: const Duration(milliseconds: 200),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 40),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Les codes ne correspondent pas. Réessayez.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Points PIN
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (i) {
                final rempli = i < pinActuel.length;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  margin: const EdgeInsets.symmetric(horizontal: 10),
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: rempli
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.3),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.5),
                      width: 1.5,
                    ),
                  ),
                );
              }),
            ),

            const Spacer(),

            // Clavier numérique
            Padding(
              padding: const EdgeInsets.fromLTRB(40, 0, 40, 40),
              child: Column(
                children: [
                  _rangeeClavier(['1', '2', '3']),
                  const SizedBox(height: 16),
                  _rangeeClavier(['4', '5', '6']),
                  const SizedBox(height: 16),
                  _rangeeClavier(['7', '8', '9']),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Case vide à gauche
                      const SizedBox(width: 70),
                      // 0
                      _ToucheClavier(
                        label: '0',
                        onTap: () => _ajouterChiffre('0'),
                      ),
                      // Supprimer
                      SizedBox(
                        width: 70, height: 70,
                        child: GestureDetector(
                          onTap: _supprimer,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: const Icon(
                              Icons.backspace_outlined,
                              color: Colors.white, size: 22,
                            ),
                          ),
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
    );
  }

  Widget _rangeeClavier(List<String> chiffres) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: chiffres.map((c) => _ToucheClavier(
        label: c,
        onTap: () => _ajouterChiffre(c),
      )).toList(),
    );
  }
}

// Touche individuelle du clavier PIN
class _ToucheClavier extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _ToucheClavier({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 70,
        height: 70,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.1),
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

