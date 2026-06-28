import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/l10n/app_translations.dart';
import '../../core/providers/langue_provider.dart';
import '../../core/services/database_service.dart';
import '../../core/services/session_service.dart';
import '../../core/services/sync_service.dart';
import '../../core/services/auth_service.dart';
import 'mot_de_passe_screen.dart';
import '../../core/services/biometric_service.dart';
import 'package:confidantsante/features/patient/dashboard_patient_screen.dart';
class LoginPatientScreen extends StatefulWidget {
  const LoginPatientScreen({super.key});

  @override
  State<LoginPatientScreen> createState() => _LoginPatientScreenState();
}

class _LoginPatientScreenState extends State<LoginPatientScreen> {

  final TextEditingController _numeroController  = TextEditingController();
  final TextEditingController _mdpController     = TextEditingController();
  final GlobalKey<FormState>  _formKey           = GlobalKey<FormState>();

  bool _enChargement   = false;
  bool _mdpVisible     = false;
  String? _erreur;

  @override
  void dispose() {
    _numeroController.dispose();
    _mdpController.dispose();
    super.dispose();
  }

  // ── CONNEXION ─────────────────────────────────────────────────────────────
  Future<void> _connecter() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _enChargement = true;
      _erreur = null;
    });

    final numero = _numeroController.text.trim();

    // Authentification Firebase Auth (email-alias dérivé du numéro).
    final res = await AuthService().connecterPatient(
      numero: numero,
      motDePasse: _mdpController.text,
    );
    if (!mounted) return;
    if (!res.succes) {
      setState(() {
        _enChargement = false;
        _erreur = AppTranslations.t(res.messageCle ?? 'auth_err_generique');
      });
      return;
    }

    // Assure la présence de la fiche locale (1re connexion sur cet appareil :
    // compte créé par le médecin, ou réinstallation de l'app).
    var patient = await DatabaseService().getPatient(numero);
    if (patient == null) {
      final distant = await SyncService().recupererComptePatient(numero);
      if (distant != null) {
        await DatabaseService().upsertPatientDepuisFirestore(
          numero:            numero,
          nom:               distant['nom'] as String? ?? '',
          soignant:          distant['soignant'] as String?,
          soignantMatricule: distant['soignant_matricule'] as String?,
          hopital:           distant['hopital'] as String?,
        );
      } else {
        // Compte Auth sans profil Firestore : fiche locale minimale.
        await DatabaseService().creerPatient(
          nom: numero,
          numero: numero,
          motDePasse: _mdpController.text,
        );
      }
      patient = await DatabaseService().getPatient(numero);
    }

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
        _erreur = AppTranslations.t('erreur_login');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    context.watch<LangueProvider>();
    final t = AppTranslations.t;
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
                      t('connexion_patient'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    const SizedBox(height: 6),

                    Text(
                      t('sous_titre_connexion'),
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

                    // Champ numéro
                    _labelChamp(t('numero_telephone')),
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
                          return t('erreur_numero');
                        }
                        if (v.length < 9) {
                          return t('erreur_numero_court');
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    // Champ mot de passe
                    _labelChamp(
                      t('mot_de_passe'),
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
                        hintText: t('hint_mdp'),
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
                          return t('erreur_mdp_vide');
                        }
                        if (v.length < 6) {
                          return t('erreur_mdp');
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
                            : _connecter,
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
                          t('se_connecter'),
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

}

// ── ÉCRAN VÉRIFICATION PIN ───────────────────────────────────────────────────



class PinVerificationScreen extends StatefulWidget {
  const PinVerificationScreen({super.key});

  @override
  State<PinVerificationScreen> createState() =>
      _PinVerificationScreenState();
}

class _PinVerificationScreenState extends State<PinVerificationScreen> {

  String _pin = '';
  bool _erreur = false;
  int _tentatives = 0;
  bool _biometrieDisponible = false;
  String _typeBiometrie = 'none';

  @override
  void initState() {
    super.initState();
    _verifierBiometrie();
  }

  Future<void> _verifierBiometrie() async {
    final dispo = await BiometricService().isDisponible();
    final type = await BiometricService().getTypeBiometrie();
    if (mounted) {
      setState(() {
        _biometrieDisponible = dispo;
        _typeBiometrie = type;
      });
      // Propose automatiquement la biométrie au premier affichage
      if (dispo) {
        Future.delayed(const Duration(milliseconds: 500), _authentifierBiometrie);
      }
    }
  }

  Future<void> _authentifierBiometrie() async {
    final raison = _typeBiometrie == 'face'
        ? AppTranslations.t('face_id_raison')
        : AppTranslations.t('empreinte_raison');

    final ok = await BiometricService().authentifier(raison: raison);
    if (!mounted) return;

    if (ok) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const DashboardPatientScreen()),
      );
    }
    // Si échec, l'utilisateur peut utiliser le PIN
  }

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

  static const int _maxTentatives = 5;

  Future<void> _verifierPin() async {
    final ok = await SessionService().verifierPin(_pin);
    if (!mounted) return;

    if (ok) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const DashboardPatientScreen()),
      );
    } else {
      setState(() {
        _erreur = true;
        _tentatives++;
        _pin = '';
      });

      // Verrouillage : trop de tentatives → déconnexion forcée.
      if (_tentatives >= _maxTentatives) {
        await AuthService().deconnecter();
        await SessionService().deconnecter();
        if (!mounted) return;
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/role',
          (route) => false,
        );
      }
    }
  }

  // PIN oublié : le patient saisit le mot de passe de son compte pour
  // définir un nouveau PIN.
  Future<void> _reinitialiserPin() async {
    final ctrl = TextEditingController();
    String? erreur;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) => AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
          title: Text(AppTranslations.t('reinit_pin_titre')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppTranslations.t('reinit_pin_desc'),
                style: const TextStyle(
                    fontSize: 13, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: ctrl,
                obscureText: true,
                decoration: InputDecoration(
                  hintText: AppTranslations.t('mot_de_passe'),
                  border: const OutlineInputBorder(),
                ),
              ),
              if (erreur != null) ...[
                const SizedBox(height: 8),
                Text(erreur!,
                    style: const TextStyle(
                        color: AppColors.danger, fontSize: 12)),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(AppTranslations.t('annuler')),
            ),
            ElevatedButton(
              onPressed: () async {
                final numero = await SessionService().getNumero();
                if (numero == null) {
                  if (ctx.mounted) Navigator.pop(ctx);
                  return;
                }
                final ok = await AuthService().verifierMotDePassePatient(
                  numero: numero,
                  motDePasse: ctrl.text,
                );
                if (ok) {
                  if (ctx.mounted) Navigator.pop(ctx);
                  if (mounted) {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const PinScreen()),
                    );
                  }
                } else {
                  setDlg(() => erreur = AppTranslations.t('mdp_incorrect'));
                }
              },
              child: Text(AppTranslations.t('valider')),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    context.watch<LangueProvider>();
    final t = AppTranslations.t;
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
                    child: const Icon(Icons.arrow_back_ios_new,
                        color: Colors.white, size: 16),
                  ),
                ),
              ),
            ),

            const Spacer(),

            // Icône
            Container(
              width: 64, height: 64,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(Icons.pin_outlined,
                  color: Colors.white, size: 32),
            ),

            const SizedBox(height: 20),

            Text(
              t('entrer_pin'),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              t('pin_sous_titre'),
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
                    horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _tentatives >= _maxTentatives - 1
                      ? t('pin_trop_tentatives')
                      : t('pin_incorrect'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Points PIN
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (i) {
                final rempli = i < _pin.length;
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

            // Clavier numérique
            Padding(
              padding: const EdgeInsets.fromLTRB(40, 0, 40, 16),
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

                      // Bouton biométrie (si disponible) ou espace vide
                      SizedBox(
                        width: 70, height: 70,
                        child: _biometrieDisponible
                            ? GestureDetector(
                          onTap: _authentifierBiometrie,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Icon(
                              _typeBiometrie == 'face'
                                  ? Icons.face_outlined
                                  : Icons.fingerprint_rounded,
                              color: Colors.white, size: 28,
                            ),
                          ),
                        )
                            : const SizedBox(),
                      ),

                      _touche('0'),

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
                            child: const Icon(Icons.backspace_outlined,
                                color: Colors.white, size: 22),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Lien "Code oublié"
            TextButton(
              onPressed: _reinitialiserPin,
              child: Text(
                t('code_oublie'),
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 13,
                ),
              ),
            ),

            const SizedBox(height: 16),

          ],
        ),
      ),
    );
  }

  Widget _rangee(List<String> chiffres) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: chiffres.map(_touche).toList(),
  );

  Widget _touche(String label) => GestureDetector(
    onTap: () => _ajouterChiffre(label),
    child: Container(
      width: 70, height: 70,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
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

// Import nécessaire
