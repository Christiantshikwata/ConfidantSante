// lib/features/soignant/ajouter_patient_screen.dart
// ConfidantSanté — Ajouter un patient (côté soignant)
// Auteur : Christian Ngoy Tshikwata — UDBL Lubumbashi

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/app_colors.dart';
import '../../core/l10n/app_translations.dart';
import '../../core/services/database_service.dart';
import '../../core/services/sync_service.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/session_service.dart';

class AjouterPatientScreen extends StatefulWidget {
  const AjouterPatientScreen({super.key});

  @override
  State<AjouterPatientScreen> createState() => _AjouterPatientScreenState();
}

class _AjouterPatientScreenState extends State<AjouterPatientScreen> {

  final _formKey    = GlobalKey<FormState>();
  final _nomCtrl    = TextEditingController();
  final _numeroCtrl = TextEditingController();
  final _mdpCtrl    = TextEditingController();

  bool _mdpVisible   = false;
  bool _enChargement = false;
  String? _erreur;
  String? _succes;

  final List<String> _protocoles = [
    'Lamivudine + Efavirenz + Ténofovir',
    'Lamivudine + Névirapine',
    'Efavirenz + Ténofovir',
    'Lamivudine + Efavirenz',
    'Dolutégravir + Ténofovir + Lamivudine',
    'Autre',
  ];
  String _protocoleChoisi = 'Lamivudine + Efavirenz + Ténofovir';
  int _dureeMois = 1;

  @override
  void dispose() {
    _nomCtrl.dispose();
    _numeroCtrl.dispose();
    _mdpCtrl.dispose();
    super.dispose();
  }

  Future<void> _enregistrer() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _enChargement = true; _erreur = null; _succes = null; });

    try {
      final existe = await DatabaseService().numeroExiste(_numeroCtrl.text.trim());
      if (existe) {
        setState(() => _erreur = 'Ce numéro est déjà enregistré dans le système.');
        return;
      }

      final nom    = _nomCtrl.text.trim();
      final numero = _numeroCtrl.text.trim();
      final pwd    = _mdpCtrl.text;

      // Rattache le patient au médecin connecté.
      final matricule = await SessionService().getSoignantMatricule();
      final nomSoignant = await SessionService().getSoignantNom();

      // Crée le compte Firebase Auth du patient via une app secondaire :
      // le médecin reste connecté. Le patient se connectera ensuite sur son
      // propre téléphone avec son numéro + ce mot de passe initial.
      final res = await AuthService().creerUtilisateurSecondaire(
        email:      AuthService.emailPatient(numero),
        motDePasse: pwd,
        role:       'patient',
        numero:     numero,
      );
      if (!res.succes) {
        setState(() => _erreur =
            AppTranslations.t(res.messageCle ?? 'auth_err_generique'));
        return;
      }

      final id = await DatabaseService().creerPatientParSoignant(
        nom:               nom,
        numero:            numero,
        motDePasse:        pwd,
        soignant:          nomSoignant ?? 'Dr. Yves Ndetereyuwe',
        soignantMatricule: matricule,
        hopital:           'Centre Hospitalier Congo-Chine',
      );

      if (id > 0) {
        // Pousse le profil patient vers Firestore (sans mot de passe).
        await SyncService().pousserComptePatient(
          numero:            numero,
          nom:               nom,
          uid:               res.uid,
          soignant:          nomSoignant ?? 'Dr. Yves Ndetereyuwe',
          soignantMatricule: matricule,
          hopital:           'Centre Hospitalier Congo-Chine',
        );

        // Attribue le protocole : l'heure sera choisie par le patient.
        final tid = await DatabaseService().assignerProtocole(
          patientId:         id,
          nomMedicament:     _protocoleChoisi,
          dosage:            '1 comprimé/jour',
          dureeMois:         _dureeMois,
          soignantMatricule: matricule,
        );
        final row = await DatabaseService().getTraitementParId(tid);
        if (row != null) {
          await SyncService().pousserProtocole(
            numero:            numero,
            idLocal:           tid.toString(),
            nomMedicament:     row['nom_medicament'] as String? ?? '',
            dosage:            row['dosage'] as String? ?? '',
            dateDebut:         row['date_debut'] as String?,
            dateFin:           row['date_fin'] as String?,
            dureeMois:         row['duree_mois'] as int?,
            soignantMatricule: matricule,
          );
        }

        setState(() => _succes = 'Patient $nom créé avec succès !');
        _formKey.currentState!.reset();
        _nomCtrl.clear(); _numeroCtrl.clear(); _mdpCtrl.clear();
        setState(() {
          _protocoleChoisi = _protocoles.first;
          _dureeMois = 1;
        });
      } else {
        setState(() => _erreur = 'Erreur lors de la création du patient.');
      }
    } catch (e) {
      setState(() => _erreur = 'Une erreur est survenue. Réessayez.');
    } finally {
      if (mounted) setState(() => _enChargement = false);
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
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF01579B), Color(0xFF0277BD), Color(0xFF0288D1)],
              ),
              borderRadius: BorderRadius.only(
                bottomLeft:  Radius.circular(28),
                bottomRight: Radius.circular(28),
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
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
                        child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 16),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      width: 56, height: 56,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(Icons.person_add_outlined, color: Colors.white, size: 28),
                    ),
                    const SizedBox(height: 16),
                    const Text('Ajouter un patient',
                        style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 6),
                    Text('Enregistrer un nouveau patient PVVIH\nau suivi thérapeutique.',
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 14, height: 1.5)),
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

                    if (_succes != null) ...[
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.success.withValues(alpha: 0.4)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle_outline, color: AppColors.success, size: 20),
                            const SizedBox(width: 10),
                            Expanded(child: Text(_succes!,
                                style: const TextStyle(fontSize: 13, color: AppColors.success, fontWeight: FontWeight.w500))),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Nom
                    _LabelChamp('Nom complet du patient'),
                    const SizedBox(height: 8),
                    _ChampTexte(
                      controller: _nomCtrl,
                      hint: 'Ex. : Christian Ngoy Tshikwata',
                      icone: Icons.person_outline,
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Veuillez entrer le nom du patient' : null,
                    ),

                    const SizedBox(height: 16),

                    // Numéro
                    _LabelChamp('Numéro de téléphone'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _numeroCtrl,
                      keyboardType: TextInputType.phone,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(9),
                      ],
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500,
                          color: AppColors.textPrimary, letterSpacing: 1),
                      decoration: InputDecoration(
                        prefixIcon: Container(
                          margin: const EdgeInsets.fromLTRB(14, 8, 0, 8),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE3F2FD),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text('+243',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF0288D1))),
                        ),
                        hintText: '8X XXX XXXX',
                        hintStyle: const TextStyle(color: Color(0xFFB0BEC5), fontSize: 15),
                        filled: true, fillColor: Colors.white,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: Color(0xFFE0E7EF))),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: Color(0xFFE0E7EF))),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: Color(0xFF0288D1), width: 1.5)),
                        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: AppColors.danger)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Veuillez entrer le numéro';
                        if (v.length < 9) return 'Le numéro doit avoir 9 chiffres';
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    // Mot de passe
                    _LabelChamp('Mot de passe initial'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _mdpCtrl,
                      obscureText: !_mdpVisible,
                      style: const TextStyle(fontSize: 15, color: AppColors.textPrimary),
                      decoration: InputDecoration(
                        hintText: 'Minimum 6 caractères',
                        hintStyle: const TextStyle(color: Color(0xFFB0BEC5), fontSize: 14),
                        prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF0288D1), size: 20),
                        suffixIcon: IconButton(
                          icon: Icon(_mdpVisible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                              color: AppColors.textSecondary, size: 20),
                          onPressed: () => setState(() => _mdpVisible = !_mdpVisible),
                        ),
                        filled: true, fillColor: Colors.white,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: Color(0xFFE0E7EF))),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: Color(0xFFE0E7EF))),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: Color(0xFF0288D1), width: 1.5)),
                        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: AppColors.danger)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Veuillez définir un mot de passe';
                        if (v.length < 6) return 'Minimum 6 caractères';
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    // Protocole ARV — BoxDecoration correct
                    _LabelChamp('Protocole ARV'),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE0E7EF)),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _protocoleChoisi,
                          isExpanded: true,
                          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF0288D1)),
                          style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
                          items: _protocoles.map((p) => DropdownMenuItem(
                            value: p,
                            child: Text(p, overflow: TextOverflow.ellipsis),
                          )).toList(),
                          onChanged: (v) { if (v != null) setState(() => _protocoleChoisi = v); },
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Durée du protocole
                    _LabelChamp('Durée du protocole'),
                    const SizedBox(height: 8),
                    Row(
                      children: [1, 3, 6].map((m) {
                        final actif = _dureeMois == m;
                        return Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _dureeMois = m),
                            child: Container(
                              margin: const EdgeInsets.only(right: 8),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: actif
                                    ? const Color(0xFF0288D1)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: actif
                                      ? const Color(0xFF0288D1)
                                      : const Color(0xFFE0E7EF),
                                ),
                              ),
                              child: Center(
                                child: Text('$m mois',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: actif
                                          ? Colors.white
                                          : AppColors.textSecondary,
                                    )),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                    if (_erreur != null) ...[
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFEBEE),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline, color: AppColors.danger, size: 16),
                            const SizedBox(width: 8),
                            Expanded(child: Text(_erreur!,
                                style: const TextStyle(fontSize: 13, color: AppColors.danger))),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 32),

                    SizedBox(
                      width: double.infinity, height: 52,
                      child: ElevatedButton(
                        onPressed: _enChargement ? null : _enregistrer,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0288D1),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: _enChargement
                            ? const SizedBox(width: 22, height: 22,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                            : const Text('Enregistrer le patient',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                      ),
                    ),

                    const SizedBox(height: 40),
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

class _LabelChamp extends StatelessWidget {
  final String texte;
  const _LabelChamp(this.texte);
  @override
  Widget build(BuildContext context) => Text(texte,
      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
          color: AppColors.textPrimary, letterSpacing: 0.2));
}

class _ChampTexte extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icone;
  final String? Function(String?) validator;
  const _ChampTexte({required this.controller, required this.hint,
    required this.icone, required this.validator});

  @override
  Widget build(BuildContext context) => TextFormField(
    controller: controller,
    style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
    decoration: InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFFB0BEC5), fontSize: 14),
      prefixIcon: Icon(icone, color: const Color(0xFF0288D1), size: 20),
      filled: true, fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE0E7EF))),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE0E7EF))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF0288D1), width: 1.5)),
      errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.danger)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    ),
    validator: validator,
  );
}