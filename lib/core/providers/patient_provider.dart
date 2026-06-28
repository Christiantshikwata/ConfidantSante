import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../services/session_service.dart';
import '../services/sync_service.dart';
import '../services/notification_service.dart';

// Ce provider gère toutes les données du patient connecté
// Il est accessible depuis n'importe quel écran
class PatientProvider extends ChangeNotifier {

  // Données du patient
  int?    _patientId;
  String  _nom          = '';
  String  _numero       = '';
  double  _observance   = 0.0;
  int     _joursActifs  = 0;

  // Rappels du jour
  List<Map<String, dynamic>> _rappels    = [];
  List<Map<String, dynamic>> _traitements = [];
  List<Map<String, dynamic>> _historique  = [];

  // Protocoles attribués par le médecin, en attente de définition d'heure
  List<Map<String, dynamic>> _protocoles = [];

  // Ids des rappels déjà pris aujourd'hui
  Set<int> _prisAujourdhui = {};

  // Indique qu'un chargement des données est en cours (spinner UI).
  bool _chargement = false;

  // Getters
  int?    get patientId   => _patientId;
  String  get nom         => _nom;
  String  get numero      => _numero;
  double  get observance  => _observance;
  int     get joursActifs => _joursActifs;

  List<Map<String, dynamic>> get rappels     => _rappels;
  List<Map<String, dynamic>> get traitements => _traitements;
  List<Map<String, dynamic>> get historique  => _historique;
  List<Map<String, dynamic>> get protocolesAConfigurer => _protocoles;
  Set<int> get prisAujourdhui => _prisAujourdhui;
  bool get chargement => _chargement;

  /// Indique si un rappel a déjà été marqué pris aujourd'hui.
  bool estPrisAujourdhui(int rappelId) => _prisAujourdhui.contains(rappelId);

  Map<String, dynamic>? get _protocoleActif =>
      _traitements.isNotEmpty ? _traitements.first : null;

  /// Durée totale (en jours) du protocole en cours, ou 0 si aucun.
  int get protocoleDureeJours {
    final t = _protocoleActif;
    if (t == null) return 0;
    final debut = DateTime.tryParse(t['date_debut'] as String? ?? '');
    final fin = DateTime.tryParse(t['date_fin'] as String? ?? '');
    if (debut == null || fin == null) return 0;
    return fin.difference(debut).inDays;
  }

  /// Nombre de jours restants avant la fin du protocole (jamais négatif).
  int get protocoleJoursRestants {
    final t = _protocoleActif;
    if (t == null) return 0;
    final fin = DateTime.tryParse(t['date_fin'] as String? ?? '');
    if (fin == null) return 0;
    final r = fin.difference(DateTime.now()).inDays;
    return r < 0 ? 0 : r;
  }

  // Charge toutes les données du patient depuis SQLite
  Future<void> chargerDonnees() async {
    _chargement = true;
    notifyListeners();
    try {
      await _chargerDonneesInterne();
    } finally {
      _chargement = false;
      notifyListeners();
    }
  }

  Future<void> _chargerDonneesInterne() async {
    final idStr = await SessionService().getPatientId();
    final nom   = await SessionService().getNom();
    final num   = await SessionService().getNumero();

    if (idStr == null) return;

    _patientId = int.tryParse(idStr);
    _nom       = nom ?? '';
    _numero    = num ?? '';

    if (_patientId == null) return;

    // Enregistre les doses manquées des jours écoulés (réconciliation) —
    // avant de désactiver les rappels expirés, pour couvrir toute la durée.
    await DatabaseService().reconcilierPrisesManquees(_patientId!);

    // Désactive et annule les rappels dont le protocole est terminé
    final expires = await DatabaseService().desactiverRappelsExpires(_patientId!);
    for (final id in expires) {
      await NotificationService().annulerRappel(id);
    }

    // Charge les rappels
    _rappels = await DatabaseService().getRappels(_patientId!);

    // Charge les traitements
    _traitements = await DatabaseService().getTraitements(_patientId!);

    // Récupère les protocoles et les rendez-vous fixés par le médecin
    // (Firestore → local).
    if (_numero.isNotEmpty) {
      await SyncService().pullProtocoles(_numero, _patientId!);
      await SyncService().pullRendezVous(_numero, _patientId!);
    }

    // Protocoles attribués par le médecin, en attente d'une heure
    _protocoles = await DatabaseService().getProtocolesAConfigurer(_patientId!);

    // Calcule l'observance
    _observance = await DatabaseService().getTauxObservance(_patientId!);

    // Charge l'historique
    _historique = await DatabaseService().getHistorique30j(_patientId!);

    // Prises déjà effectuées aujourd'hui
    _prisAujourdhui =
        await DatabaseService().getPrisesIdsAujourdhui(_patientId!);

    // Calcule les jours actifs
    _joursActifs = _historique
        .where((p) => p['statut'] == 'pris')
        .length;

    notifyListeners();
  }

  // Ajoute un rappel et recharge
  Future<void> ajouterRappel({
    required String nomMedicament,
    required String dosage,
    required String heure,
  }) async {
    if (_patientId == null) return;

    await DatabaseService().ajouterRappel(
      patientId:      _patientId!,
      nomMedicament:  nomMedicament,
      dosage:         dosage,
      heure:          heure,
    );

    await chargerDonnees();
  }

  // Confirme une prise
  Future<void> confirmerPrise(int traitementId) async {
    if (_patientId == null) return;

    await DatabaseService().enregistrerPrise(
      traitementId: traitementId,
      patientId:    _patientId!,
      statut:       'pris',
    );
    SyncService().synchroniser();
    await chargerDonnees();
  }

  // Le patient fixe l'heure d'un protocole : crée le rappel quotidien et
  // programme la notification jusqu'à la fin du protocole.
  Future<void> definirHeureProtocole(
    Map<String, dynamic> protocole,
    String heure,
  ) async {
    if (_patientId == null) return;

    final nom    = protocole['nom_medicament'] as String? ?? '';
    final dosage = protocole['dosage'] as String? ?? '';

    final rappelId = await DatabaseService().definirHeureProtocole(
      traitementId:  protocole['id'] as int,
      patientId:     _patientId!,
      nomMedicament: nom,
      dosage:        dosage,
      heure:         heure,
      dateFin:       protocole['date_fin'] as String?,
    );

    await NotificationService().programmerDepuisTexte(
      id:            rappelId,
      nomMedicament: nom,
      dosage:        dosage,
      heureTexte:    heure,
    );

    await chargerDonnees();
  }

  // Réinitialise les données à la déconnexion
  void reinitialiser() {
    _patientId   = null;
    _nom         = '';
    _numero      = '';
    _observance  = 0.0;
    _joursActifs = 0;
    _rappels     = [];
    _traitements = [];
    _historique  = [];
    _protocoles  = [];
    notifyListeners();
  }
}