import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/database_service.dart';
import '../../core/services/session_service.dart';
import 'mot_de_passe_screen.dart';
import 'package:confidantsante/features/patient/dashboard_patient_screen.dart';
class LoginPatientScreen extends StatefulWidget {
  const LoginPatientScreen({super.key});

  @override
  State<LoginPatientScreen> createState() => _LoginPatientScreenState();
}

class _LoginPatientScreenState extends State<LoginPatientScreen> {

  final TextEditingController _numeroController  = TextEditingController();
  final TextEditingController _nomController     = TextEditingController();
  final TextEditingController _mdpController     = TextEditingController();
  final GlobalKey<FormState>  _formKey           = GlobalKey<FormState>();

  bool _enChargement   = false;
  bool _mdpVisible     = false;
  bool _premiereVisite = true;
  String? _erreur;

  @override
  void dispose() {
    _numeroController.dispose();
    _nomController.dispose();
    _mdpController.dispose();
    super.dispose();
  }

  // ── INSCRIPTION ───────────────────────────────────────────────────────────
  Future<void> _inscrire() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _enChargement = true;
      _erreur = null;
    });

    final numero = _numeroController.text.trim();

    // Vérifie si le numéro existe déjà
    final existe = await DatabaseService().patientExiste(numero);
    if (!mounted) return;

    if (existe) {
      setState(() {
        _enChargement = false;
        _erreur = 'Ce numéro est déjà enregistré. Connectez-vous.';
      });
      return;
    }

    // Crée le patient dans SQLite
    final id = await DatabaseService().creerPatient(
      nom: _nomController.text.trim(),
      numero: numero,
      motDePasse: _mdpController.text,
    );

    if (!mounted) return;

    if (id > 0) {
      // Sauvegarde la session
      await SessionService().sauvegarderSession(
        patientId: id.toString(),
        nom: _nomController.text.trim(),
        numero: numero,
      );

      setState(() => _enChargement = false);

      // Va créer le PIN
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const PinScreen(),
        ),
      );
    } else {
      setState(() {
        _enChargement = false;
        _erreur = 'Erreur lors de la création du compte.';
      });
    }
  }

  // ── CONNEXION ─────────────────────────────────────────────────────────────
  Future<void> _connecter() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _enChargement = true;
      _erreur = null;
    });

    final patient = await DatabaseService().connecterPatient(
      numero: _numeroController.text.trim(),
      motDePasse: _mdpController.text,
    );

    if (!mounted) return;

    if (patient != null) {
      // Sauvegarde la session
      await SessionService().sauvegarderSession(
        patientId: patient['id'].toString(),
        nom: patient['nom'],
        numero: patient['numero'],
      );

      setState(() => _enChargement = false);

      // Vérifie si le PIN est déjà configuré
      final pinOk = await SessionService().pinConfigue();

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => pinOk
              ? const PinVerificationScreen()
              : const PinScreen(),
        ),
      );
    } else {
      setState(() {
        _enChargement = false;
        _erreur = 'Numéro ou mot de passe incorrect.';
      });
    }
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
                        Icons.health_and_safety_outlined,
                        color: Colors.white, size: 28,
                      ),
                    ),

                    const SizedBox(height: 16),

                    Text(
                      _premiereVisite
                          ? 'Créer un compte'
                          : 'Connexion Patient',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    const SizedBox(height: 6),

                    Text(
                      _premiereVisite
                          ? 'Créez votre compte pour commencer\n'
                          'à suivre votre traitement.'
                          : 'Connectez-vous pour accéder\n'
                          'à votre espace personnel.',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.75),
                        fontSize: 14,
                        height: 1.5,
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

                    // Toggle inscription / connexion
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.primaryPale,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          _toggleBtn(
                            'Nouveau compte',
                            _premiereVisite,
                                () => setState(() {
                              _premiereVisite = true;
                              _erreur = null;
                            }),
                          ),
                          _toggleBtn(
                            'Se connecter',
                            !_premiereVisite,
                                () => setState(() {
                              _premiereVisite = false;
                              _erreur = null;
                            }),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Champ nom (inscription seulement)
                    if (_premiereVisite) ...[
                      _labelChamp('Votre nom complet'),
                      const SizedBox(height: 8),
                      _champTexte(
                        controller: _nomController,
                        hint: 'Ex : Christian Ngoy',
                        icone: Icons.person_outline,
                        validator: (v) {
                          if (_premiereVisite &&
                              (v == null || v.isEmpty)) {
                            return 'Veuillez entrer votre nom';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Champ numéro
                    _labelChamp('Numéro de téléphone'),
                    const SizedBox(height: 8),

                    TextFormField(
                      controller: _numeroController,
                      keyboardType: TextInputType.phone,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(9),
                      ],
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                        letterSpacing: 1,
                      ),
                      decoration: InputDecoration(
                        prefixIcon: Container(
                          margin: const EdgeInsets.fromLTRB(14, 8, 0, 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primaryPale,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            '+243',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        hintText: '8X XXX XXXX',
                        hintStyle: const TextStyle(
                          color: Color(0xFFB0BEC5),
                          fontSize: 15,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                            color: Color(0xFFE0E7EF),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                            color: Color(0xFFE0E7EF),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                            color: AppColors.primary,
                            width: 1.5,
                          ),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                            color: AppColors.danger,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 16,
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) {
                          return 'Veuillez entrer votre numéro';
                        }
                        if (v.length < 9) {
                          return 'Le numéro doit contenir 9 chiffres';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    // Champ mot de passe
                    _labelChamp(
                      _premiereVisite
                          ? 'Créez un mot de passe'
                          : 'Mot de passe',
                    ),
                    const SizedBox(height: 8),

                    TextFormField(
                      controller: _mdpController,
                      obscureText: !_mdpVisible,
                      style: const TextStyle(
                        fontSize: 15,
                        color: AppColors.textPrimary,
                      ),
                      decoration: InputDecoration(
                        hintText: _premiereVisite
                            ? 'Minimum 6 caractères'
                            : 'Votre mot de passe',
                        hintStyle: const TextStyle(
                          color: Color(0xFFB0BEC5),
                          fontSize: 14,
                        ),
                        prefixIcon: const Icon(
                          Icons.lock_outline,
                          color: AppColors.primary,
                          size: 20,
                        ),
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
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                            color: Color(0xFFE0E7EF),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                            color: Color(0xFFE0E7EF),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                            color: AppColors.primary,
                            width: 1.5,
                          ),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                            color: AppColors.danger,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 16,
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

                    // Message d'erreur
                    if (_erreur != null) ...[
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFEBEE),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: AppColors.danger.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.error_outline,
                              color: AppColors.danger,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _erreur!,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.danger,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 28),

                    // Bouton principal
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _enChargement
                            ? null
                            : (_premiereVisite ? _inscrire : _connecter),
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
                            : Text(
                          _premiereVisite
                              ? 'Créer mon compte'
                              : 'Se connecter',
                          style: const TextStyle(
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

  Widget _champTexte({
    required TextEditingController controller,
    required String hint,
    required IconData icone,
    required String? Function(String?) validator,
  }) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(
        fontSize: 14,
        color: AppColors.textPrimary,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(
          color: Color(0xFFB0BEC5),
          fontSize: 14,
        ),
        prefixIcon: Icon(icone, color: AppColors.primary, size: 20),
        filled: true,
        fillColor: Colors.white,
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
      ),
      validator: validator,
    );
  }

  Widget _toggleBtn(
      String label,
      bool actif,
      VoidCallback onTap,
      ) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.all(4),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: actif ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: actif ? Colors.white : AppColors.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── ÉCRAN VÉRIFICATION PIN ───────────────────────────────────────────────────

class PinVerificationScreen extends StatefulWidget {
  const PinVerificationScreen({super.key});

  @override
  State<PinVerificationScreen> createState() =>
      _PinVerificationScreenState();
}

class _PinVerificationScreenState
    extends State<PinVerificationScreen> {

  String _pin = '';
  bool _erreur = false;
  int _tentatives = 0;

  void _ajouterChiffre(String c) {
    if (_pin.length >= 4) return;
    setState(() {
      _pin += c;
      _erreur = false;
    });
    if (_pin.length == 4) _verifierPin();
  }

  void _supprimer() {
    if (_pin.isEmpty) return;
    setState(() {
      _pin = _pin.substring(0, _pin.length - 1);
      _erreur = false;
    });
  }

  Future<void> _verifierPin() async {
    final ok = await SessionService().verifierPin(_pin);
    if (!mounted) return;

    if (ok) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const DashboardPatientScreen(),
        ),
      );
    } else {
      setState(() {
        _erreur = true;
        _tentatives++;
        _pin = '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return _buildEcranPin(
      titre: 'Entrez votre PIN',
      sousTitre: 'Votre code à 4 chiffres',
      pin: _pin,
      erreur: _erreur,
      messageErreur: _tentatives >= 3
          ? 'Trop de tentatives. Reconnectez-vous.'
          : 'PIN incorrect. Réessayez.',
    );
  }

  Widget _buildEcranPin({
    required String titre,
    required String sousTitre,
    required String pin,
    required bool erreur,
    required String messageErreur,
  }) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: SafeArea(
        child: Column(
          children: [

            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: GestureDetector(
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
              ),
            ),

            const Spacer(),

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

            Text(
              titre,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              sousTitre,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 14,
              ),
            ),

            const SizedBox(height: 8),

            AnimatedOpacity(
              opacity: erreur ? 1 : 0,
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
                child: Text(
                  messageErreur,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 32),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (i) {
                final rempli = i < pin.length;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  margin: const EdgeInsets.symmetric(horizontal: 10),
                  width: 16, height: 16,
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

            Padding(
              padding: const EdgeInsets.fromLTRB(40, 0, 40, 40),
              child: Column(
                children: [
                  _rangee(['1', '2', '3']),
                  const SizedBox(height: 16),
                  _rangee(['4', '5', '6']),
                  const SizedBox(height: 16),
                  _rangee(['7', '8', '9']),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const SizedBox(width: 70),
                      _touche('0'),
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

  Widget _rangee(List<String> chiffres) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: chiffres.map((c) => _touche(c)).toList(),
    );
  }

  Widget _touche(String label) {
    return GestureDetector(
      onTap: () => _ajouterChiffre(label),
      child: Container(
        width: 70, height: 70,
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

// Import nécessaire
