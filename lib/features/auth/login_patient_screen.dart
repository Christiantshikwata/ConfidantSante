import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/app_colors.dart';
import 'mot_de_passe_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LoginPatientScreen extends StatefulWidget {
  const LoginPatientScreen({super.key});

  @override
  State<LoginPatientScreen> createState() => _LoginPatientScreenState();
}

class _LoginPatientScreenState extends State<LoginPatientScreen> {

  // Contrôleur du champ de saisie du numéro
  final TextEditingController _numeroController = TextEditingController();

  // Clé du formulaire — permet de valider les champs
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // true quand on attend la réponse du serveur
  bool _enChargement = false;

  @override
  void dispose() {
    _numeroController.dispose();
    super.dispose();
  }

  // Validation et envoi du numéro
  Future<void> _envoyerCode() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _enChargement = true);

    final numero = '+243${_numeroController.text.trim()}';

    // Firebase envoie le vrai SMS
    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: numero,

      // SMS envoyé — on navigue vers l'écran OTP
      codeSent: (String verificationId, int? resendToken) {
        setState(() => _enChargement = false);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OtpScreen(
              numero: numero,
              verificationId: verificationId,
            ),
          ),
        );
      },

      // Vérification automatique (Android seulement)
      verificationCompleted: (PhoneAuthCredential credential) async {
        await FirebaseAuth.instance.signInWithCredential(credential);
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const MotDePasseScreen(),
          ),
        );
      },

      // Erreur
      verificationFailed: (FirebaseAuthException e) {
        setState(() => _enChargement = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Erreur : ${e.message ?? "Vérifiez votre numéro"}',
            ),
            backgroundColor: AppColors.danger,
            behavior: SnackBarBehavior.floating,
          ),
        );
      },

      // Timeout — 60 secondes
      timeout: const Duration(seconds: 60),
      codeAutoRetrievalTimeout: (String verificationId) {},
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      body: Column(
        children: [

          // En-tête bleu
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(28),
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

                    // Bouton retour
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.arrow_back_ios_new,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Icône
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.phone_outlined,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),

                    const SizedBox(height: 16),

                    const Text(
                      'Connexion Patient',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.2,
                      ),
                    ),

                    const SizedBox(height: 6),

                    Text(
                      'Entrez votre numéro pour recevoir\nun code de vérification par SMS.',
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

                    const Text(
                      'Numéro de téléphone',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                        letterSpacing: 0.2,
                      ),
                    ),

                    const SizedBox(height: 10),

                    // Champ de saisie avec indicatif +243
                    TextFormField(
                      controller: _numeroController,
                      keyboardType: TextInputType.phone,
                      // Limite à 9 chiffres (format congolais)
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
                        // Préfixe +243
                        prefixIcon: Container(
                          margin: const EdgeInsets.fromLTRB(14, 8, 0, 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
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
                          letterSpacing: 1,
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
                          horizontal: 16,
                          vertical: 16,
                        ),
                      ),
                      // Validation du numéro
                      validator: (valeur) {
                        if (valeur == null || valeur.isEmpty) {
                          return 'Veuillez entrer votre numéro';
                        }
                        if (valeur.length < 9) {
                          return 'Le numéro doit contenir 9 chiffres';
                        }
                        return null; // null = valide
                      },
                    ),

                    const SizedBox(height: 12),

                    // Info sur le SMS
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 14,
                          color: AppColors.textSecondary.withValues(
                            alpha: 0.7,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Un code à 6 chiffres sera envoyé par SMS',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary.withValues(
                              alpha: 0.7,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),

                    // Bouton envoyer
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _enChargement ? null : _envoyerCode,
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
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                            : const Text(
                          'Recevoir le code SMS',
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
}

// ── ÉCRAN OTP ────────────────────────────────────────────────────────────────

class OtpScreen extends StatefulWidget {
  final String numero;
  final String verificationId; // ← nouveau paramètre

  const OtpScreen({
    super.key,
    required this.numero,
    required this.verificationId,
  });

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {

  // 6 contrôleurs — un par chiffre du code OTP
  final List<TextEditingController> _controllers =
  List.generate(6, (_) => TextEditingController());

  // 6 focusNodes — pour passer automatiquement au chiffre suivant
  final List<FocusNode> _focusNodes =
  List.generate(6, (_) => FocusNode());

  bool _enChargement = false;
  bool _codeInvalide = false;

  // Compteur pour renvoyer le code
  int _secondesRestantes = 60;
  bool _peutRenvoyer = false;

  @override
  void initState() {
    super.initState();
    _demarrerCompteur();
  }

  @override
  void dispose() {
    for (var c in _controllers) c.dispose();
    for (var f in _focusNodes) f.dispose();
    super.dispose();
  }

  // Compteur de 60 secondes avant de pouvoir renvoyer
  Future<void> _demarrerCompteur() async {
    for (int i = 60; i >= 0; i--) {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return;
      setState(() {
        _secondesRestantes = i;
        if (i == 0) _peutRenvoyer = true;
      });
    }
  }

  // Récupère le code complet depuis les 6 champs
  String get _codeComplet =>
      _controllers.map((c) => c.text).join();

  // Vérifie le code OTP
  Future<void> _verifierCode() async {
    if (_codeComplet.length < 6) return;

    setState(() {
      _enChargement = true;
      _codeInvalide = false;
    });

    try {
      // Crée les credentials avec le code saisi
      final credential = PhoneAuthProvider.credential(
        verificationId: widget.verificationId,
        smsCode: _codeComplet,
      );

      // Connecte l'utilisateur avec Firebase
      await FirebaseAuth.instance.signInWithCredential(credential);

      if (!mounted) return;
      setState(() => _enChargement = false);

      // Code correct — on continue
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const MotDePasseScreen(),
        ),
      );

    } on FirebaseAuthException catch (e) {
      setState(() {
        _enChargement = false;
        _codeInvalide = true;
      });
      for (var c in _controllers) c.clear();
      _focusNodes[0].requestFocus();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.code == 'invalid-verification-code'
                ? 'Code incorrect. Vérifiez votre SMS.'
                : 'Erreur : ${e.message}',
          ),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
        ),
      );
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
                bottomLeft: Radius.circular(28),
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
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.arrow_back_ios_new,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.sms_outlined,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),

                    const SizedBox(height: 16),

                    const Text(
                      'Vérification SMS',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    const SizedBox(height: 6),

                    Text(
                      'Code envoyé au ${widget.numero}',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.75),
                        fontSize: 14,
                      ),
                    ),

                  ],
                ),
              ),
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [

                  const SizedBox(height: 16),

                  // Message d'erreur
                  if (_codeInvalide)
                    Container(
                      margin: const EdgeInsets.only(bottom: 20),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFEBEE),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.danger.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.error_outline,
                            color: AppColors.danger,
                            size: 18,
                          ),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Text(
                              'Code incorrect. Vérifiez votre SMS et réessayez.',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.danger,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  const Text(
                    'Entrez le code à 6 chiffres',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Les 6 cases OTP
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(6, (index) {
                      return SizedBox(
                        width: 46,
                        height: 56,
                        child: TextFormField(
                          controller: _controllers[index],
                          focusNode: _focusNodes[index],
                          textAlign: TextAlign.center,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(1),
                          ],
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Color(0xFFE0E7EF),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: _codeInvalide
                                    ? AppColors.danger
                                    : const Color(0xFFE0E7EF),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: AppColors.primary,
                                width: 1.5,
                              ),
                            ),
                            contentPadding: EdgeInsets.zero,
                          ),
                          onChanged: (valeur) {
                            if (valeur.isNotEmpty) {
                              // Passe au champ suivant automatiquement
                              if (index < 5) {
                                _focusNodes[index + 1].requestFocus();
                              } else {
                                // Dernier champ — on vérifie
                                _focusNodes[index].unfocus();
                                _verifierCode();
                              }
                            } else {
                              // Si on efface — revient au champ précédent
                              if (index > 0) {
                                _focusNodes[index - 1].requestFocus();
                              }
                            }
                          },
                        ),
                      );
                    }),
                  ),

                  const SizedBox(height: 28),

                  // Renvoyer le code
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Vous n\'avez pas reçu le code ? ',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary.withValues(
                            alpha: 0.8,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: _peutRenvoyer
                            ? () {
                          setState(() {
                            _peutRenvoyer = false;
                            _secondesRestantes = 60;
                          });
                          _demarrerCompteur();
                        }
                            : null,
                        child: Text(
                          _peutRenvoyer
                              ? 'Renvoyer'
                              : 'Renvoyer (${_secondesRestantes}s)',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: _peutRenvoyer
                                ? AppColors.primary
                                : AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // Bouton vérifier
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _enChargement ? null : _verifierCode,
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
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                          : const Text(
                        'Vérifier le code',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Note test
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primaryPale,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.bug_report_outlined,
                          size: 14,
                          color: AppColors.primary,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Mode test : utilisez le code 123456',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),

                ],
              ),
            ),
          ),

        ],
      ),
    );
  }
}
