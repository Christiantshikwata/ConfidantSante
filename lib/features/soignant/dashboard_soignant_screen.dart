
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/database_service.dart';
import '../../core/services/session_service.dart';
import '../../core/services/sync_service.dart';
import '../messagerie/messagerie_screen.dart';
import 'ajouter_patient_screen.dart';

class DashboardSoignantScreen extends StatefulWidget {
  const DashboardSoignantScreen({super.key});

  @override
  State<DashboardSoignantScreen> createState() =>
      _DashboardSoignantScreenState();
}

class _DashboardSoignantScreenState extends State<DashboardSoignantScreen> {

  int _pageActive = 0;
  String _nomSoignant = 'Dr.';
  List<Map<String, dynamic>> _patients = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _chargerDonnees();
  }

  Future<void> _chargerDonnees() async {
    setState(() => _isLoading = true);
    try {
      final nom = await SessionService().getSoignantNom();
      final patients = await DatabaseService().getTousPatients();

      // Pour chaque patient, calcule son observance.
      // Source prioritaire : Firestore (données remontées par l'appareil du
      // patient, via le numéro de téléphone) ; repli sur la base locale.
      final patientsAvecObservance = await Future.wait(
        patients.map((p) async {
          final numero = p['numero'] as String? ?? '';
          double? obs;
          if (numero.isNotEmpty) {
            obs = await SyncService().getObservanceFirestore(numero);
          }
          obs ??= await DatabaseService().getObservancePatient(p['id'] as int);
          return {...p, 'observance': obs};
        }),
      );

      setState(() {
        _nomSoignant = nom ?? 'Dr. Ndetereyuwe';
        _patients = patientsAvecObservance;
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      body: _pageActive == 0
          ? _PageAccueil(
        nomSoignant: _nomSoignant,
        patients: _patients,
        isLoading: _isLoading,
        onRefresh: _chargerDonnees,
      )
          : _PagePatients(
        patients: _patients,
        isLoading: _isLoading,
        onRefresh: _chargerDonnees,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(
              color: const Color(0xFFE0E7EF),
              width: 0.5,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _pageActive,
          onTap: (i) => setState(() => _pageActive = i),
          backgroundColor: Colors.transparent,
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: const Color(0xFF0288D1),
          unselectedItemColor: const Color(0xFF94A3B8),
          selectedLabelStyle: const TextStyle(
              fontSize: 11, fontWeight: FontWeight.w600),
          unselectedLabelStyle: const TextStyle(fontSize: 11),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_outlined),
              activeIcon: Icon(Icons.dashboard),
              label: 'Tableau de bord',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.people_outline),
              activeIcon: Icon(Icons.people),
              label: 'Mes patients',
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  PAGE ACCUEIL SOIGNANT
// ─────────────────────────────────────────────────────────────────────────────
class _PageAccueil extends StatelessWidget {
  final String nomSoignant;
  final List<Map<String, dynamic>> patients;
  final bool isLoading;
  final VoidCallback onRefresh;

  const _PageAccueil({
    required this.nomSoignant,
    required this.patients,
    required this.isLoading,
    required this.onRefresh,
  });

  static String _salutation() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Bonjour Dr.';
    if (h < 17) return 'Bon après-midi Dr.';
    return 'Bonsoir Dr.';
  }

  List<Map<String, dynamic>> get _alertes => patients
      .where((p) => (p['observance'] as double? ?? 0) < 50)
      .toList();

  double get _observanceMoyenne {
    if (patients.isEmpty) return 0;
    final total = patients.fold<double>(
        0, (s, p) => s + (p['observance'] as double? ?? 0));
    return total / patients.length;
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      color: const Color(0xFF0288D1),
      child: CustomScrollView(
        slivers: [

          // En-tête
          SliverToBoxAdapter(
            child: Container(
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
                  bottomLeft: Radius.circular(28),
                  bottomRight: Radius.circular(28),
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _salutation(),
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.75),
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  nomSoignant,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Badge soignant
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.3),
                              ),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.medical_services_outlined,
                                    color: Colors.white, size: 14),
                                SizedBox(width: 6),
                                Text(
                                  'Soignant',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // 3 stats
                      Row(
                        children: [
                          _StatSoignant(
                            valeur: '${patients.length}',
                            label: 'Patients',
                            icone: Icons.people_outline,
                          ),
                          const SizedBox(width: 8),
                          _StatSoignant(
                            valeur: '${_alertes.length}',
                            label: 'Alertes',
                            icone: Icons.warning_amber_outlined,
                            estAlerte: _alertes.isNotEmpty,
                          ),
                          const SizedBox(width: 8),
                          _StatSoignant(
                            valeur: '${_observanceMoyenne.toInt()}%',
                            label: 'Moy. obs.',
                            icone: Icons.trending_up,
                          ),
                        ],
                      ),

                    ],
                  ),
                ),
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([

                if (isLoading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: CircularProgressIndicator(
                          color: Color(0xFF0288D1)),
                    ),
                  )
                else ...[

                  // Alertes
                  if (_alertes.isNotEmpty) ...[
                    const Text(
                      'Alertes actives',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.danger,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ..._alertes.map((p) => _CarteAlerte(patient: p)),
                    const SizedBox(height: 20),
                  ],

                  // Bouton ajouter patient
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AjouterPatientScreen(),
                          ),
                        );
                        onRefresh();
                      },
                      icon: const Icon(Icons.person_add_outlined, size: 20),
                      label: const Text(
                        'Ajouter un patient',
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0288D1),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Tous les patients
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Tous mes patients',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        '${patients.length} patient${patients.length > 1 ? 's' : ''}',
                        style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  if (patients.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          children: [
                            Icon(Icons.people_outline,
                                size: 64,
                                color: const Color(0xFF0288D1)
                                    .withValues(alpha: 0.3)),
                            const SizedBox(height: 16),
                            const Text(
                              'Aucun patient enregistré.\nAjoutez votre premier patient.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 15,
                                color: AppColors.textSecondary,
                                height: 1.6,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ...patients.map((p) => _LignePatient(patient: p)),

                ],

                const SizedBox(height: 100),

              ]),
            ),
          ),

        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  PAGE PATIENTS
// ─────────────────────────────────────────────────────────────────────────────
class _PagePatients extends StatefulWidget {
  final List<Map<String, dynamic>> patients;
  final bool isLoading;
  final VoidCallback onRefresh;

  const _PagePatients({
    required this.patients,
    required this.isLoading,
    required this.onRefresh,
  });

  @override
  State<_PagePatients> createState() => _PagePatientsState();
}

class _PagePatientsState extends State<_PagePatients> {
  String _recherche = '';

  List<Map<String, dynamic>> get _filtres => widget.patients
      .where((p) => (p['nom'] as String? ?? '')
      .toLowerCase()
      .contains(_recherche.toLowerCase()))
      .toList();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [

        // En-tête
        Container(
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Mes patients',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      GestureDetector(
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const AjouterPatientScreen(),
                            ),
                          );
                          widget.onRefresh();
                        },
                        child: Container(
                          width: 38, height: 38,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.person_add_outlined,
                            color: Colors.white, size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  // Barre de recherche
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextField(
                      onChanged: (v) => setState(() => _recherche = v),
                      style: const TextStyle(
                          fontSize: 14, color: AppColors.textPrimary),
                      decoration: const InputDecoration(
                        hintText: 'Rechercher un patient...',
                        hintStyle: TextStyle(
                            color: AppColors.textSecondary, fontSize: 14),
                        prefixIcon: Icon(Icons.search,
                            color: AppColors.textSecondary, size: 20),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Liste
        Expanded(
          child: widget.isLoading
              ? const Center(
              child: CircularProgressIndicator(
                  color: Color(0xFF0288D1)))
              : _filtres.isEmpty
              ? Center(
            child: Text(
              _recherche.isEmpty
                  ? 'Aucun patient enregistré.'
                  : 'Aucun résultat pour "$_recherche"',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
          )
              : ListView.builder(
            padding:
            const EdgeInsets.fromLTRB(20, 12, 20, 100),
            itemCount: _filtres.length,
            itemBuilder: (_, i) =>
                _CartePatientDetail(patient: _filtres[i]),
          ),
        ),

      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  WIDGETS COMMUNS
// ─────────────────────────────────────────────────────────────────────────────

class _StatSoignant extends StatelessWidget {
  final String valeur, label;
  final IconData icone;
  final bool estAlerte;

  const _StatSoignant({
    required this.valeur,
    required this.label,
    required this.icone,
    this.estAlerte = false,
  });

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: estAlerte
            ? AppColors.danger.withValues(alpha: 0.2)
            : Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: estAlerte
            ? Border.all(
            color: AppColors.danger.withValues(alpha: 0.4))
            : null,
      ),
      child: Column(
        children: [
          Icon(icone, color: Colors.white, size: 18),
          const SizedBox(height: 6),
          Text(valeur,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              )),
          Text(label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 11,
              )),
        ],
      ),
    ),
  );
}

class _CarteAlerte extends StatelessWidget {
  final Map<String, dynamic> patient;
  const _CarteAlerte({required this.patient});

  @override
  Widget build(BuildContext context) {
    final obs = (patient['observance'] as double? ?? 0);
    final initiales = (patient['nom'] as String? ?? 'P')
        .split(' ')
        .map((e) => e.isNotEmpty ? e[0] : '')
        .take(2)
        .join()
        .toUpperCase();

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border(
          left: BorderSide(color: AppColors.danger, width: 3),
          top: BorderSide(color: const Color(0xFFE0E7EF)),
          right: BorderSide(color: const Color(0xFFE0E7EF)),
          bottom: BorderSide(color: const Color(0xFFE0E7EF)),
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
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: AppColors.danger,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                initiales,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  patient['nom'] as String? ?? '',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  'Observance : ${obs.toInt()}% — Intervention requise',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.danger),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.danger.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'Urgent',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.danger,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LignePatient extends StatelessWidget {
  final Map<String, dynamic> patient;
  const _LignePatient({required this.patient});

  Color get _couleur {
    final obs = patient['observance'] as double? ?? 0;
    if (obs >= 90) return AppColors.success;
    if (obs >= 70) return AppColors.warning;
    return AppColors.danger;
  }

  @override
  Widget build(BuildContext context) {
    final obs = patient['observance'] as double? ?? 0;
    final initiales = (patient['nom'] as String? ?? 'P')
        .split(' ')
        .map((e) => e.isNotEmpty ? e[0] : '')
        .take(2)
        .join()
        .toUpperCase();

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DossierPatientScreen(patient: patient),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE0E7EF)),
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
                color: _couleur,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  initiales,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    patient['nom'] as String? ?? '',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '+243 ${patient['numero'] ?? ''}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(3),
                          child: LinearProgressIndicator(
                            value: obs / 100,
                            backgroundColor: const Color(0xFFE0E7EF),
                            valueColor:
                            AlwaysStoppedAnimation(_couleur),
                            minHeight: 5,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${obs.toInt()}%',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: _couleur,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            const Icon(Icons.chevron_right,
                color: AppColors.textSecondary, size: 20),
          ],
        ),
      ),
    );
  }
}

class _CartePatientDetail extends StatelessWidget {
  final Map<String, dynamic> patient;
  const _CartePatientDetail({required this.patient});

  Color get _couleur {
    final obs = patient['observance'] as double? ?? 0;
    if (obs >= 90) return AppColors.success;
    if (obs >= 70) return AppColors.warning;
    return AppColors.danger;
  }

  String get _statut {
    final obs = patient['observance'] as double? ?? 0;
    if (obs >= 90) return 'Excellent';
    if (obs >= 70) return 'Attention';
    return 'En retard';
  }

  @override
  Widget build(BuildContext context) {
    final obs = patient['observance'] as double? ?? 0;
    final initiales = (patient['nom'] as String? ?? 'P')
        .split(' ')
        .map((e) => e.isNotEmpty ? e[0] : '')
        .take(2)
        .join()
        .toUpperCase();

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DossierPatientScreen(patient: patient),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE0E7EF)),
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
            Row(
              children: [
                Container(
                  width: 52, height: 52,
                  decoration: BoxDecoration(
                    color: _couleur,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      initiales,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        patient['nom'] as String? ?? '',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        '+243 ${patient['numero'] ?? ''}',
                        style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: _couleur.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _statut,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: _couleur,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                const Text('Observance',
                    style: TextStyle(
                        fontSize: 12, color: AppColors.textSecondary)),
                const Spacer(),
                Text('${obs.toInt()}%',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: _couleur,
                    )),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: obs / 100,
                backgroundColor: const Color(0xFFE0E7EF),
                valueColor: AlwaysStoppedAnimation(_couleur),
                minHeight: 8,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.phone_outlined,
                    size: 14, color: AppColors.textSecondary),
                const SizedBox(width: 6),
                Text('+243 ${patient['numero'] ?? ''}',
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textSecondary)),
                const Spacer(),
                const Text(
                  'Voir le dossier →',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF0288D1),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  DOSSIER PATIENT
// ─────────────────────────────────────────────────────────────────────────────
class DossierPatientScreen extends StatefulWidget {
  final Map<String, dynamic> patient;
  const DossierPatientScreen({super.key, required this.patient});

  @override
  State<DossierPatientScreen> createState() => _DossierPatientScreenState();
}

class _DossierPatientScreenState extends State<DossierPatientScreen> {
  List<Map<String, dynamic>> _historique = [];
  List<Map<String, dynamic>> _traitements = [];

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    final id = widget.patient['id'] as int;
    final hist = await DatabaseService().getHistorique30j(id);
    final trait = await DatabaseService().getTraitements(id);
    setState(() {
      _historique = hist;
      _traitements = trait;
    });
  }

  // Médecin : attribue un protocole (médicament + dosage + durée) au patient.
  Future<void> _ajouterProtocole() async {
    final patientId = widget.patient['id'] as int;
    final nomCtrl = TextEditingController();
    final dosageCtrl = TextEditingController();
    int dureeMois = 1;

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
                const Text('Attribuer un protocole',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary)),
                const SizedBox(height: 4),
                const Text('Le patient choisira lui-même l\'heure de prise.',
                    style: TextStyle(
                        fontSize: 13, color: AppColors.textSecondary)),
                const SizedBox(height: 20),

                const Text('Médicament',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary)),
                const SizedBox(height: 6),
                TextField(
                  controller: nomCtrl,
                  decoration: _decoProto('Ex. : Tenofovir/Lamivudine'),
                ),
                const SizedBox(height: 14),

                const Text('Dosage',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary)),
                const SizedBox(height: 6),
                TextField(
                  controller: dosageCtrl,
                  decoration: _decoProto('Ex. : 300mg — 1 comprimé'),
                ),
                const SizedBox(height: 14),

                const Text('Durée du protocole',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary)),
                const SizedBox(height: 8),
                Row(
                  children: [1, 3, 6].map((m) {
                    final actif = dureeMois == m;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => setModal(() => dureeMois = m),
                        child: Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: actif
                                ? const Color(0xFF0288D1)
                                : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(12),
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
                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (nomCtrl.text.trim().isEmpty) return;
                      await DatabaseService().assignerProtocole(
                        patientId: patientId,
                        nomMedicament: nomCtrl.text.trim(),
                        dosage: dosageCtrl.text.trim().isEmpty
                            ? '1 comprimé'
                            : dosageCtrl.text.trim(),
                        dureeMois: dureeMois,
                      );
                      if (!ctx.mounted) return;
                      Navigator.pop(ctx);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0288D1),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text('Attribuer',
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

    if (mounted) {
      _charger();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Protocole attribué au patient'),
          backgroundColor: Color(0xFF0288D1),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  InputDecoration _decoProto(String hint) => InputDecoration(
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

  Color get _couleur {
    final obs = widget.patient['observance'] as double? ?? 0;
    if (obs >= 90) return AppColors.success;
    if (obs >= 70) return AppColors.warning;
    return AppColors.danger;
  }

  @override
  Widget build(BuildContext context) {
    final patient = widget.patient;
    final obs = patient['observance'] as double? ?? 0;
    final initiales = (patient['nom'] as String? ?? 'P')
        .split(' ')
        .map((e) => e.isNotEmpty ? e[0] : '')
        .take(2)
        .join()
        .toUpperCase();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      body: CustomScrollView(
        slivers: [

          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF01579B), Color(0xFF0288D1)],
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(28),
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
                          child: const Icon(Icons.arrow_back_ios_new,
                              color: Colors.white, size: 16),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Container(
                            width: 60, height: 60,
                            decoration: BoxDecoration(
                              color: _couleur,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.4),
                                width: 2,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                initiales,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  patient['nom'] as String? ?? '',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  '+243 ${patient['numero'] ?? ''}',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.7),
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: _couleur.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: _couleur.withValues(alpha: 0.5),
                              ),
                            ),
                            child: Text(
                              '${obs.toInt()}%',
                              style: TextStyle(
                                color: _couleur,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([

                // Stats
                Row(
                  children: [
                    _StatDossier(
                      valeur: '${obs.toInt()}%',
                      label: 'Observance',
                      couleur: _couleur,
                    ),
                    const SizedBox(width: 12),
                    _StatDossier(
                      valeur: '${_historique.where((p) => p['statut'] == 'pris').length}',
                      label: 'Prises confirmées',
                      couleur: AppColors.success,
                    ),
                    const SizedBox(width: 12),
                    _StatDossier(
                      valeur: '${_historique.where((p) => p['statut'] != 'pris').length}',
                      label: 'Manquées',
                      couleur: AppColors.danger,
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Traitement
                const Text(
                  'Traitement en cours',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),

                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE0E7EF)),
                  ),
                  child: Column(
                    children: [
                      _LigneInfo(
                        'Protocole',
                        _traitements.isNotEmpty
                            ? (_traitements.first['nom_medicament']
                        as String? ??
                            '—')
                            : '—',
                        false,
                      ),
                      _LigneInfo('Hôpital',
                          patient['hopital'] as String? ?? 'CHCC', false),
                      _LigneInfo('Soignant',
                          patient['soignant'] as String? ?? 'Dr. Ndetereyuwe',
                          true),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Historique grille
                const Text(
                  'Historique 30 jours',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),

                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE0E7EF)),
                  ),
                  child: _historique.isEmpty
                      ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(12),
                      child: Text('Aucune prise enregistrée',
                          style: TextStyle(
                              color: AppColors.textSecondary)),
                    ),
                  )
                      : GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 7,
                      crossAxisSpacing: 4,
                      mainAxisSpacing: 4,
                    ),
                    itemCount: _historique.length.clamp(0, 30),
                    itemBuilder: (_, i) {
                      final pris =
                          _historique[i]['statut'] == 'pris';
                      return Container(
                        decoration: BoxDecoration(
                          color: pris
                              ? const Color(0xFF0288D1)
                              : const Color(0xFFFFCDD2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 20),

                // Actions
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          final matricule =
                              await SessionService().getSoignantMatricule() ??
                                  DatabaseService.soignantDemoMatricule;
                          final numero = patient['numero'] as String? ?? '';
                          if (!context.mounted) return;
                          Navigator.push(context, MaterialPageRoute(
                            builder: (_) => MessagerieScreen(
                              conversationId:
                                  MessagerieScreen.conversationIdPour(
                                patientNumero: numero,
                                soignantMatricule: matricule,
                              ),
                              monId: matricule,
                              destinataireNom: patient['nom'] as String,
                              role: 'soignant',
                            ),
                          ));
                        },
                        icon: const Icon(Icons.message_outlined, size: 18),
                        label: const Text('Message'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0288D1),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _ajouterProtocole,
                        icon: const Icon(Icons.add_outlined, size: 18),
                        label: const Text('Protocole'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF0288D1),
                          side: const BorderSide(
                              color: Color(0xFF0288D1), width: 1.5),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 100),

              ]),
            ),
          ),

        ],
      ),
    );
  }

  Widget _LigneInfo(String label, String valeur, bool dernier) =>
      Container(
        padding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          border: dernier
              ? null
              : const Border(
              bottom: BorderSide(
                  color: Color(0xFFF0F4F8), width: 1)),
        ),
        child: Row(
          children: [
            Text(label,
                style: const TextStyle(
                    fontSize: 13, color: AppColors.textSecondary)),
            const Spacer(),
            Text(valeur,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                )),
          ],
        ),
      );
}

class _StatDossier extends StatelessWidget {
  final String valeur, label;
  final Color couleur;
  const _StatDossier(
      {required this.valeur, required this.label, required this.couleur});

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(
          vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE0E7EF)),
      ),
      child: Column(
        children: [
          Text(valeur,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: couleur,
              )),
          const SizedBox(height: 4),
          Text(label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 10,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              )),
        ],
      ),
    ),
  );
}