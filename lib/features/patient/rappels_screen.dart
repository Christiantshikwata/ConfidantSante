import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';


// Modèle de données pour un rappel
// C'est une classe simple qui représente un médicament avec ses horaires
class Rappel {
  final String id;
  final String nomMedicament;
  final String dosage;
  final List<String> heures;
  final String statut; // 'pris', 'attente', 'manque'
  bool estPris;

  Rappel({
    required this.id,
    required this.nomMedicament,
    required this.dosage,
    required this.heures,
    required this.statut,
    this.estPris = false,
  });
}

class RappelsScreen extends StatefulWidget {
  const RappelsScreen({super.key});

  @override
  State<RappelsScreen> createState() => _RappelsScreenState();
}

class _RappelsScreenState extends State<RappelsScreen>
    with SingleTickerProviderStateMixin {

  // Contrôleur pour les onglets Aujourd'hui / Semaine / Historique
  late TabController _tabController;

  // Liste des rappels du jour — données simulées
  // On les remplacera par SQLite plus tard
  final List<Rappel> _rappelsAujourdhui = [
    Rappel(
      id: '1',
      nomMedicament: 'Lamivudine',
      dosage: '150mg • 1 comprimé',
      heures: ['08h00'],
      statut: 'pris',
      estPris: true,
    ),
    Rappel(
      id: '2',
      nomMedicament: 'Efavirenz',
      dosage: '600mg • 1 comprimé',
      heures: ['21h00'],
      statut: 'attente',
    ),
    Rappel(
      id: '3',
      nomMedicament: 'Ténofovir',
      dosage: '300mg • 1 comprimé',
      heures: ['21h00'],
      statut: 'attente',
    ),
  ];

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

  // Marque un rappel comme pris ou non pris
  void _togglePrise(Rappel rappel) {
    setState(() => rappel.estPris = !rappel.estPris);

    // Affiche un message de confirmation
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          rappel.estPris
              ? '✓ ${rappel.nomMedicament} marqué comme pris'
              : '${rappel.nomMedicament} marqué comme non pris',
        ),
        backgroundColor: rappel.estPris
            ? AppColors.success
            : AppColors.textSecondary,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  // Ouvre le formulaire d'ajout de rappel
  void _ajouterRappel() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _FormulaireAjoutRappel(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),

      body: Column(
        children: [

          // En-tête
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
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [

                        const Text(
                          'Rappels',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                          ),
                        ),

                        // Bouton ajouter
                        GestureDetector(
                          onTap: _ajouterRappel,
                          child: Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.add,
                              color: Colors.white,
                              size: 22,
                            ),
                          ),
                        ),

                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Résumé rapide
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        _StatRapide(
                          valeur: _rappelsAujourdhui
                              .where((r) => r.estPris)
                              .length
                              .toString(),
                          label: 'Prises',
                          couleur: Colors.white,
                        ),
                        const SizedBox(width: 6),
                        _StatRapide(
                          valeur: _rappelsAujourdhui
                              .where((r) => !r.estPris)
                              .length
                              .toString(),
                          label: 'En attente',
                          couleur: Colors.white.withValues(alpha: 0.7),
                        ),
                        const SizedBox(width: 6),
                        _StatRapide(
                          valeur: _rappelsAujourdhui.length.toString(),
                          label: 'Total',
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
                    tabs: const [
                      Tab(text: "Aujourd'hui"),
                      Tab(text: 'Cette semaine'),
                      Tab(text: 'Historique'),
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

                // Onglet Aujourd'hui
                _OngletAujourdhui(
                  rappels: _rappelsAujourdhui,
                  onToggle: _togglePrise,
                ),

                // Onglet Semaine — placeholder
                const _OngletSemaine(),

                // Onglet Historique — placeholder
                const _OngletHistorique(),

              ],
            ),
          ),

        ],
      ),
    );
  }
}

// ── STAT RAPIDE ──────────────────────────────────────────────────────────────

class _StatRapide extends StatelessWidget {
  final String valeur;
  final String label;
  final Color couleur;

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
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: couleur.withValues(alpha: 0.8),
                fontSize: 11,
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
  final List<Rappel> rappels;
  final Function(Rappel) onToggle;

  const _OngletAujourdhui({
    required this.rappels,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    // Groupe les rappels par heure
    final Map<String, List<Rappel>> parHeure = {};
    for (final r in rappels) {
      for (final h in r.heures) {
        parHeure.putIfAbsent(h, () => []).add(r);
      }
    }

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [

        // Indicateur offline
        Container(
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
                size: 14,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Mode hors-ligne actif — données sauvegardées localement',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Rappels groupés par heure
        ...parHeure.entries.map((entry) {
          final heure = entry.key;
          final rappelsHeure = entry.value;
          final tousLusPris = rappelsHeure.every((r) => r.estPris);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // En-tête de groupe horaire
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: tousLusPris
                          ? AppColors.success.withValues(alpha: 0.1)
                          : AppColors.warning.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.schedule,
                          size: 12,
                          color: tousLusPris
                              ? AppColors.success
                              : AppColors.warning,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          heure,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: tousLusPris
                                ? AppColors.success
                                : AppColors.warning,
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
                  const SizedBox(width: 10),
                  // Badge statut
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: tousLusPris
                          ? AppColors.success.withValues(alpha: 0.1)
                          : AppColors.warning.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      tousLusPris ? 'Pris ✓' : 'En attente',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: tousLusPris
                            ? AppColors.success
                            : AppColors.warning,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // Cartes médicaments de ce groupe
              ...rappelsHeure.map((rappel) => _CarteRappel(
                rappel: rappel,
                onToggle: () => onToggle(rappel),
              )),

              const SizedBox(height: 20),

            ],
          );
        }),

      ],
    );
  }
}

// ── CARTE RAPPEL ─────────────────────────────────────────────────────────────

class _CarteRappel extends StatelessWidget {
  final Rappel rappel;
  final VoidCallback onToggle;

  const _CarteRappel({
    required this.rappel,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: rappel.estPris
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

          // Icône médicament
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: rappel.estPris
                  ? AppColors.success.withValues(alpha: 0.1)
                  : AppColors.primaryPale,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.medication_outlined,
              color: rappel.estPris
                  ? AppColors.success
                  : AppColors.primary,
              size: 22,
            ),
          ),

          const SizedBox(width: 14),

          // Informations
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  rappel.nomMedicament,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: rappel.estPris
                        ? AppColors.textSecondary
                        : AppColors.textPrimary,
                    decoration: rappel.estPris
                        ? TextDecoration.lineThrough
                        : TextDecoration.none,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  rappel.dosage,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          // Bouton confirmer
          GestureDetector(
            onTap: onToggle,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: rappel.estPris
                    ? AppColors.success
                    : Colors.transparent,
                border: Border.all(
                  color: rappel.estPris
                      ? AppColors.success
                      : const Color(0xFFCFD8DC),
                  width: 1.5,
                ),
              ),
              child: rappel.estPris
                  ? const Icon(
                Icons.check,
                color: Colors.white,
                size: 18,
              )
                  : null,
            ),
          ),

        ],
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

class _FormulaireAjoutRappelState extends State<_FormulaireAjoutRappel> {

  final TextEditingController _nomController = TextEditingController();
  final TextEditingController _dosageController = TextEditingController();
  TimeOfDay _heure = TimeOfDay.now();

  @override
  void dispose() {
    _nomController.dispose();
    _dosageController.dispose();
    super.dispose();
  }

  // Ouvre le sélecteur d'heure
  Future<void> _choisirHeure() async {
    final TimeOfDay? heure = await showTimePicker(
      context: context,
      initialTime: _heure,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (heure != null) setState(() => _heure = heure);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        // Évite que le clavier cache le formulaire
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // Barre de drag
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE0E7EF),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          const SizedBox(height: 20),

          const Text(
            'Ajouter un rappel',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),

          const SizedBox(height: 20),

          // Champ nom médicament
          _champTexte(
            controller: _nomController,
            label: 'Nom du médicament',
            hint: 'Ex : Lamivudine',
            icone: Icons.medication_outlined,
          ),

          const SizedBox(height: 14),

          // Champ dosage
          _champTexte(
            controller: _dosageController,
            label: 'Dosage',
            hint: 'Ex : 150mg • 1 comprimé',
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
                border: Border.all(
                  color: const Color(0xFFE0E7EF),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.schedule,
                    color: AppColors.primary,
                    size: 20,
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
              onPressed: () {
                // On fermera le formulaire et ajoutera le rappel
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Rappel "${_nomController.text}" ajouté',
                    ),
                    backgroundColor: AppColors.success,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    margin: const EdgeInsets.all(16),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                'Enregistrer le rappel',
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

  Widget _champTexte({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icone,
  }) {
    return TextField(
      controller: controller,
      style: const TextStyle(
        fontSize: 14,
        color: AppColors.textPrimary,
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
          color: AppColors.textSecondary,
          fontSize: 13,
        ),
      ),
    );
  }
}

// ── ONGLETS SEMAINE ET HISTORIQUE ────────────────────────────────────────────

class _OngletSemaine extends StatelessWidget {
  const _OngletSemaine();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Jours de la semaine
        ...['Lundi', 'Mardi', 'Mercredi', 'Jeudi',
          'Vendredi', 'Samedi', 'Dimanche']
            .asMap()
            .entries
            .map((entry) {
          final estAujourdhui = entry.key == 2; // Mercredi simulé
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
                    child: const Text(
                      "Aujourd'hui",
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                // Indicateurs de prises
                const SizedBox(width: 8),
                Row(
                  children: List.generate(3, (i) {
                    final estPris = i < (estAujourdhui ? 1 : 3);
                    return Container(
                      width: 8,
                      height: 8,
                      margin: const EdgeInsets.only(left: 4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: estPris
                            ? AppColors.success
                            : const Color(0xFFE0E7EF),
                      ),
                    );
                  }),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}

class _OngletHistorique extends StatelessWidget {
  const _OngletHistorique();

  @override
  Widget build(BuildContext context) {
    // Simule 30 jours d'historique
    final jours = List.generate(30, (i) {
      final date = DateTime.now().subtract(Duration(days: i));
      final estPris = i != 3 && i != 7 && i != 15 && i != 22;
      return {'date': date, 'pris': estPris};
    });

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [

        // Taux observance
        Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1565C0), Color(0xFF1976D2)],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Taux d\'observance',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '87%',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      '26 prises sur 30',
                      style: TextStyle(
                        color: Colors.white60,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.trending_up,
                color: Colors.white,
                size: 48,
              ),
            ],
          ),
        ),

        // Calendrier des 30 derniers jours
        const Text(
          'Historique des 30 derniers jours',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),

        const SizedBox(height: 12),

        // Grille des jours
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE0E7EF)),
          ),
          child: Column(
            children: [
              // Jours de la semaine
              Row(
                children: ['L', 'M', 'M', 'J', 'V', 'S', 'D']
                    .map((j) => Expanded(
                  child: Center(
                    child: Text(
                      j,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ))
                    .toList(),
              ),
              const SizedBox(height: 8),
              // Grille des jours
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  crossAxisSpacing: 4,
                  mainAxisSpacing: 4,
                ),
                itemCount: jours.length,
                itemBuilder: (context, index) {
                  final jour = jours[index];
                  final estPris = jour['pris'] as bool;
                  final date = jour['date'] as DateTime;

                  return Container(
                    decoration: BoxDecoration(
                      color: estPris
                          ? AppColors.primary
                          : const Color(0xFFFFCDD2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Center(
                      child: Text(
                        date.day.toString(),
                        style: TextStyle(
                          fontSize: 9,
                          color: estPris
                              ? Colors.white
                              : AppColors.danger,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 12),

              // Légende
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _legende(AppColors.primary, 'Pris'),
                  const SizedBox(width: 16),
                  _legende(const Color(0xFFFFCDD2), 'Manqué'),
                ],
              ),
            ],
          ),
        ),

      ],
    );
  }

  Widget _legende(Color couleur, String label) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: couleur,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}