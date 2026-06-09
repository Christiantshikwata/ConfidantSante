

import 'package:flutter/material.dart';
//import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/l10n/app_translations.dart';
import '../../core/services/database_service.dart';
//import '../../core/providers/patient_provider.dart';
import '../../core/services/session_service.dart';

class AgendaScreen extends StatefulWidget {
  const AgendaScreen({super.key});

  @override
  State<AgendaScreen> createState() => _AgendaScreenState();
}

class _AgendaScreenState extends State<AgendaScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _rdvAVenir = [];
  List<Map<String, dynamic>> _rdvPasses = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _chargerRdv();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _chargerRdv() async {
    setState(() => _isLoading = true);
    try {
      // Récupère l'id du patient connecté depuis SessionService
      final idStr = await SessionService().getPatientId();
      if (idStr == null) return;
      final patientId = int.tryParse(idStr);
      if (patientId == null) return;

      final db = DatabaseService();
      final tous = await db.getRendezVous(patientId);
      final now = DateTime.now();

      setState(() {
        _rdvAVenir = tous
            .where((r) {
          final d = DateTime.tryParse(r['date'] as String? ?? '');
          return d != null && d.isAfter(now);
        })
            .toList()
          ..sort((a, b) => DateTime.parse(a['date'])
              .compareTo(DateTime.parse(b['date'])));

        _rdvPasses = tous
            .where((r) {
          final d = DateTime.tryParse(r['date'] as String? ?? '');
          return d != null && !d.isAfter(now);
        })
            .toList()
          ..sort((a, b) => DateTime.parse(b['date'])
              .compareTo(DateTime.parse(a['date'])));
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _ajouterRdv() async {
    final t = AppTranslations.t;
    final idStr = await SessionService().getPatientId();
    if (idStr == null) return;
    final patientId = int.tryParse(idStr);
    if (patientId == null) return;

    DateTime? selectedDate;
    TimeOfDay selectedTime = const TimeOfDay(hour: 8, minute: 0);
    final motifCtrl = TextEditingController();
    final lieuCtrl = TextEditingController();

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

                // Poignée
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

                Text(
                  t('ajouter_rdv'),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),

                const SizedBox(height: 20),

                // Motif
                _LabelChamp(t('motif_rdv')),
                const SizedBox(height: 6),
                _ChampTexte(
                  controller: motifCtrl,
                  hint: t('motif_hint'),
                  icon: Icons.medical_services_outlined,
                ),

                const SizedBox(height: 14),

                // Lieu
                _LabelChamp(t('lieu_rdv')),
                const SizedBox(height: 6),
                _ChampTexte(
                  controller: lieuCtrl,
                  hint: t('lieu_hint'),
                  icon: Icons.location_on_outlined,
                ),

                const SizedBox(height: 14),

                // Date
                _LabelChamp(t('date_rdv')),
                const SizedBox(height: 6),
                GestureDetector(
                  onTap: () async {
                    final d = await showDatePicker(
                      context: ctx,
                      initialDate: DateTime.now().add(const Duration(days: 1)),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                      builder: (context, child) => Theme(
                        data: Theme.of(context).copyWith(
                          colorScheme: const ColorScheme.light(
                            primary: AppColors.primary,
                          ),
                        ),
                        child: child!,
                      ),
                    );
                    if (d != null) setModal(() => selectedDate = d);
                  },
                  child: _BoiteSelection(
                    icon: Icons.calendar_today_rounded,
                    text: selectedDate != null
                        ? DateFormat('dd MMMM yyyy', 'fr_FR').format(selectedDate!)
                        : t('choisir_date'),
                    actif: selectedDate != null,
                  ),
                ),

                const SizedBox(height: 14),

                // Heure
                _LabelChamp(t('heure_rdv')),
                const SizedBox(height: 6),
                GestureDetector(
                  onTap: () async {
                    final ti = await showTimePicker(
                      context: ctx,
                      initialTime: selectedTime,
                    );
                    if (ti != null) setModal(() => selectedTime = ti);
                  },
                  child: _BoiteSelection(
                    icon: Icons.access_time_rounded,
                    text: selectedTime.format(ctx),
                    actif: true,
                  ),
                ),

                const SizedBox(height: 28),

                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (selectedDate == null ||
                          motifCtrl.text.trim().isEmpty) {
                        return;
                      }

                      final dateTime = DateTime(
                        selectedDate!.year,
                        selectedDate!.month,
                        selectedDate!.day,
                        selectedTime.hour,
                        selectedTime.minute,
                      );

                      // Sauvegarde dans SQLite
                      await DatabaseService().ajouterRendezVous(
                        patientId: patientId,
                        motif: motifCtrl.text.trim(),
                        lieu: lieuCtrl.text.trim(),
                        date: dateTime.toIso8601String(),
                      );

                      if (!ctx.mounted) return;
                      Navigator.pop(ctx);
                      _chargerRdv();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      t('enregistrer'),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
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
            decoration: const BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Column(
                children: [

                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
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
                            child: const Icon(
                              Icons.arrow_back_ios_new,
                              color: Colors.white, size: 16,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Text(
                          t('agenda_titre'),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  TabBar(
                    controller: _tabController,
                    indicatorColor: Colors.white,
                    indicatorWeight: 3,
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.white.withValues(alpha: 0.5),
                    labelStyle: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                    tabs: [
                      Tab(text: t('rdv_a_venir')),
                      Tab(text: t('rdv_passes')),
                    ],
                  ),

                ],
              ),
            ),
          ),

          // ── Contenu ──────────────────────────────────────────────────
          Expanded(
            child: _isLoading
                ? const Center(
              child: CircularProgressIndicator(
                color: AppColors.primary,
              ),
            )
                : TabBarView(
              controller: _tabController,
              children: [
                _ListeRdv(
                  rdvs: _rdvAVenir,
                  messageVide: t('aucun_rdv_avenir'),
                  estAVenir: true,
                  onSupprimer: (id) async {
                    await DatabaseService().supprimerRendezVous(id);
                    _chargerRdv();
                  },
                ),
                _ListeRdv(
                  rdvs: _rdvPasses,
                  messageVide: t('aucun_rdv_passe'),
                  estAVenir: false,
                  onSupprimer: (id) async {
                    await DatabaseService().supprimerRendezVous(id);
                    _chargerRdv();
                  },
                ),
              ],
            ),
          ),

        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _ajouterRdv,
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Liste des rendez-vous
// ─────────────────────────────────────────────────────────────────────────────
class _ListeRdv extends StatelessWidget {
  final List<Map<String, dynamic>> rdvs;
  final String messageVide;
  final bool estAVenir;
  final void Function(int) onSupprimer;

  const _ListeRdv({
    required this.rdvs,
    required this.messageVide,
    required this.estAVenir,
    required this.onSupprimer,
  });

  @override
  Widget build(BuildContext context) {
    if (rdvs.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.calendar_today_rounded,
                size: 64,
                color: AppColors.primary.withValues(alpha: 0.3),
              ),
              const SizedBox(height: 16),
              Text(
                messageVide,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  color: AppColors.textSecondary,
                  height: 1.6,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {},
      color: AppColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
        itemCount: rdvs.length,
        itemBuilder: (_, i) {
          final rdv = rdvs[i];
          return Dismissible(
            key: Key('rdv_${rdv['id']}'),
            direction: DismissDirection.endToStart,
            onDismissed: (_) => onSupprimer(rdv['id'] as int),
            background: Container(
              margin: const EdgeInsets.symmetric(vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFFFEBEE),
                borderRadius: BorderRadius.circular(16),
              ),
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 20),
              child: const Icon(
                Icons.delete_rounded,
                color: AppColors.danger, size: 24,
              ),
            ),
            child: _CarteRdv(rdv: rdv, estAVenir: estAVenir),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Carte d'un rendez-vous
// ─────────────────────────────────────────────────────────────────────────────
class _CarteRdv extends StatelessWidget {
  final Map<String, dynamic> rdv;
  final bool estAVenir;

  const _CarteRdv({required this.rdv, required this.estAVenir});

  @override
  Widget build(BuildContext context) {
    final date = DateTime.tryParse(rdv['date'] as String? ?? '');
    final t = AppTranslations.t;

    final isAujourdhui = date != null &&
        date.day == DateTime.now().day &&
        date.month == DateTime.now().month &&
        date.year == DateTime.now().year;

    final couleur = isAujourdhui
        ? const Color(0xFFE65100)
        : estAVenir
        ? AppColors.primary
        : AppColors.textSecondary;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isAujourdhui
            ? Border.all(color: const Color(0xFFE65100), width: 1.5)
            : Border.all(color: const Color(0xFFE0E7EF)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // Bloc date
            Container(
              width: 52, height: 60,
              decoration: BoxDecoration(
                color: couleur.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    date != null ? DateFormat('dd').format(date) : '--',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: couleur,
                    ),
                  ),
                  Text(
                    date != null
                        ? DateFormat('MMM', 'fr_FR').format(date).toUpperCase()
                        : '--',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: couleur,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 14),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  if (isAujourdhui) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE65100).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        t('rdv_aujourd_hui'),
                        style: const TextStyle(
                          fontSize: 10,
                          color: Color(0xFFE65100),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                  ],

                  Text(
                    rdv['motif'] as String? ?? '',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),

                  const SizedBox(height: 6),

                  if ((rdv['lieu'] as String? ?? '').isNotEmpty)
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined,
                            size: 13, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            rdv['lieu'] as String,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),

                  const SizedBox(height: 4),

                  Row(
                    children: [
                      const Icon(Icons.access_time_rounded,
                          size: 13, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        date != null
                            ? DateFormat('HH:mm').format(date)
                            : '--:--',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
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
}

// ─────────────────────────────────────────────────────────────────────────────
//  Widgets de formulaire
// ─────────────────────────────────────────────────────────────────────────────
class _LabelChamp extends StatelessWidget {
  final String text;
  const _LabelChamp(this.text);

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w600,
      color: AppColors.textPrimary,
    ),
  );
}

class _ChampTexte extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;

  const _ChampTexte({
    required this.controller,
    required this.hint,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) => TextField(
    controller: controller,
    style: const TextStyle(
      fontSize: 14, color: AppColors.textPrimary,
    ),
    decoration: InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(
        color: Color(0xFFB0BEC5), fontSize: 14,
      ),
      prefixIcon: Icon(icon, color: AppColors.primary, size: 20),
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
    ),
  );
}

class _BoiteSelection extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool actif;

  const _BoiteSelection({
    required this.icon,
    required this.text,
    required this.actif,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(
        horizontal: 14, vertical: 14),
    decoration: BoxDecoration(
      color: actif
          ? AppColors.primaryPale
          : const Color(0xFFF8FAFF),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: actif
            ? AppColors.primary.withValues(alpha: 0.4)
            : const Color(0xFFE0E7EF),
      ),
    ),
    child: Row(
      children: [
        Icon(icon,
            color: actif ? AppColors.primary : AppColors.textSecondary,
            size: 20),
        const SizedBox(width: 10),
        Text(
          text,
          style: TextStyle(
            fontSize: 14,
            fontWeight: actif ? FontWeight.w600 : FontWeight.normal,
            color: actif ? AppColors.primary : AppColors.textSecondary,
          ),
        ),
      ],
    ),
  );
}