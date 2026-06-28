import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/l10n/app_translations.dart';
import '../../core/providers/patient_provider.dart';
import '../../core/providers/langue_provider.dart';
import '../../core/services/database_service.dart';
import '../../core/services/notification_service.dart';
import '../../core/services/sync_service.dart';

class RappelsScreen extends StatefulWidget {
  const RappelsScreen({super.key});

  @override
  State<RappelsScreen> createState() => _RappelsScreenState();
}

class _RappelsScreenState extends State<RappelsScreen>
    with SingleTickerProviderStateMixin {

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    context.watch<LangueProvider>();
    final t = AppTranslations.t;

    return Consumer<PatientProvider>(
      builder: (context, patient, _) {

        final rappels = patient.rappels;

        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFF),
          body: Column(
            children: [

              // En-tête
              Container(
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.only(
                    bottomLeft:  Radius.circular(24),
                    bottomRight: Radius.circular(24),
                  ),
                ),
                child: SafeArea(
                  bottom: false,
                  child: Column(
                    children: [

                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            t('rappels'),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Stats rapides
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          children: [
                            _StatRapide(
                              valeur: '${rappels.length}',
                              label: t('medicaments'),
                              couleur: Colors.white,
                            ),
                            const SizedBox(width: 8),
                            _StatRapide(
                              valeur: '${patient.prisAujourdhui.length}',
                              label: t('prises_aujourdhui'),
                              couleur: Colors.white.withValues(alpha: 0.75),
                            ),
                            const SizedBox(width: 8),
                            _StatRapide(
                              valeur: '${patient.observance.toInt()}%',
                              label: t('observance_court'),
                              couleur: Colors.white.withValues(alpha: 0.5),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Onglets
                      TabBar(
                        controller: _tabController,
                        indicatorColor: Colors.white,
                        indicatorWeight: 3,
                        labelColor: Colors.white,
                        unselectedLabelColor:
                        Colors.white.withValues(alpha: 0.5),
                        labelStyle: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                        tabs: [
                          Tab(text: t('onglet_aujourdhui')),
                          Tab(text: t('onglet_semaine')),
                          Tab(text: t('onglet_historique')),
                        ],
                      ),

                    ],
                  ),
                ),
              ),

              // Contenu des onglets
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _OngletAujourdhui(
                      rappels: rappels,
                      protocoles: patient.protocolesAConfigurer,
                    ),
                    const _OngletSemaine(),
                    _OngletHistorique(historique: patient.historique),
                  ],
                ),
              ),

            ],
          ),
        );
      },
    );
  }
}

// ── STAT RAPIDE ──────────────────────────────────────────────────────────────

class _StatRapide extends StatelessWidget {
  final String valeur;
  final String label;
  final Color  couleur;

  const _StatRapide({
    required this.valeur,
    required this.label,
    required this.couleur,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(
              valeur,
              style: TextStyle(
                color: couleur,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: couleur.withValues(alpha: 0.8),
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── ONGLET AUJOURD'HUI ───────────────────────────────────────────────────────

class _OngletAujourdhui extends StatelessWidget {
  final List<Map<String, dynamic>> rappels;
  final List<Map<String, dynamic>> protocoles;

  const _OngletAujourdhui({
    required this.rappels,
    required this.protocoles,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppTranslations.t;
    if (rappels.isEmpty && protocoles.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.medication_outlined,
              size: 64,
              color: AppColors.primary.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              t('aucun_traitement'),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                t('aucun_traitement_desc'),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Groupe par heure
    final Map<String, List<Map<String, dynamic>>> parHeure = {};
    for (final r in rappels) {
      final h = r['heure'] as String? ?? '00h00';
      parHeure.putIfAbsent(h, () => []).add(r);
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () => context.read<PatientProvider>().chargerDonnees(),
      child: ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(20),
      children: [

        // Protocoles attribués par le médecin, en attente d'une heure
        if (protocoles.isNotEmpty) ...[
          Row(
            children: [
              const Icon(Icons.assignment_outlined,
                  size: 16, color: AppColors.primary),
              const SizedBox(width: 6),
              Text(
                '${t('a_configurer')} (${protocoles.length})',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...protocoles.map((p) => _CarteProtocole(protocole: p)),
          const SizedBox(height: 20),
        ],

        // Badge offline — affiché uniquement hors connexion (état réseau réel)
        ValueListenableBuilder<bool>(
          valueListenable: SyncService().enLigne,
          builder: (_, enLigne, __) {
            if (enLigne) return const SizedBox.shrink();
            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 10,
              ),
              decoration: BoxDecoration(
                color: AppColors.primaryPale,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.cloud_off_outlined,
                    size: 14, color: AppColors.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      t('mode_hors_ligne'),
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),

        // Rappels groupés par heure
        ...parHeure.entries.map((entry) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // En-tête heure
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.schedule,
                          size: 12,
                          color: AppColors.warning,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          entry.key,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.warning,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Container(
                      height: 0.5,
                      color: const Color(0xFFE0E7EF),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // Cartes médicaments
              ...entry.value.map((rappel) =>
                  _CarteRappel(rappel: rappel),
              ),

              const SizedBox(height: 16),

            ],
          );
        }),

      ],
      ),
    );
  }
}

// ── CARTE PROTOCOLE (à configurer par le patient) ───────────────────────────

class _CarteProtocole extends StatelessWidget {
  final Map<String, dynamic> protocole;

  const _CarteProtocole({required this.protocole});

  Future<void> _definirHeure(BuildContext context) async {
    final heureChoisie = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 8, minute: 0),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (heureChoisie == null) return;

    final heure =
        '${heureChoisie.hour.toString().padLeft(2, '0')}h${heureChoisie.minute.toString().padLeft(2, '0')}';

    if (!context.mounted) return;
    await context
        .read<PatientProvider>()
        .definirHeureProtocole(protocole, heure);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${AppTranslations.t('rappel_programme')} • $heure • ${protocole['nom_medicament']}',
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final mois = protocole['duree_mois'];
    final dureeTexte = mois != null ? '$mois mois' : '';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: AppColors.primaryPale,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.assignment_turned_in_outlined,
                color: AppColors.primary, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  protocole['nom_medicament'] as String? ?? '',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${protocole['dosage'] ?? ''}${dureeTexte.isNotEmpty ? ' • $dureeTexte' : ''}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => _definirHeure(context),
            style: TextButton.styleFrom(foregroundColor: AppColors.primary),
            child: Text(
              AppTranslations.t('definir_heure'),
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

// ── CARTE RAPPEL ─────────────────────────────────────────────────────────────

class _CarteRappel extends StatelessWidget {
  final Map<String, dynamic> rappel;

  const _CarteRappel({required this.rappel});

  @override
  Widget build(BuildContext context) {
    // L'état « pris » vient du provider (persistant), pas d'un état local.
    final pris = context.select<PatientProvider, bool>(
      (p) => p.estPrisAujourdhui(rappel['id'] as int? ?? -1),
    );

    return Dismissible(
      key: Key(rappel['id'].toString()),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: AppColors.danger,
          borderRadius: BorderRadius.circular(14),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(
          Icons.delete_outline,
          color: Colors.white, size: 24,
        ),
      ),
      onDismissed: (_) async {
        // Supprime le rappel de SQLite
        await DatabaseService().supprimerRappel(
          rappel['id'] as int,
        );
        if (context.mounted) {
          context.read<PatientProvider>().chargerDonnees();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${rappel['nom_medicament']} ${AppTranslations.t('supprime')}',
              ),
              backgroundColor: AppColors.danger,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              margin: const EdgeInsets.all(16),
            ),
          );
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: pris
                ? AppColors.success.withValues(alpha: 0.3)
                : const Color(0xFFE0E7EF),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [

            Container(
              width: 46, height: 46,
              decoration: BoxDecoration(
                color: pris
                    ? AppColors.success.withValues(alpha: 0.1)
                    : AppColors.primaryPale,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.medication_outlined,
                color: pris ? AppColors.success : AppColors.primary,
                size: 22,
              ),
            ),

            const SizedBox(width: 14),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    rappel['nom_medicament'] ?? '',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: pris
                          ? AppColors.textSecondary
                          : AppColors.textPrimary,
                      decoration: pris
                          ? TextDecoration.lineThrough
                          : TextDecoration.none,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    rappel['dosage'] ?? '1 comprimé',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            // Bouton confirmer prise (idempotent : une fois par jour)
            GestureDetector(
              onTap: pris
                  ? null
                  : () async {
                      await context
                          .read<PatientProvider>()
                          .confirmerPrise(rappel['id'] as int? ?? 0);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              '✓ ${rappel['nom_medicament']} ${AppTranslations.t('pris_court')}',
                            ),
                            backgroundColor: AppColors.success,
                            duration: const Duration(seconds: 2),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            margin: const EdgeInsets.all(16),
                          ),
                        );
                      }
                    },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 36, height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: pris ? AppColors.success : Colors.transparent,
                  border: Border.all(
                    color: pris
                        ? AppColors.success
                        : const Color(0xFFCFD8DC),
                    width: 1.5,
                  ),
                ),
                child: pris
                    ? const Icon(
                  Icons.check,
                  color: Colors.white, size: 18,
                )
                    : null,
              ),
            ),

          ],
        ),
      ),
    );
  }
}

// ── FORMULAIRE AJOUT RAPPEL ──────────────────────────────────────────────────

class _FormulaireAjoutRappel extends StatefulWidget {
  const _FormulaireAjoutRappel();

  @override
  State<_FormulaireAjoutRappel> createState() =>
      _FormulaireAjoutRappelState();
}

class _FormulaireAjoutRappelState
    extends State<_FormulaireAjoutRappel> {

  final TextEditingController _nomController    = TextEditingController();
  final TextEditingController _dosageController = TextEditingController();
  TimeOfDay _heure = TimeOfDay.now();
  bool _enChargement = false;

  @override
  void dispose() {
    _nomController.dispose();
    _dosageController.dispose();
    super.dispose();
  }

  Future<void> _choisirHeure() async {
    final h = await showTimePicker(
      context: context,
      initialTime: _heure,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppColors.primary,
          ),
        ),
        child: child!,
      ),
    );
    if (h != null) setState(() => _heure = h);
  }

  Future<void> _enregistrer() async {
    if (_nomController.text.trim().isEmpty) return;

    setState(() => _enChargement = true);

    final heure =
        '${_heure.hour.toString().padLeft(2, '0')}h'
        '${_heure.minute.toString().padLeft(2, '0')}';

    // 1 — Sauvegarde dans SQLite
    await context.read<PatientProvider>().ajouterRappel(
      nomMedicament: _nomController.text.trim(),
      dosage: _dosageController.text.trim().isEmpty
          ? '1 comprimé'
          : _dosageController.text.trim(),
      heure: heure,
    );

    // 2 — Programme la notification locale
    await NotificationService().programmerDepuisTexte(
      id: DateTime.now().millisecondsSinceEpoch % 100000,
      nomMedicament: _nomController.text.trim(),
      dosage: _dosageController.text.trim().isEmpty
          ? '1 comprimé'
          : _dosageController.text.trim(),
      heureTexte: heure,
    );

    if (!mounted) return;
    setState(() => _enChargement = false);
    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '✓ ${_nomController.text} — rappel programmé à $heure',
        ),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft:  Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      padding: EdgeInsets.only(
        left: 24, right: 24, top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // Barre de drag
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE0E7EF),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          const SizedBox(height: 20),

          const Text(
            'Ajouter un médicament',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),

          const SizedBox(height: 20),

          // Nom du médicament
          _champForm(
            controller: _nomController,
            label: 'Nom du médicament',
            hint: 'Ex : Lamivudine',
            icone: Icons.medication_outlined,
          ),

          const SizedBox(height: 14),

          // Dosage
          _champForm(
            controller: _dosageController,
            label: 'Dosage',
            hint: 'Ex : 150mg — 1 comprimé',
            icone: Icons.science_outlined,
          ),

          const SizedBox(height: 14),

          // Sélecteur d'heure
          GestureDetector(
            onTap: _choisirHeure,
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE0E7EF)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.schedule,
                    color: AppColors.primary, size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Heure de prise',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${_heure.hour.toString().padLeft(2, '0')}h'
                              '${_heure.minute.toString().padLeft(2, '0')}',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Bouton enregistrer
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _enChargement ? null : _enregistrer,
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
                  color: Colors.white, strokeWidth: 2.5,
                ),
              )
                  : const Text(
                'Enregistrer',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),

        ],
      ),
    );
  }

  Widget _champForm({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icone,
  }) {
    return TextField(
      controller: controller,
      style: const TextStyle(
        fontSize: 14, color: AppColors.textPrimary,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icone, color: AppColors.primary, size: 20),
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
          borderSide: const BorderSide(
            color: AppColors.primary, width: 1.5,
          ),
        ),
        labelStyle: const TextStyle(
          color: AppColors.textSecondary, fontSize: 13,
        ),
      ),
    );
  }
}

// ── ONGLET SEMAINE ───────────────────────────────────────────────────────────

class _OngletSemaine extends StatelessWidget {
  const _OngletSemaine();

  @override
  Widget build(BuildContext context) {
    final t = AppTranslations.t;
    final jours = [
      t('jour_lun'), t('jour_mar'), t('jour_mer'), t('jour_jeu'),
      t('jour_ven'), t('jour_sam'), t('jour_dim'),
    ];
    final aujourd = DateTime.now().weekday - 1;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: jours.asMap().entries.map((entry) {
        final estAujourdhui = entry.key == aujourd;
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: estAujourdhui
                ? AppColors.primaryPale
                : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: estAujourdhui
                  ? AppColors.primary
                  : const Color(0xFFE0E7EF),
            ),
          ),
          child: Row(
            children: [
              Text(
                entry.value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: estAujourdhui
                      ? AppColors.primary
                      : AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              if (estAujourdhui)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    t('aujourdhui'),
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

// ── ONGLET HISTORIQUE ────────────────────────────────────────────────────────

class _OngletHistorique extends StatelessWidget {
  final List<Map<String, dynamic>> historique;

  const _OngletHistorique({required this.historique});

  @override
  Widget build(BuildContext context) {
    final t = AppTranslations.t;
    if (historique.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history,
              size: 64,
              color: AppColors.primary.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              t('aucun_historique'),
              style: const TextStyle(
                fontSize: 15,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              t('historique_vide_desc'),
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    final totalPrises = historique.length;
    final prises = historique
        .where((p) => p['statut'] == 'pris')
        .length;
    final taux = totalPrises > 0
        ? (prises / totalPrises * 100).toInt()
        : 0;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [

        // Carte observance
        Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.only(bottom: 20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1565C0), Color(0xFF1976D2)],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t('taux_observance'),
                      style: const TextStyle(
                        color: Colors.white70, fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$taux%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      '$prises/$totalPrises ${t('prises_label')}',
                      style: const TextStyle(
                        color: Colors.white60, fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.trending_up,
                color: Colors.white, size: 48,
              ),
            ],
          ),
        ),

        // Liste des prises
        Text(
          t('detail_prises'),
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),

        const SizedBox(height: 12),

        ...historique.reversed.map((prise) {
          final estPris = prise['statut'] == 'pris';
          final date = DateTime.tryParse(
            prise['date_heure'] as String? ?? '',
          );
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: estPris
                    ? AppColors.success.withValues(alpha: 0.3)
                    : AppColors.danger.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: estPris
                        ? AppColors.success.withValues(alpha: 0.1)
                        : AppColors.danger.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    estPris ? Icons.check : Icons.close,
                    color: estPris
                        ? AppColors.success
                        : AppColors.danger,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        estPris ? t('prise_confirmee') : t('prise_manquee'),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: estPris
                              ? AppColors.success
                              : AppColors.danger,
                        ),
                      ),
                      if (date != null)
                        Text(
                          '${date.day}/${date.month}/${date.year} '
                              'à ${date.hour}h${date.minute.toString().padLeft(2, '0')}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),

      ],
    );
  }
}