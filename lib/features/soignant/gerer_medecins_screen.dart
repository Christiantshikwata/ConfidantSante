// lib/features/soignant/gerer_medecins_screen.dart
// ConfidantSanté — Gestion des médecins (réservé à l'administrateur)

import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/l10n/app_translations.dart';
import '../../core/services/database_service.dart';
import '../../core/services/sync_service.dart';
import '../../core/services/auth_service.dart';

class GererMedecinsScreen extends StatefulWidget {
  const GererMedecinsScreen({super.key});

  @override
  State<GererMedecinsScreen> createState() => _GererMedecinsScreenState();
}

class _GererMedecinsScreenState extends State<GererMedecinsScreen> {
  List<Map<String, dynamic>> _soignants = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    setState(() => _isLoading = true);
    final list = await DatabaseService().getTousSoignants();
    if (mounted) {
      setState(() {
        _soignants = list;
        _isLoading = false;
      });
    }
  }

  Future<void> _ajouterMedecin() async {
    final nomCtrl = TextEditingController();
    final matriculeCtrl = TextEditingController();
    final specialiteCtrl = TextEditingController();
    final mdpCtrl = TextEditingController();
    String? erreur;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setModal) => Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
            left: 24, right: 24, top: 8,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40, height: 4,
                    margin: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE0E7EF),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const Text('Ajouter un médecin',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary)),
                const SizedBox(height: 20),

                _label('Nom complet'),
                const SizedBox(height: 6),
                TextField(controller: nomCtrl, decoration: _deco('Ex. : Dr. Jean Kabila')),
                const SizedBox(height: 14),

                _label('Matricule'),
                const SizedBox(height: 6),
                TextField(
                  controller: matriculeCtrl,
                  textCapitalization: TextCapitalization.characters,
                  decoration: _deco('Ex. : MED-2024-002'),
                ),
                const SizedBox(height: 14),

                _label('Spécialité'),
                const SizedBox(height: 6),
                TextField(controller: specialiteCtrl, decoration: _deco('Ex. : Médecin infectiologue')),
                const SizedBox(height: 14),

                _label('Mot de passe initial'),
                const SizedBox(height: 6),
                TextField(
                  controller: mdpCtrl,
                  obscureText: true,
                  decoration: _deco('Minimum 6 caractères'),
                ),

                if (erreur != null) ...[
                  const SizedBox(height: 12),
                  Text(erreur!,
                      style: const TextStyle(
                          color: AppColors.danger, fontSize: 13)),
                ],

                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () async {
                      final nom = nomCtrl.text.trim();
                      final matricule = matriculeCtrl.text.trim();
                      final mdp = mdpCtrl.text;
                      if (nom.isEmpty || matricule.isEmpty || mdp.length < 6) {
                        setModal(() => erreur =
                            'Nom, matricule et mot de passe (6+) requis.');
                        return;
                      }
                      if (await DatabaseService().matriculeExiste(matricule)) {
                        setModal(() => erreur = 'Ce matricule existe déjà.');
                        return;
                      }
                      final spec = specialiteCtrl.text.trim().isEmpty
                          ? 'Médecin'
                          : specialiteCtrl.text.trim();
                      // Crée le compte Firebase Auth du médecin via une app
                      // secondaire (l'admin reste connecté). Le médecin pourra
                      // se connecter sur son propre téléphone.
                      final res =
                          await AuthService().creerUtilisateurSecondaire(
                        email: AuthService.emailSoignant(matricule),
                        motDePasse: mdp,
                        role: 'soignant',
                        matricule: matricule,
                      );
                      if (!res.succes) {
                        setModal(() => erreur = AppTranslations.t(
                            res.messageCle ?? 'auth_err_generique'));
                        return;
                      }
                      await DatabaseService().creerSoignant(
                        nom: nom,
                        matricule: matricule,
                        motDePasse: mdp,
                        specialite: spec,
                      );
                      // Pousse le profil vers Firestore (sans mot de passe).
                      await SyncService().pousserCompteSoignant(
                        matricule: matricule,
                        nom: nom,
                        uid: res.uid,
                        specialite: spec,
                      );
                      if (ctx.mounted) Navigator.pop(ctx);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0288D1),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text('Créer le médecin',
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );

    if (mounted) _charger();
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
              color: Color(0xFF0288D1),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 38, height: 38,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.arrow_back_ios_new,
                            color: Colors.white, size: 16),
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Text('Gérer les médecins',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ),
          ),

          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF0288D1)))
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
                    itemCount: _soignants.length,
                    itemBuilder: (_, i) {
                      final s = _soignants[i];
                      final matricule = s['matricule'] as String? ?? '';
                      final estAdmin =
                          DatabaseService().estAdmin(matricule);
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFE0E7EF)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 46, height: 46,
                              decoration: BoxDecoration(
                                color: const Color(0xFFE3F2FD),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.medical_services_outlined,
                                  color: Color(0xFF0288D1), size: 22),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(s['nom'] as String? ?? '',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textPrimary,
                                      )),
                                  const SizedBox(height: 2),
                                  Text(
                                    '$matricule • ${s['specialite'] ?? ''}',
                                    style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textSecondary),
                                  ),
                                ],
                              ),
                            ),
                            if (estAdmin)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0288D1)
                                      .withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text('Admin',
                                    style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF0288D1))),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _ajouterMedecin,
        backgroundColor: const Color(0xFF0288D1),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _label(String t) => Text(t,
      style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary));

  InputDecoration _deco(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFFB0BEC5), fontSize: 14),
        filled: true,
        fillColor: const Color(0xFFF8FAFF),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE0E7EF)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE0E7EF)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF0288D1), width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      );
}
