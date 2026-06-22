import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import '../../firebase_options.dart';

/// Authentification via Firebase Auth.
///
/// Choix de conception (mémoire UDBL) :
///  - Le patient s'identifie par son numéro de téléphone (9 chiffres) et le
///    soignant par son matricule. Firebase Auth n'accepte que des e-mails, donc
///    on dérive un « email-alias » interne (aucun SMS, aucun e-mail réel) :
///       patient   →  p<numero>@confidantsante.app
///       soignant  →  <matricule en minuscules>@confidantsante.app
///  - Le rôle (patient / soignant / admin) est stocké dans Firestore sous
///    users/{uid}. Les règles de sécurité s'appuient dessus (pas de Cloud
///    Functions / custom claims, compatible plan gratuit).
///  - Créer un compte côté client connecte automatiquement le nouvel
///    utilisateur. Pour que le médecin (ou l'admin) puisse créer un compte sans
///    perdre sa propre session, on passe par une app Firebase SECONDAIRE.
class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  static const String domaine = 'confidantsante.app';
  static const String adminMatricule = 'MED-2024-001';
  static const String adminMotDePasseDemo = 'soignant123';
  static const String adminNomDemo = 'Dr. Yves Ndetereyuwe';

  FirebaseAuth get _auth => FirebaseAuth.instance;
  FirebaseFirestore get _db => FirebaseFirestore.instance;

  /// Vrai si Firebase a bien été initialisé (sinon l'app reste 100 % locale).
  bool get disponible => Firebase.apps.isNotEmpty;

  User? get utilisateurCourant => disponible ? _auth.currentUser : null;
  bool get estConnecte => utilisateurCourant != null;
  String? get uidCourant => utilisateurCourant?.uid;

  // ── Email-alias ────────────────────────────────────────────────────────────
  static String emailPatient(String numero) => 'p$numero@$domaine';
  static String emailSoignant(String matricule) =>
      '${matricule.trim().toLowerCase()}@$domaine';

  // ── PATIENT : inscription (auto-inscription depuis l'écran patient) ─────────
  Future<AuthResultat> inscrirePatient({
    required String numero,
    required String motDePasse,
    required String nom,
  }) async {
    if (!disponible) return AuthResultat.echec('auth_err_indispo');
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: emailPatient(numero),
        password: motDePasse,
      );
      final uid = cred.user!.uid;
      // 1) Doc rôle (lisible par les règles) — créé par l'utilisateur lui-même.
      await _db.collection('users').doc(uid).set({
        'role': 'patient',
        'numero': numero,
        'cree_le': FieldValue.serverTimestamp(),
      });
      // 2) Doc métier patient.
      await _db.collection('patients').doc(numero).set({
        'nom': nom,
        'numero': numero,
        'uid': uid,
        'role': 'patient',
        'compte_cree': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      return AuthResultat.succes(uid);
    } on FirebaseAuthException catch (e) {
      return AuthResultat.echec(_cleErreur(e));
    } catch (e) {
      debugPrint('[AuthService] inscrirePatient: $e');
      return AuthResultat.echec('auth_err_generique');
    }
  }

  // ── PATIENT : connexion ─────────────────────────────────────────────────────
  Future<AuthResultat> connecterPatient({
    required String numero,
    required String motDePasse,
  }) async {
    if (!disponible) return AuthResultat.echec('auth_err_indispo');
    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: emailPatient(numero),
        password: motDePasse,
      );
      final uid = cred.user!.uid;
      // Assure le doc rôle (cas d'un patient créé par le médecin : son doc
      // users/{uid} n'existe pas encore car le médecin ne pouvait pas l'écrire).
      await _db.collection('users').doc(uid).set({
        'role': 'patient',
        'numero': numero,
      }, SetOptions(merge: true));
      return AuthResultat.succes(uid);
    } on FirebaseAuthException catch (e) {
      return AuthResultat.echec(_cleErreur(e));
    } catch (e) {
      debugPrint('[AuthService] connecterPatient: $e');
      return AuthResultat.echec('auth_err_generique');
    }
  }

  // ── SOIGNANT : connexion (avec amorçage du compte admin de démonstration) ───
  Future<AuthResultat> connecterSoignant({
    required String matricule,
    required String motDePasse,
  }) async {
    if (!disponible) return AuthResultat.echec('auth_err_indispo');
    final email = emailSoignant(matricule);
    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: email,
        password: motDePasse,
      );
      final uid = cred.user!.uid;
      await _db.collection('users').doc(uid).set({
        'role': matricule == adminMatricule ? 'admin' : 'soignant',
        'matricule': matricule,
      }, SetOptions(merge: true));
      return AuthResultat.succes(uid);
    } on FirebaseAuthException catch (e) {
      // Premier lancement : on amorce le compte admin de démonstration.
      final inexistant =
          e.code == 'user-not-found' || e.code == 'invalid-credential';
      if (inexistant &&
          matricule == adminMatricule &&
          motDePasse == adminMotDePasseDemo) {
        return _amorcerAdminDemo(email, motDePasse);
      }
      return AuthResultat.echec(_cleErreur(e));
    } catch (e) {
      debugPrint('[AuthService] connecterSoignant: $e');
      return AuthResultat.echec('auth_err_generique');
    }
  }

  Future<AuthResultat> _amorcerAdminDemo(String email, String mdp) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: mdp,
      );
      final uid = cred.user!.uid;
      await _db.collection('users').doc(uid).set({
        'role': 'admin',
        'matricule': adminMatricule,
        'cree_le': FieldValue.serverTimestamp(),
      });
      await _db.collection('soignants').doc(adminMatricule).set({
        'matricule': adminMatricule,
        'nom': adminNomDemo,
        'specialite': 'Médecin infectiologue',
        'uid': uid,
        'cree_le': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      return AuthResultat.succes(uid);
    } on FirebaseAuthException catch (e) {
      return AuthResultat.echec(_cleErreur(e));
    } catch (e) {
      debugPrint('[AuthService] amorcerAdminDemo: $e');
      return AuthResultat.echec('auth_err_generique');
    }
  }

  // ── Création d'un compte PAR un autre utilisateur (médecin / admin) ─────────
  /// Crée l'utilisateur Firebase Auth + son doc users/{uid} via une app
  /// secondaire, pour préserver la session du créateur. Le doc métier
  /// (patients/{numero} ou soignants/{matricule}) est écrit ensuite par
  /// l'appelant, depuis sa propre session (autorisé par les règles).
  Future<AuthResultat> creerUtilisateurSecondaire({
    required String email,
    required String motDePasse,
    required String role, // 'patient' | 'soignant'
    String? numero,
    String? matricule,
  }) async {
    if (!disponible) return AuthResultat.echec('auth_err_indispo');
    FirebaseApp? secondaire;
    try {
      secondaire = await Firebase.initializeApp(
        name: 'creator_${DateTime.now().microsecondsSinceEpoch}',
        options: DefaultFirebaseOptions.currentPlatform,
      );
      final authSec = FirebaseAuth.instanceFor(app: secondaire);
      final cred = await authSec.createUserWithEmailAndPassword(
        email: email,
        password: motDePasse,
      );
      final uid = cred.user!.uid;
      // Écrit depuis la session du NOUVEL utilisateur (autorisé : self).
      final dbSec = FirebaseFirestore.instanceFor(app: secondaire);
      await dbSec.collection('users').doc(uid).set({
        'role': role,
        if (numero != null) 'numero': numero,
        if (matricule != null) 'matricule': matricule,
        'cree_le': FieldValue.serverTimestamp(),
      });
      await authSec.signOut();
      return AuthResultat.succes(uid);
    } on FirebaseAuthException catch (e) {
      return AuthResultat.echec(_cleErreur(e));
    } catch (e) {
      debugPrint('[AuthService] creerUtilisateurSecondaire: $e');
      return AuthResultat.echec('auth_err_generique');
    } finally {
      if (secondaire != null) {
        try {
          await secondaire.delete();
        } catch (_) {}
      }
    }
  }

  /// Vérifie le mot de passe du patient courant (utilisé pour réinitialiser le
  /// PIN). Re-connecter le même utilisateur est sans effet de bord.
  Future<bool> verifierMotDePassePatient({
    required String numero,
    required String motDePasse,
  }) async {
    if (!disponible) return false;
    try {
      await _auth.signInWithEmailAndPassword(
        email: emailPatient(numero),
        password: motDePasse,
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> deconnecter() async {
    if (disponible) {
      try {
        await _auth.signOut();
      } catch (_) {}
    }
  }

  // ── Traduction des codes d'erreur Firebase → clés i18n ──────────────────────
  String _cleErreur(FirebaseAuthException e) {
    // Trace le code exact dans la console (diagnostic). Ex. operation-not-allowed
    // = fournisseur E-mail/Mot de passe non activé dans la console Firebase.
    debugPrint('[AuthService] FirebaseAuthException code=${e.code} message=${e.message}');
    switch (e.code) {
      case 'wrong-password':
      case 'invalid-credential':
        return 'auth_err_mdp';
      case 'user-not-found':
        return 'auth_err_introuvable';
      case 'email-already-in-use':
        return 'auth_err_existe';
      case 'network-request-failed':
        return 'auth_err_reseau';
      case 'weak-password':
        return 'auth_err_faible';
      default:
        return 'auth_err_generique';
    }
  }
}

/// Résultat d'une opération d'authentification. En cas d'échec, [messageCle]
/// est une clé du dictionnaire AppTranslations.
class AuthResultat {
  final bool succes;
  final String? uid;
  final String? messageCle;

  const AuthResultat._({required this.succes, this.uid, this.messageCle});

  factory AuthResultat.succes(String uid) =>
      AuthResultat._(succes: true, uid: uid);
  factory AuthResultat.echec(String messageCle) =>
      AuthResultat._(succes: false, messageCle: messageCle);
}
