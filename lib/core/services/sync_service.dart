import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'database_service.dart';
import 'session_service.dart';

class SyncService {

  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _syncEnCours = false;

  // ── Vérifie si internet est disponible ───────────────────────────────────
  Future<bool> _isConnecte() async {
    final result = await Connectivity().checkConnectivity();
    return result != ConnectivityResult.none;
  }

  // ── Point d'entrée principal ─────────────────────────────────────────────
  /// Lance la synchronisation si internet est disponible
  Future<SyncResult> synchroniser() async {
    if (_syncEnCours) {
      return SyncResult(succes: false, message: 'Synchronisation déjà en cours');
    }

    final connecte = await _isConnecte();
    if (!connecte) {
      return SyncResult(succes: false, message: 'Pas de connexion internet');
    }

    _syncEnCours = true;
    int total = 0;

    try {
      final idStr = await SessionService().getPatientId();
      if (idStr == null) {
        return SyncResult(succes: false, message: 'Aucun patient connecté');
      }
      final patientId = int.tryParse(idStr);
      if (patientId == null) {
        return SyncResult(succes: false, message: 'ID patient invalide');
      }

      // 1. Synchronise le profil patient
      await _syncProfil(patientId);

      // 2. Synchronise les prises non envoyées
      final prisesSynced = await _syncPrises(patientId);
      total += prisesSynced;

      // 3. Synchronise les rappels
      final rappelsSynced = await _syncRappels(patientId);
      total += rappelsSynced;

      // 4. Synchronise les rendez-vous
      final rdvSynced = await _syncRendezVous(patientId);
      total += rdvSynced;

      debugPrint('[SyncService] ✓ $total éléments synchronisés');

      return SyncResult(
        succes: true,
        message: '$total élément${total > 1 ? 's' : ''} synchronisé${total > 1 ? 's' : ''}',
        nbElements: total,
      );

    } catch (e) {
      debugPrint('[SyncService] Erreur : $e');
      return SyncResult(succes: false, message: 'Erreur : ${e.toString()}');
    } finally {
      _syncEnCours = false;
    }
  }

  // ── 1. Profil patient ─────────────────────────────────────────────────────
  Future<void> _syncProfil(int patientId) async {
    try {
      final db = DatabaseService();
      final patients = await db.database.then(
            (d) => d.query('patients', where: 'id = ?', whereArgs: [patientId]),
      );
      if (patients.isEmpty) return;

      final patient = patients.first;

      await _firestore
          .collection('patients')
          .doc(patientId.toString())
          .set({
        'nom':          patient['nom'],
        'numero':       patient['numero'],
        'soignant':     patient['soignant'],
        'hopital':      patient['hopital'],
        'date_creation': patient['date_creation'],
        'derniere_sync': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      debugPrint('[SyncService] Profil patient synchronisé');
    } catch (e) {
      debugPrint('[SyncService] Erreur profil : $e');
    }
  }

  // ── 2. Prises (priorité haute — observance) ───────────────────────────────
  Future<int> _syncPrises(int patientId) async {
    int count = 0;
    try {
      final db = DatabaseService();
      final dbInstance = await db.database;

      // Récupère toutes les prises non synchronisées
      final prises = await dbInstance.query(
        'prises',
        where: 'patient_id = ? AND synchronise = 0',
        whereArgs: [patientId],
      );

      for (final prise in prises) {
        final priseId = prise['id'].toString();

        await _firestore
            .collection('patients')
            .doc(patientId.toString())
            .collection('prises')
            .doc(priseId)
            .set({
          'traitement_id': prise['traitement_id'],
          'patient_id':    prise['patient_id'],
          'date_heure':    prise['date_heure'],
          'statut':        prise['statut'],
          'sync_at':       FieldValue.serverTimestamp(),
        });

        // Marque comme synchronisée dans SQLite
        await dbInstance.update(
          'prises',
          {'synchronise': 1},
          where: 'id = ?',
          whereArgs: [prise['id']],
        );

        count++;
      }

      if (count > 0) {
        debugPrint('[SyncService] $count prise(s) synchronisée(s)');
      }
    } catch (e) {
      debugPrint('[SyncService] Erreur prises : $e');
    }
    return count;
  }

  // ── 3. Rappels ────────────────────────────────────────────────────────────
  Future<int> _syncRappels(int patientId) async {
    int count = 0;
    try {
      final rappels = await DatabaseService().getRappels(patientId);

      if (rappels.isEmpty) return 0;

      // Envoie tous les rappels actifs en un seul document
      final rappelsData = rappels.map((r) => {
        'id':             r['id'],
        'nom_medicament': r['nom_medicament'],
        'dosage':         r['dosage'],
        'heure':          r['heure'],
        'est_actif':      r['est_actif'],
      }).toList();

      await _firestore
          .collection('patients')
          .doc(patientId.toString())
          .set({
        'rappels':      rappelsData,
        'rappels_sync': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      count = rappels.length;
      debugPrint('[SyncService] $count rappel(s) synchronisé(s)');
    } catch (e) {
      debugPrint('[SyncService] Erreur rappels : $e');
    }
    return count;
  }

  // ── 4. Rendez-vous ────────────────────────────────────────────────────────
  Future<int> _syncRendezVous(int patientId) async {
    int count = 0;
    try {
      final rdvs = await DatabaseService().getRendezVous(patientId);

      if (rdvs.isEmpty) return 0;

      for (final rdv in rdvs) {
        await _firestore
            .collection('patients')
            .doc(patientId.toString())
            .collection('rendez_vous')
            .doc(rdv['id'].toString())
            .set({
          'motif':   rdv['motif'],
          'lieu':    rdv['lieu'],
          'date':    rdv['date'],
          'statut':  rdv['statut'],
          'sync_at': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        count++;
      }

      debugPrint('[SyncService] $count rendez-vous synchronisé(s)');
    } catch (e) {
      debugPrint('[SyncService] Erreur rendez-vous : $e');
    }
    return count;
  }

  // ── Écoute la connectivité et sync automatiquement ────────────────────────
  /// À appeler une fois dans main.dart ou après le login
  void ecouterConnectivite() {
    Connectivity().onConnectivityChanged.listen((result) {
      if (result != ConnectivityResult.none) {
        debugPrint('[SyncService] Connexion détectée → synchronisation auto');
        synchroniser();
      }
    });
  }

  // ── Calcule l'observance depuis Firestore (pour le soignant) ─────────────
  Future<double> getObservanceFirestore(String patientId) async {
    try {
      final snapshot = await _firestore
          .collection('patients')
          .doc(patientId)
          .collection('prises')
          .get();

      if (snapshot.docs.isEmpty) return 0.0;

      final total = snapshot.docs.length;
      final prises = snapshot.docs
          .where((d) => d.data()['statut'] == 'pris')
          .length;

      return (prises / total) * 100;
    } catch (e) {
      return 0.0;
    }
  }
}

// ── Résultat de synchronisation ───────────────────────────────────────────────
class SyncResult {
  final bool succes;
  final String message;
  final int nbElements;

  const SyncResult({
    required this.succes,
    required this.message,
    this.nbElements = 0,
  });
}