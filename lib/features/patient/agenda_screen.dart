import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/l10n/app_translations.dart';
import '../../core/providers/langue_provider.dart';
import '../../core/services/database_service.dart';
import '../../core/services/session_service.dart';
import '../../core/services/sync_service.dart';

/// Agenda du patient — consultation seule.
///
/// Les rendez-vous sont désormais fixés par le médecin (logique hospitalière) ;
/// le patient les récupère depuis Firestore et les consulte, sans pouvoir en
/// créer ni en supprimer.
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

      // Récupère d'abord les rendez-vous fixés par le médecin (Firestore).
      final numero = await SessionService().getNumero();
      if (numero != null && numero.isNotEmpty) {
        await SyncService().pullRendezVous(numero, patientId);
      }

      final tous = await DatabaseService().getRendezVous(patientId);
      final now = DateTime.now();

      setState(() {
        _rdvAVenir = tous.where((r) {
          final d = DateTime.tryParse(r['date'] as String? ?? '');
          return d != null && d.isAfter(now);
        }).toList()
          ..sort((a, b) =>
              DateTime.parse(a['date']).compareTo(DateTime.parse(b['date'])));

        _rdvPasses = tous.where((r) {
          final d = DateTime.tryParse(r['date'] as String? ?? '');
          return d != null && !d.isAfter(now);
        }).toList()
          ..sort((a, b) =>
              DateTime.parse(b['date']).compareTo(DateTime.parse(a['date'])));
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
                    child: CircularProgressIndicator(color: AppColors.primary),
                  )
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _ListeRdv(
                        rdvs: _rdvAVenir,
                        messageVide: t('aucun_rdv_avenir'),
                        estAVenir: true,
                      ),
                      _ListeRdv(
                        rdvs: _rdvPasses,
                        messageVide: t('aucun_rdv_passe'),
                        estAVenir: false,
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Liste des rendez-vous (consultation seule)
// ─────────────────────────────────────────────────────────────────────────────
class _ListeRdv extends StatelessWidget {
  final List<Map<String, dynamic>> rdvs;
  final String messageVide;
  final bool estAVenir;

  const _ListeRdv({
    required this.rdvs,
    required this.messageVide,
    required this.estAVenir,
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

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      itemCount: rdvs.length,
      itemBuilder: (_, i) => _CarteRdv(rdv: rdvs[i], estAVenir: estAVenir),
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
