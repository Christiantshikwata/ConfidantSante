import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'database_service.dart';
import 'session_service.dart';

class SyncService {

  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal();

  // Accès paresseux : ne touche Firestore que si Firebase est initialisé.
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  bool _syncEnCours = false;

  /// État de connexion réseau réel, observable par l'UI (badge « hors ligne »).
  final ValueNotifier<bool> enLigne = ValueNotifier<bool>(true);

  /// Vrai si une app Firebase a été initialisée (sinon on reste 100% local).
  bool get firebaseDisponible => Firebase.apps.isNotEmpty;

  /// Met à jour [enLigne] selon l'état réseau courant.
  Future<void> rafraichirEtatConnexion() async {
    enLigne.value = await _isConnecte();
  }

  // ── Vérifie si internet est disponible (connectivity_plus 6.x → List) ──────
  Future<bool> _isConnecte() async {
    final results = await Connectivity().checkConnectivity();
    return results.any((r) => r != ConnectivityResult.none);
  }

  // ── Point d'entrée principal ─────────────────────────────────────────────
  /// Lance la synchronisation si internet et Firebase sont disponibles.
  Future<SyncResult> synchroniser() async {
    if (!firebaseDisponible) {
      return SyncResult(succes: false, message: 'Firebase indisponible');
    }
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

      // Identité stable inter-appareils : le numéro de téléphone.
      final numero = await SessionService().getNumero();
      if (numero == null || numero.isEmpty) {
        return SyncResult(succes: false, message: 'Numéro patient introuvable');
      }

      await _syncProfil(patientId, numero);
      total += await _syncPrises(patientId, numero);
      // Récupère l'historique distant (restauration sur un nouvel appareil).
      total += await pullPrises(numero, patientId);
      total += await _syncRappels(patientId, numero);
      // Les rendez-vous sont désormais fixés par le médecin : le patient les
      // récupère (pull) au lieu de les pousser.
      total += await pullRendezVous(numero, patientId);

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
  Future<void> _syncProfil(int patientId, String numero) async {
    try {
      final db = DatabaseService();
      final patients = await db.database.then(
            (d) => d.query('patients', where: 'id = ?', whereArgs: [patientId]),
      );
      if (patients.isEmpty) return;

      final patient = patients.first;

      await _firestore
          .collection('patients')
          .doc(numero)
          .set({
        'nom':                patient['nom'],
        'numero':             patient['numero'],
        'soignant':           patient['soignant'],
        'soignant_matricule': patient['soignant_matricule'],
        'hopital':            patient['hopital'],
        'date_creation':      patient['date_creation'],
        'derniere_sync':      FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      debugPrint('[SyncService] Profil patient synchronisé');
    } catch (e) {
      debugPrint('[SyncService] Erreur profil : $e');
    }
  }

  // ── 2. Prises (priorité haute — observance) ───────────────────────────────
  Future<int> _syncPrises(int patientId, String numero) async {
    int count = 0;
    try {
      final db = DatabaseService();
      final dbInstance = await db.database;

      final prises = await dbInstance.query(
        'prises',
        where: 'patient_id = ? AND synchronise = 0',
        whereArgs: [patientId],
      );

      for (final prise in prises) {
        final localId = prise['id'].toString();
        // Identifiant stable (protocole + jour) : même prise = même document,
        // d'un appareil à l'autre. À défaut (anciennes lignes), l'id local.
        final remoteId = (prise['remote_id'] as String?)?.isNotEmpty == true
            ? prise['remote_id'] as String
            : localId;

        // remote_id du protocole (via le rappel) pour relier la prise au bon
        // rappel lors d'une restauration sur un nouvel appareil.
        String? traitementRemoteId;
        final rappelId = prise['traitement_id'];
        if (rappelId != null) {
          final r = await dbInstance.query(
            'rappels',
            columns: ['remote_id'],
            where: 'id = ?',
            whereArgs: [rappelId],
            limit: 1,
          );
          if (r.isNotEmpty) {
            traitementRemoteId = r.first['remote_id'] as String?;
          }
        }

        await _firestore
            .collection('patients')
            .doc(numero)
            .collection('prises')
            .doc(remoteId)
            .set({
          'traitement_id':        prise['traitement_id'],
          'traitement_remote_id': traitementRemoteId,
          'remote_id':            remoteId,
          'date_heure':           prise['date_heure'],
          'statut':               prise['statut'],
          'sync_at':              FieldValue.serverTimestamp(),
        });

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
  Future<int> _syncRappels(int patientId, String numero) async {
    int count = 0;
    try {
      final rappels = await DatabaseService().getRappels(patientId);
      if (rappels.isEmpty) return 0;

      final rappelsData = rappels.map((r) => {
        'id':             r['id'],
        'nom_medicament': r['nom_medicament'],
        'dosage':         r['dosage'],
        'heure':          r['heure'],
        'est_actif':      r['est_actif'],
      }).toList();

      await _firestore
          .collection('patients')
          .doc(numero)
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

  // ── 4. Rendez-vous (médecin → Firestore → patient) ─────────────────────────

  /// Médecin : pousse vers Firestore un rendez-vous fixé pour un patient.
  Future<void> pousserRendezVous({
    required String numero,
    required String idLocal,
    required String motif,
    required String lieu,
    required String date,
    String? statut,
    String? soignantMatricule,
  }) async {
    if (!firebaseDisponible) return;
    try {
      await _firestore
          .collection('patients')
          .doc(numero)
          .collection('rendez_vous')
          .doc(idLocal)
          .set({
        'motif':              motif,
        'lieu':               lieu,
        'date':               date,
        'statut':             statut ?? 'planifie',
        'soignant_matricule': soignantMatricule,
        'cree_le':            FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('[SyncService] Erreur pousserRendezVous : $e');
    }
  }

  /// Patient : récupère depuis Firestore les rendez-vous fixés par le médecin
  /// et les enregistre localement (sans doublon). Retourne le nombre traité.
  Future<int> pullRendezVous(String numero, int patientId) async {
    if (!firebaseDisponible) return 0;
    int count = 0;
    try {
      final snap = await _firestore
          .collection('patients')
          .doc(numero)
          .collection('rendez_vous')
          .get();
      for (final doc in snap.docs) {
        final d = doc.data();
        await DatabaseService().upsertRendezVousDepuisFirestore(
          patientId:         patientId,
          remoteId:          doc.id,
          motif:             d['motif'] as String? ?? '',
          lieu:              d['lieu'] as String? ?? '',
          date:              d['date'] as String? ?? '',
          statut:            d['statut'] as String?,
          soignantMatricule: d['soignant_matricule'] as String?,
        );
        count++;
      }
    } catch (e) {
      debugPrint('[SyncService] Erreur pullRendezVous : $e');
    }
    return count;
  }

  // ── Écoute la connectivité et sync automatiquement ────────────────────────
  /// À appeler une fois dans main.dart ou après le login.
  void ecouterConnectivite() {
    // Initialise l'état courant puis suit les changements (même sans Firebase :
    // le badge « hors ligne » doit rester juste).
    rafraichirEtatConnexion();
    Connectivity().onConnectivityChanged.listen((results) {
      final connecte = results.any((r) => r != ConnectivityResult.none);
      enLigne.value = connecte;
      if (connecte && firebaseDisponible) {
        debugPrint('[SyncService] Connexion détectée → synchronisation auto');
        synchroniser();
      }
    });
  }

  // ── Comptes patients (médecin → Firestore → patient) ───────────────────────

  /// Médecin : pousse le profil patient vers Firestore (l'authentification est
  /// gérée par Firebase Auth — aucun mot de passe n'est stocké dans Firestore).
  Future<void> pousserComptePatient({
    required String numero,
    required String nom,
    String? uid,
    String? soignant,
    String? soignantMatricule,
    String? hopital,
    String? adresse,
    String? genre,
    String? tauxSerologique,
    String? contactUrgenceNom,
    String? contactUrgenceTel,
  }) async {
    if (!firebaseDisponible) return;
    try {
      await _firestore.collection('patients').doc(numero).set({
        'nom':                 nom,
        'numero':              numero,
        if (uid != null) 'uid': uid,
        'role':                'patient',
        'soignant':            soignant,
        'soignant_matricule':  soignantMatricule,
        'hopital':             hopital,
        'adresse':             adresse,
        'genre':               genre,
        'taux_serologique':    tauxSerologique,
        'contact_urgence_nom': contactUrgenceNom,
        'contact_urgence_tel': contactUrgenceTel,
        'compte_cree':         FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('[SyncService] Erreur pousserComptePatient : $e');
    }
  }

  /// Met à jour le médecin référent d'un patient dans Firestore (migration).
  Future<void> mettreAJourSoignantPatient({
    required String numero,
    required String matricule,
    String? nomSoignant,
  }) async {
    if (!firebaseDisponible) return;
    try {
      await _firestore.collection('patients').doc(numero).set({
        'soignant_matricule': matricule,
        if (nomSoignant != null) 'soignant': nomSoignant,
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('[SyncService] Erreur mettreAJourSoignantPatient : $e');
    }
  }

  /// Admin : pousse le profil d'un médecin vers Firestore (l'authentification
  /// est gérée par Firebase Auth — aucun mot de passe n'est stocké ici).
  Future<void> pousserCompteSoignant({
    required String matricule,
    required String nom,
    String? uid,
    String? specialite,
  }) async {
    if (!firebaseDisponible) return;
    try {
      await _firestore.collection('soignants').doc(matricule).set({
        'matricule':  matricule,
        'nom':        nom,
        if (uid != null) 'uid': uid,
        'specialite': specialite,
        'cree_le':    FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('[SyncService] Erreur pousserCompteSoignant : $e');
    }
  }

  /// Médecin : récupère son compte depuis Firestore (première connexion).
  Future<Map<String, dynamic>?> recupererCompteSoignant(
      String matricule) async {
    if (!firebaseDisponible) return null;
    try {
      final doc =
          await _firestore.collection('soignants').doc(matricule).get();
      if (!doc.exists) return null;
      return doc.data();
    } catch (e) {
      debugPrint('[SyncService] Erreur recupererCompteSoignant : $e');
      return null;
    }
  }

  /// Médecin : récupère depuis Firestore les patients qui lui sont rattachés
  /// (création ou migration) et les enregistre localement.
  Future<void> pullPatientsDuSoignant(String matricule) async {
    if (!firebaseDisponible) return;
    try {
      final snap = await _firestore
          .collection('patients')
          .where('soignant_matricule', isEqualTo: matricule)
          .get();
      for (final doc in snap.docs) {
        final d = doc.data();
        await DatabaseService().upsertPatientDepuisFirestore(
          numero:            d['numero'] as String? ?? doc.id,
          nom:               d['nom'] as String? ?? '',
          soignant:          d['soignant'] as String?,
          soignantMatricule: d['soignant_matricule'] as String?,
          hopital:           d['hopital'] as String?,
          adresse:           d['adresse'] as String?,
          genre:             d['genre'] as String?,
          tauxSerologique:   d['taux_serologique'] as String?,
          contactUrgenceNom: d['contact_urgence_nom'] as String?,
          contactUrgenceTel: d['contact_urgence_tel'] as String?,
        );
      }
    } catch (e) {
      debugPrint('[SyncService] Erreur pullPatientsDuSoignant : $e');
    }
  }

  /// Admin : récupère TOUS les patients depuis Firestore et les enregistre
  /// localement. Indispensable après une réinstallation ou sur un nouvel
  /// appareil : l'administrateur (médecin de démonstration) lit la liste
  /// complète, qui n'existe plus en local tant qu'elle n'a pas été rapatriée.
  Future<void> pullTousPatients() async {
    if (!firebaseDisponible) return;
    try {
      final snap = await _firestore.collection('patients').get();
      for (final doc in snap.docs) {
        final d = doc.data();
        // Ignore d'éventuels documents qui ne sont pas des patients.
        if (d['role'] != null && d['role'] != 'patient') continue;
        await DatabaseService().upsertPatientDepuisFirestore(
          numero:            d['numero'] as String? ?? doc.id,
          nom:               d['nom'] as String? ?? '',
          soignant:          d['soignant'] as String?,
          soignantMatricule: d['soignant_matricule'] as String?,
          hopital:           d['hopital'] as String?,
          adresse:           d['adresse'] as String?,
          genre:             d['genre'] as String?,
          tauxSerologique:   d['taux_serologique'] as String?,
          contactUrgenceNom: d['contact_urgence_nom'] as String?,
          contactUrgenceTel: d['contact_urgence_tel'] as String?,
        );
      }
    } catch (e) {
      debugPrint('[SyncService] Erreur pullTousPatients : $e');
    }
  }

  /// Patient : récupère le compte (profil + hash) depuis Firestore, s'il existe.
  Future<Map<String, dynamic>?> recupererComptePatient(String numero) async {
    if (!firebaseDisponible) return null;
    try {
      final doc =
          await _firestore.collection('patients').doc(numero).get();
      if (!doc.exists) return null;
      return doc.data();
    } catch (e) {
      debugPrint('[SyncService] Erreur recupererComptePatient : $e');
      return null;
    }
  }

  // ── Protocoles (médecin → patient) ─────────────────────────────────────────

  /// Médecin : pousse un protocole vers Firestore (sous le numéro du patient).
  Future<void> pousserProtocole({
    required String numero,
    required String idLocal,
    required String nomMedicament,
    required String dosage,
    String? dateDebut,
    String? dateFin,
    int? dureeMois,
    String? soignantMatricule,
  }) async {
    if (!firebaseDisponible) return;
    try {
      await _firestore
          .collection('patients')
          .doc(numero)
          .collection('traitements')
          .doc(idLocal)
          .set({
        'nom_medicament':     nomMedicament,
        'dosage':             dosage,
        'date_debut':         dateDebut,
        'date_fin':           dateFin,
        'duree_mois':         dureeMois,
        'soignant_matricule': soignantMatricule,
        'created_at':         FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('[SyncService] Erreur pousserProtocole : $e');
    }
  }

  /// Patient : récupère les protocoles attribués depuis Firestore et les
  /// enregistre localement (sans doublon).
  Future<void> pullProtocoles(String numero, int patientId) async {
    if (!firebaseDisponible) return;
    try {
      final snap = await _firestore
          .collection('patients')
          .doc(numero)
          .collection('traitements')
          .get();
      for (final doc in snap.docs) {
        final d = doc.data();
        await DatabaseService().upsertProtocoleDepuisFirestore(
          patientId:     patientId,
          remoteId:      doc.id,
          nomMedicament: d['nom_medicament'] as String? ?? '',
          dosage:        d['dosage'] as String? ?? '',
          dateDebut:     d['date_debut'] as String?,
          dateFin:       d['date_fin'] as String?,
          dureeMois:     d['duree_mois'] as int?,
          heure:         d['heure'] as String?,
        );
      }
    } catch (e) {
      debugPrint('[SyncService] Erreur pullProtocoles : $e');
    }
  }

  /// Patient : enregistre dans Firestore l'heure de prise qu'il a choisie pour
  /// un protocole. Elle est ainsi rétablie automatiquement sur ses autres
  /// appareils (le rappel et la notification sont recréés au prochain chargement).
  Future<void> pousserHeureProtocole({
    required String numero,
    required String remoteId,
    required String heure,
  }) async {
    if (!firebaseDisponible) return;
    try {
      await _firestore
          .collection('patients')
          .doc(numero)
          .collection('traitements')
          .doc(remoteId)
          .set({'heure': heure}, SetOptions(merge: true));
    } catch (e) {
      debugPrint('[SyncService] Erreur pousserHeureProtocole : $e');
    }
  }

  /// Patient : récupère l'historique des prises depuis Firestore et le restaure
  /// localement (sans doublon). Indispensable sur un nouvel appareil pour
  /// retrouver l'observance et l'historique. Retourne le nombre de prises lues.
  Future<int> pullPrises(String numero, int patientId) async {
    if (!firebaseDisponible) return 0;
    int count = 0;
    try {
      final snap = await _firestore
          .collection('patients')
          .doc(numero)
          .collection('prises')
          .get();
      for (final doc in snap.docs) {
        final d = doc.data();
        await DatabaseService().upsertPriseDepuisFirestore(
          patientId:          patientId,
          remoteId:           (d['remote_id'] as String?) ?? doc.id,
          traitementRemoteId: d['traitement_remote_id'] as String?,
          dateHeure:          d['date_heure'] as String? ?? '',
          statut:             d['statut'] as String? ?? 'pris',
        );
        count++;
      }
    } catch (e) {
      debugPrint('[SyncService] Erreur pullPrises : $e');
    }
    return count;
  }

  // ── Observance depuis Firestore (pour le soignant), par numéro patient ─────
  Future<double?> getObservanceFirestore(String numero) async {
    if (!firebaseDisponible) return null;
    try {
      final snapshot = await _firestore
          .collection('patients')
          .doc(numero)
          .collection('prises')
          .get();

      if (snapshot.docs.isEmpty) return null;

      final total = snapshot.docs.length;
      final prises = snapshot.docs
          .where((d) => d.data()['statut'] == 'pris')
          .length;

      return (prises / total) * 100;
    } catch (e) {
      return null;
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
