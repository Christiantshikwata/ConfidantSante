import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../services/session_service.dart';

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

  // Getters
  int?    get patientId   => _patientId;
  String  get nom         => _nom;
  String  get numero      => _numero;
  double  get observance  => _observance;
  int     get joursActifs => _joursActifs;

  List<Map<String, dynamic>> get rappels     => _rappels;
  List<Map<String, dynamic>> get traitements => _traitements;
  List<Map<String, dynamic>> get historique  => _historique;

  // Charge toutes les données du patient depuis SQLite
  Future<void> chargerDonnees() async {
    final idStr = await SessionService().getPatientId();
    final nom   = await SessionService().getNom();
    final num   = await SessionService().getNumero();

    if (idStr == null) return;

    _patientId = int.tryParse(idStr);
    _nom       = nom ?? '';
    _numero    = num ?? '';

    if (_patientId == null) return;

    // Charge les rappels
    _rappels = await DatabaseService().getRappels(_patientId!);

    // Charge les traitements
    _traitements = await DatabaseService().getTraitements(_patientId!);

    // Calcule l'observance
    _observance = await DatabaseService().getTauxObservance(_patientId!);

    // Charge l'historique
    _historique = await DatabaseService().getHistorique30j(_patientId!);

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
    notifyListeners();
  }
}