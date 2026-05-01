import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

// Modèle de données pour un patient
class PatientModel {
  final String id;
  final String nom;
  final String initiales;
  final String protocole;
  final double observance;
  final String dernierePrise;
  final bool enAlerte;
  final String statut;
  final Color couleurAvatar;

  const PatientModel({
    required this.id,
    required this.nom,
    required this.initiales,
    required this.protocole,
    required this.observance,
    required this.dernierePrise,
    required this.enAlerte,
    required this.statut,
    required this.couleurAvatar,
  });
}

class DashboardSoignantScreen extends StatefulWidget {
  const DashboardSoignantScreen({super.key});

  @override
  State<DashboardSoignantScreen> createState() =>
      _DashboardSoignantScreenState();
}

class _DashboardSoignantScreenState
    extends State<DashboardSoignantScreen> {

  int _pageActive = 0;

  // Données simulées des patients
  final List<PatientModel> _patients = const [
    PatientModel(
      id: '1',
      nom: 'Christian Ngoy',
      initiales: 'CN',
      protocole: 'Lam. + Efa. + Tén.',
      observance: 0.87,
      dernierePrise: "Aujourd'hui 08h00",
      enAlerte: false,
      statut: 'Actif',
      couleurAvatar: AppColors.primary,
    ),
    PatientModel(
      id: '2',
      nom: 'K. Mukendi',
      initiales: 'KM',
      protocole: 'Lam. + Névi.',
      observance: 0.42,
      dernierePrise: 'Il y a 3 jours',
      enAlerte: true,
      statut: 'En retard',
      couleurAvatar: AppColors.danger,
    ),
    PatientModel(
      id: '3',
      nom: 'M. Ntumba',
      initiales: 'MN',
      protocole: 'Efa. + Tén.',
      observance: 0.68,
      dernierePrise: 'Hier 21h00',
      enAlerte: true,
      statut: 'Attention',
      couleurAvatar: AppColors.warning,
    ),
    PatientModel(
      id: '4',
      nom: 'B. Kalenda',
      initiales: 'BK',
      protocole: 'Lam. + Efa.',
      observance: 0.95,
      dernierePrise: "Aujourd'hui 21h00",
      enAlerte: false,
      statut: 'Excellent',
      couleurAvatar: AppColors.success,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      body: _pageActive == 0
          ? _PageAccueilSoignant(patients: _patients)
          : _PagePatientsSoignant(patients: _patients),
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
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
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

// ── PAGE ACCUEIL SOIGNANT ────────────────────────────────────────────────────

class _PageAccueilSoignant extends StatelessWidget {
  final List<PatientModel> patients;

  const _PageAccueilSoignant({required this.patients});

  // Patients en alerte
  List<PatientModel> get _alertes =>
      patients.where((p) => p.enAlerte).toList();

  // Observance moyenne
  double get _observanceMoyenne =>
      patients.fold(0.0, (sum, p) => sum + p.observance) /
          patients.length;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [

        // En-tête soignant — bleu cyan distinct du patient
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

                    // Ligne du haut
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
                              const Text(
                                'Dr. Ndetereyuwe',
                                style: TextStyle(
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
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.3),
                            ),
                          ),
                          child: const Row(
                            children: [
                              Icon(
                                Icons.medical_services_outlined,
                                color: Colors.white,
                                size: 14,
                              ),
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

                    // 3 stats rapides
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
                          valeur:
                          '${(_observanceMoyenne * 100).toInt()}%',
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

              // Section alertes
              if (_alertes.isNotEmpty) ...[
                _titreSec('Alertes actives', couleur: AppColors.danger),
                const SizedBox(height: 12),
                ..._alertes.map(
                      (p) => _CarteAlerte(patient: p),
                ),
                const SizedBox(height: 20),
              ],

              // Section tous les patients
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _titreSec('Tous mes patients'),
                  Text(
                    '${patients.length} patients',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Liste patients
              ...patients.map(
                    (p) => _LignePatient(patient: p),
              ),

              const SizedBox(height: 100),

            ]),
          ),
        ),

      ],
    );
  }

  static String _salutation() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Bonjour Dr.';
    if (h < 17) return 'Bon après-midi Dr.';
    return 'Bonsoir Dr.';
  }

  Widget _titreSec(String titre, {Color? couleur}) {
    return Text(
      titre,
      style: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: couleur ?? AppColors.textPrimary,
        letterSpacing: 0.2,
      ),
    );
  }
}

// ── PAGE PATIENTS SOIGNANT ───────────────────────────────────────────────────

class _PagePatientsSoignant extends StatefulWidget {
  final List<PatientModel> patients;

  const _PagePatientsSoignant({required this.patients});

  @override
  State<_PagePatientsSoignant> createState() =>
      _PagePatientsSoignantState();
}

class _PagePatientsSoignantState
    extends State<_PagePatientsSoignant> {

  String _recherche = '';

  List<PatientModel> get _patientsFiltres => widget.patients
      .where((p) =>
      p.nom.toLowerCase().contains(_recherche.toLowerCase()))
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
                  const Text(
                    'Mes patients',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 14),
                  // Barre de recherche
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextField(
                      onChanged: (v) =>
                          setState(() => _recherche = v),
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textPrimary,
                      ),
                      decoration: const InputDecoration(
                        hintText: 'Rechercher un patient...',
                        hintStyle: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                        ),
                        prefixIcon: Icon(
                          Icons.search,
                          color: AppColors.textSecondary,
                          size: 20,
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Liste des patients
        Expanded(
          child: _patientsFiltres.isEmpty
              ? const Center(
            child: Text(
              'Aucun patient trouvé',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
          )
              : ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: _patientsFiltres.length,
            itemBuilder: (context, index) {
              return _CartePatientDetail(
                patient: _patientsFiltres[index],
              );
            },
          ),
        ),

      ],
    );
  }
}

// ── STAT SOIGNANT ────────────────────────────────────────────────────────────

class _StatSoignant extends StatelessWidget {
  final String valeur;
  final String label;
  final IconData icone;
  final bool estAlerte;

  const _StatSoignant({
    required this.valeur,
    required this.label,
    required this.icone,
    this.estAlerte = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: estAlerte
              ? AppColors.danger.withValues(alpha: 0.2)
              : Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
          border: estAlerte
              ? Border.all(
            color: AppColors.danger.withValues(alpha: 0.4),
          )
              : null,
        ),
        child: Column(
          children: [
            Icon(icone, color: Colors.white, size: 18),
            const SizedBox(height: 6),
            Text(
              valeur,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── CARTE ALERTE ─────────────────────────────────────────────────────────────

class _CarteAlerte extends StatelessWidget {
  final PatientModel patient;

  const _CarteAlerte({required this.patient});

  @override
  Widget build(BuildContext context) {
    final estUrgent = patient.observance < 0.5;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border(
          left: BorderSide(
            color: estUrgent ? AppColors.danger : AppColors.warning,
            width: 3,
          ),
          top: const BorderSide(color: Color(0xFFE0E7EF)),
          right: const BorderSide(color: Color(0xFFE0E7EF)),
          bottom: const BorderSide(color: Color(0xFFE0E7EF)),
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
          // Avatar
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: patient.couleurAvatar,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                patient.initiales,
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
                  patient.nom,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  estUrgent
                      ? 'Dernière prise : ${patient.dernierePrise}'
                      : 'Observance en baisse : '
                      '${(patient.observance * 100).toInt()}%',
                  style: TextStyle(
                    fontSize: 12,
                    color: estUrgent
                        ? AppColors.danger
                        : AppColors.warning,
                  ),
                ),
              ],
            ),
          ),

          // Badge
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 5,
            ),
            decoration: BoxDecoration(
              color: estUrgent
                  ? AppColors.danger.withValues(alpha: 0.1)
                  : AppColors.warning.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              estUrgent ? 'Urgent' : 'Attention',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: estUrgent ? AppColors.danger : AppColors.warning,
              ),
            ),
          ),

        ],
      ),
    );
  }
}

// ── LIGNE PATIENT (liste principale) ─────────────────────────────────────────

class _LignePatient extends StatelessWidget {
  final PatientModel patient;

  const _LignePatient({required this.patient});

  Color get _couleurObservance {
    if (patient.observance >= 0.9) return AppColors.success;
    if (patient.observance >= 0.7) return AppColors.warning;
    return AppColors.danger;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                DossierPatientScreen(patient: patient),
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
            // Avatar
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: patient.couleurAvatar,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  patient.initiales,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),

            const SizedBox(width: 14),

            // Infos
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    patient.nom,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    patient.protocole,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  // Barre observance
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(3),
                          child: LinearProgressIndicator(
                            value: patient.observance,
                            backgroundColor: const Color(0xFFE0E7EF),
                            valueColor: AlwaysStoppedAnimation(
                              _couleurObservance,
                            ),
                            minHeight: 5,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${(patient.observance * 100).toInt()}%',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: _couleurObservance,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(width: 10),

            // Flèche
            const Icon(
              Icons.chevron_right,
              color: AppColors.textSecondary,
              size: 20,
            ),

          ],
        ),
      ),
    );
  }
}

// ── CARTE PATIENT DÉTAIL (onglet Mes patients) ────────────────────────────────

class _CartePatientDetail extends StatelessWidget {
  final PatientModel patient;

  const _CartePatientDetail({required this.patient});

  Color get _couleurObservance {
    if (patient.observance >= 0.9) return AppColors.success;
    if (patient.observance >= 0.7) return AppColors.warning;
    return AppColors.danger;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                DossierPatientScreen(patient: patient),
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
                // Avatar
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: patient.couleurAvatar,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      patient.initiales,
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
                        patient.nom,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        patient.protocole,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),

                // Badge statut
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: _couleurObservance.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    patient.statut,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: _couleurObservance,
                    ),
                  ),
                ),

              ],
            ),

            const SizedBox(height: 14),

            // Barre observance
            Row(
              children: [
                const Text(
                  'Observance',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const Spacer(),
                Text(
                  '${(patient.observance * 100).toInt()}%',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _couleurObservance,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: patient.observance,
                backgroundColor: const Color(0xFFE0E7EF),
                valueColor: AlwaysStoppedAnimation(_couleurObservance),
                minHeight: 8,
              ),
            ),

            const SizedBox(height: 12),

            // Dernière prise
            Row(
              children: [
                const Icon(
                  Icons.access_time,
                  size: 14,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 6),
                Text(
                  'Dernière prise : ${patient.dernierePrise}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
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

// ── DOSSIER PATIENT ──────────────────────────────────────────────────────────

class DossierPatientScreen extends StatelessWidget {
  final PatientModel patient;

  const DossierPatientScreen({super.key, required this.patient});

  Color get _couleurObservance {
    if (patient.observance >= 0.9) return AppColors.success;
    if (patient.observance >= 0.7) return AppColors.warning;
    return AppColors.danger;
  }

  // Historique simulé
  final List<bool> _historique = const [
    true, true, true, false, true, true, true,
    true, true, false, true, true, true, true,
    true, true, true, true, true, false, true,
    true, true, true, true, true, true, true,
    true, false,
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      body: CustomScrollView(
        slivers: [

          // En-tête
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

                      // Retour
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

                      const SizedBox(height: 20),

                      // Avatar + nom
                      Row(
                        children: [
                          Container(
                            width: 60, height: 60,
                            decoration: BoxDecoration(
                              color: patient.couleurAvatar,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.4),
                                width: 2,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                patient.initiales,
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
                                  patient.nom,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'ID : CS-2026-00${patient.id}',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.7),
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Badge statut
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: _couleurObservance.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: _couleurObservance.withValues(alpha: 0.5),
                              ),
                            ),
                            child: Text(
                              patient.statut,
                              style: TextStyle(
                                color: _couleurObservance,
                                fontSize: 12,
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
                      valeur: '${(patient.observance * 100).toInt()}%',
                      label: 'Observance',
                      couleur: _couleurObservance,
                      fond: _couleurObservance.withValues(alpha: 0.1),
                    ),
                    const SizedBox(width: 12),
                    _StatDossier(
                      valeur: '26',
                      label: 'Prises confirmées',
                      couleur: AppColors.success,
                      fond: const Color(0xFFE8F5E9),
                    ),
                    const SizedBox(width: 12),
                    _StatDossier(
                      valeur: '4',
                      label: 'Manquées',
                      couleur: AppColors.danger,
                      fond: const Color(0xFFFFEBEE),
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
                      _ligneInfo('Protocole', patient.protocole),
                      _ligneInfo('Dosage/jour', '3 comprimés'),
                      _ligneInfo('Début traitement', '06/03/2026'),
                      _ligneInfo('Prochain RDV', '20/04/2026', dernier: true),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Historique
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
                  child: Column(
                    children: [
                      Row(
                        children: ['L','M','M','J','V','S','D']
                            .map((j) => Expanded(
                          child: Center(
                            child: Text(
                              j,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ))
                            .toList(),
                      ),
                      const SizedBox(height: 8),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 7,
                          crossAxisSpacing: 4,
                          mainAxisSpacing: 4,
                        ),
                        itemCount: _historique.length,
                        itemBuilder: (context, i) {
                          final pris = _historique[i];
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
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Actions
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Message envoyé au patient'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        icon: const Icon(Icons.message_outlined, size: 18),
                        label: const Text('Message'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0288D1),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Modification du protocole'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        label: const Text('Protocole'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF0288D1),
                          side: const BorderSide(
                            color: Color(0xFF0288D1),
                            width: 1.5,
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
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

  Widget _ligneInfo(
      String label,
      String valeur, {
        bool dernier = false,
      }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 16, vertical: 14,
      ),
      decoration: BoxDecoration(
        border: dernier
            ? null
            : const Border(
          bottom: BorderSide(
            color: Color(0xFFF0F4F8),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          const Spacer(),
          Text(
            valeur,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

// ── STAT DOSSIER ─────────────────────────────────────────────────────────────

class _StatDossier extends StatelessWidget {
  final String valeur;
  final String label;
  final Color couleur;
  final Color fond;

  const _StatDossier({
    required this.valeur,
    required this.label,
    required this.couleur,
    required this.fond,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: 14, horizontal: 10,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE0E7EF)),
        ),
        child: Column(
          children: [
            Text(
              valeur,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: couleur,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 10,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}