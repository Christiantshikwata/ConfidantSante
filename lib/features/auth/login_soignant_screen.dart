

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/app_colors.dart';
import '../../core/l10n/app_translations.dart';
import '../../core/services/database_service.dart';
import '../../core/services/session_service.dart';
import '../../core/services/sync_service.dart';
import '../../core/services/auth_service.dart';
import '../soignant/dashboard_soignant_screen.dart';

class LoginSoignantScreen extends StatefulWidget {
  const LoginSoignantScreen({super.key});

  @override
  State<LoginSoignantScreen> createState() => _LoginSoignantScreenState();
}

class _LoginSoignantScreenState extends State<LoginSoignantScreen> {

  final TextEditingController _matriculeController = TextEditingController();
  final TextEditingController _mdpController       = TextEditingController();
  final GlobalKey<FormState>  _formKey             = GlobalKey<FormState>();

  bool _mdpVisible    = false;
  bool _enChargement  = false;
  String? _erreur;

  @override
  void dispose() {
    _matriculeController.dispose();
    _mdpController.dispose();
    super.dispose();
  }

  Future<void> _seConnecter() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _enChargement = true;
      _erreur = null;
    });

    try {
      final matricule = _matriculeController.text.trim();

      // Authentification Firebase Auth (email-alias dérivé du matricule).
      final res = await AuthService().connecterSoignant(
        matricule:  matricule,
        motDePasse: _mdpController.text,
      );
      if (!mounted) return;
      if (!res.succes) {
        setState(() {
          _erreur = AppTranslations.t(res.messageCle ?? 'auth_err_generique');
        });
        return;
      }

      // Assure la présence de la fiche locale du soignant (1re connexion sur
      // cet appareil : médecin créé par l'admin, ou amorçage de l'admin démo).
      var soignant = await DatabaseService().getSoignantParMatricule(matricule);
      if (soignant == null) {
        final distant = await SyncService().recupererCompteSoignant(matricule);
        if (distant != null) {
          await DatabaseService().creerSoignantAvecHash(
            nom:            distant['nom'] as String? ?? '',
            matricule:      matricule,
            hashMotDePasse: '',
            specialite:     distant['specialite'] as String?,
          );
        } else if (matricule == AuthService.adminMatricule) {
          await DatabaseService().creerSoignantAvecHash(
            nom:            AuthService.adminNomDemo,
            matricule:      matricule,
            hashMotDePasse: '',
            specialite:     'Médecin infectiologue',
          );
        }
        soignant = await DatabaseService().getSoignantParMatricule(matricule);
      }

      if (!mounted) return;

      if (soignant != null) {
        // Sauvegarde la session soignant
        await SessionService().sauvegarderSessionSoignant(
          soignantId: soignant['id'].toString(),
          nom:        soignant['nom'] as String,
          matricule:  soignant['matricule'] as String,
        );

        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const DashboardSoignantScreen(),
          ),
        );
      } else {
        setState(() {
          _erreur = AppTranslations.t('erreur_login');
        });
      }
    } catch (e) {
      setState(() {
        _erreur = AppTranslations.t('erreur_login');
      });
    } finally {
      if (mounted) setState(() => _enChargement = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppTranslations.t;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      body: Column(
        children: [

          // ── En-tête ──────────────────────────────────────────────────
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF01579B),
                  Color(0xFF0277BD),
                  Color(0xFF0288D1),
                ],
              ),
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

                    // Bouton retour
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

                    // Icône soignant
                    Container(
                      width: 56, height: 56,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.medical_services_outlined,
                        color: Colors.white, size: 28,
                      ),
                    ),

                    const SizedBox(height: 16),

                    const Text(
                      'Accès soignant',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    const SizedBox(height: 6),

                    Text(
                      'Centre Hospitalier Congo-Chine\nLubumbashi, RDC',
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

          // ── Formulaire ────────────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    const SizedBox(height: 8),

                    // Matricule
                    _LabelChamp('Matricule hospitalier'),
                    const SizedBox(height: 8),

                    TextFormField(
                      controller: _matriculeController,
                      textCapitalization: TextCapitalization.characters,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                            RegExp(r'[A-Za-z0-9\-]')),
                        LengthLimitingTextInputFormatter(12),
                      ],
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                        letterSpacing: 1,
                      ),
                      decoration: _decoChamp(
                        hint: 'Ex. : MED-2024-001',
                        icone: Icons.badge_outlined,
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Veuillez entrer votre matricule';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    // Mot de passe
                    _LabelChamp(t('mot_de_passe')),
                    const SizedBox(height: 8),

                    TextFormField(
                      controller: _mdpController,
                      obscureText: !_mdpVisible,
                      style: const TextStyle(
                        fontSize: 15,
                        color: AppColors.textPrimary,
                      ),
                      decoration: _decoChamp(
                        hint: 'Votre mot de passe',
                        icone: Icons.lock_outline,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _mdpVisible
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: AppColors.textSecondary,
                            size: 20,
                          ),
                          onPressed: () =>
                              setState(() => _mdpVisible = !_mdpVisible),
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) {
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
                            const Icon(Icons.error_outline,
                                color: AppColors.danger, size: 16),
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

                    const SizedBox(height: 32),

                    // Bouton connexion
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _enChargement ? null : _seConnecter,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0288D1),
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
                          'Se connecter',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Info compte de démonstration
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE3F2FD),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFF0288D1).withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.info_outline,
                              color: Color(0xFF0288D1), size: 18),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Compte de démonstration',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF01579B),
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Matricule : MED-2024-001\nMot de passe : soignant123',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF0277BD),
                                    height: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
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

  Widget _LabelChamp(String texte) => Text(
    texte,
    style: const TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w600,
      color: AppColors.textPrimary,
      letterSpacing: 0.2,
    ),
  );

  InputDecoration _decoChamp({
    required String hint,
    required IconData icone,
    Widget? suffixIcon,
  }) =>
      InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(
          color: Color(0xFFB0BEC5), fontSize: 14,
        ),
        prefixIcon: Icon(icone, color: const Color(0xFF0288D1), size: 20),
        suffixIcon: suffixIcon,
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
              color: Color(0xFF0288D1), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.danger),
        ),
        contentPadding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 16),
      );
}