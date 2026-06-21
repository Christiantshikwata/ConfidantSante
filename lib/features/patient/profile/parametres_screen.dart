

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '/../core/constants/app_colors.dart';
import '/../core/l10n/app_translations.dart';
import '/../core/providers/langue_provider.dart';
import '/../core/services/database_service.dart';
import '/../core/services/session_service.dart';
import '/../core/services/sync_service.dart';
import '../../auth/mot_de_passe_screen.dart'; // PinScreen

class ParametresScreen extends StatefulWidget {
  const ParametresScreen({super.key});

  @override
  State<ParametresScreen> createState() => _ParametresScreenState();
}

class _ParametresScreenState extends State<ParametresScreen> {
  bool _notifsActives = true;
  int? _patientId;
  String _numero = '';
  String _medecinActuel = '—';

  @override
  void initState() {
    super.initState();
    _chargerMedecin();
  }

  Future<void> _chargerMedecin() async {
    final idStr = await SessionService().getPatientId();
    final numero = await SessionService().getNumero();
    if (numero == null) return;
    final patient = await DatabaseService().getPatient(numero);
    if (!mounted) return;
    setState(() {
      _patientId = int.tryParse(idStr ?? '');
      _numero = numero;
      final nom = patient?['soignant'] as String?;
      _medecinActuel = (nom != null && nom.isNotEmpty)
          ? nom
          : (patient?['soignant_matricule'] as String? ?? '—');
    });
  }

  Future<void> _changerMedecin() async {
    final ctrl = TextEditingController();
    String? erreur;
    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Changer de médecin'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Entrez le matricule de votre nouveau médecin référent.',
                style: TextStyle(
                    fontSize: 13, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: ctrl,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(
                  hintText: 'Ex. : MED-2024-002',
                  border: OutlineInputBorder(),
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
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () async {
                final matricule = ctrl.text.trim();
                if (matricule.isEmpty || _patientId == null) {
                  setDlg(() => erreur = 'Matricule requis.');
                  return;
                }
                final soignant = await DatabaseService()
                    .getSoignantParMatricule(matricule);
                final nomSoignant = soignant?['nom'] as String?;
                await DatabaseService().changerSoignantPatient(
                  patientId: _patientId!,
                  matricule: matricule,
                  nomSoignant: nomSoignant,
                );
                await SyncService().mettreAJourSoignantPatient(
                  numero: _numero,
                  matricule: matricule,
                  nomSoignant: nomSoignant,
                );
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('Valider'),
            ),
          ],
        ),
      ),
    );
    if (mounted) _chargerMedecin();
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LangueProvider>();
    final t = AppTranslations.t;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      body: Column(
        children: [

          // ── En-tête ──────────────────────────────────────────────────
          Container(
            decoration: const BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.only(
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
                    const SizedBox(width: 14),
                    Text(
                      t('parametres_titre'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Contenu ──────────────────────────────────────────────────
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [

                // ── SECTION LANGUE ──────────────────────────────────
                _SectionLabel(t('changer_langue')),
                const SizedBox(height: 10),

                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      _LigneLangue(
                        code: 'fr',
                        label: t('francais'),
                        flag: '🇫🇷',
                        native: 'Français',
                        selectionne: lang.code == 'fr',
                        onTap: () => lang.changerLangue('fr'),
                        dernier: false,
                      ),
                      _LigneLangue(
                        code: 'en',
                        label: t('anglais'),
                        flag: '🇬🇧',
                        native: 'English',
                        selectionne: lang.code == 'en',
                        onTap: () => lang.changerLangue('en'),
                        dernier: false,
                      ),
                      _LigneLangue(
                        code: 'sw',
                        label: t('swahili'),
                        flag: '🇨🇩',
                        native: 'Kiswahili',
                        selectionne: lang.code == 'sw',
                        onTap: () => lang.changerLangue('sw'),
                        dernier: true,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // ── SECTION SÉCURITÉ ────────────────────────────────
                _SectionLabel(t('securite')),
                const SizedBox(height: 10),

                _CarteParametres(
                  children: [
                    _LigneAction(
                      icon: Icons.pin_outlined,
                      label: t('changer_pin'),
                      sousTitre: t('changer_pin_desc'),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const PinScreen(),
                          ),
                        );
                      },
                      dernier: true,
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // ── SECTION MON MÉDECIN ─────────────────────────────
                _SectionLabel('Mon médecin'),
                const SizedBox(height: 10),

                _CarteParametres(
                  children: [
                    _LigneAction(
                      icon: Icons.medical_services_outlined,
                      label: 'Changer de médecin',
                      sousTitre: 'Médecin actuel : $_medecinActuel',
                      onTap: _changerMedecin,
                      dernier: true,
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // ── SECTION NOTIFICATIONS ───────────────────────────
                _SectionLabel(t('notifs_rappels')),
                const SizedBox(height: 10),

                _CarteParametres(
                  children: [
                    _LigneSwitch(
                      icon: Icons.notifications_active_outlined,
                      label: t('notifs_rappels'),
                      sousTitre: t('notifs_rappels_desc'),
                      valeur: _notifsActives,
                      onChange: (v) => setState(() => _notifsActives = v),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // ── SECTION À PROPOS ────────────────────────────────
                _SectionLabel(t('a_propos')),
                const SizedBox(height: 10),

                _CarteParametres(
                  children: [
                    _LigneInfo(
                      icon: Icons.local_hospital_outlined,
                      label: t('centre_hospitalier'),
                      valeur: 'Lubumbashi, RDC',
                      dernier: false,
                    ),
                    _LigneInfo(
                      icon: Icons.school_outlined,
                      label: t('udbl'),
                      valeur: '',
                      dernier: false,
                    ),
                    _LigneInfo(
                      icon: Icons.info_outline,
                      label: t('version'),
                      valeur: '1.0.0',
                      dernier: true,
                    ),
                  ],
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

// ─────────────────────────────────────────────────────────────────────────────
//  WIDGETS UTILITAIRES
// ─────────────────────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(left: 4, bottom: 2),
    child: Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: AppColors.textSecondary,
        letterSpacing: 0.5,
      ),
    ),
  );
}

class _CarteParametres extends StatelessWidget {
  final List<Widget> children;
  const _CarteParametres({required this.children});

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.05),
          blurRadius: 10,
          offset: const Offset(0, 3),
        ),
      ],
    ),
    child: Column(children: children),
  );
}

// Ligne de sélection de langue
class _LigneLangue extends StatelessWidget {
  final String code, label, flag, native;
  final bool selectionne, dernier;
  final VoidCallback onTap;

  const _LigneLangue({
    required this.code,
    required this.label,
    required this.flag,
    required this.native,
    required this.selectionne,
    required this.onTap,
    required this.dernier,
  });

  @override
  Widget build(BuildContext context) => Column(
    children: [
      InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: selectionne
                      ? AppColors.primaryPale
                      : const Color(0xFFEEF2F7),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(flag,
                      style: const TextStyle(fontSize: 22)),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: selectionne
                            ? AppColors.primary
                            : AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      native,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selectionne
                      ? AppColors.primary
                      : Colors.transparent,
                  border: Border.all(
                    color: selectionne
                        ? AppColors.primary
                        : const Color(0xFFCFD8DC),
                    width: 1.5,
                  ),
                ),
                child: selectionne
                    ? const Icon(Icons.check,
                    color: Colors.white, size: 13)
                    : null,
              ),
            ],
          ),
        ),
      ),
      if (!dernier)
        const Divider(
          height: 1, thickness: 0.5,
          indent: 74, color: Color(0xFFF0F4F8),
        ),
    ],
  );
}

// Ligne avec action (flèche)
class _LigneAction extends StatelessWidget {
  final IconData icon;
  final String label, sousTitre;
  final VoidCallback onTap;
  final bool dernier;

  const _LigneAction({
    required this.icon,
    required this.label,
    required this.sousTitre,
    required this.onTap,
    required this.dernier,
  });

  @override
  Widget build(BuildContext context) => Column(
    children: [
      InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primaryPale,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        )),
                    Text(sousTitre,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        )),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right,
                  color: AppColors.textSecondary, size: 20),
            ],
          ),
        ),
      ),
      if (!dernier)
        const Divider(
          height: 1, thickness: 0.5,
          indent: 70, color: Color(0xFFF0F4F8),
        ),
    ],
  );
}

// Ligne avec switch
class _LigneSwitch extends StatelessWidget {
  final IconData icon;
  final String label, sousTitre;
  final bool valeur;
  final ValueChanged<bool> onChange;

  const _LigneSwitch({
    required this.icon,
    required this.label,
    required this.sousTitre,
    required this.valeur,
    required this.onChange,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    child: Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.primaryPale,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.primary, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  )),
              Text(sousTitre,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  )),
            ],
          ),
        ),
        Switch(
          value: valeur,
          onChanged: onChange,
          activeColor: AppColors.primary,
          activeTrackColor: AppColors.primaryPale,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ],
    ),
  );
}

// Ligne info simple
class _LigneInfo extends StatelessWidget {
  final IconData icon;
  final String label, valeur;
  final bool dernier;

  const _LigneInfo({
    required this.icon,
    required this.label,
    required this.valeur,
    required this.dernier,
  });

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFEEF2F7),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon,
                  color: AppColors.textSecondary, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(label,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textPrimary,
                  )),
            ),
            if (valeur.isNotEmpty)
              Text(valeur,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  )),
          ],
        ),
      ),
      if (!dernier)
        const Divider(
          height: 1, thickness: 0.5,
          indent: 70, color: Color(0xFFF0F4F8),
        ),
    ],
  );
}