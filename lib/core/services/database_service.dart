import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'password_service.dart';

class DatabaseService {

  // Singleton — une seule instance dans toute l'app
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  Database? _db;

  // Matricule du soignant de démonstration (identité stable).
  static const String soignantDemoMatricule = 'MED-2024-001';

  // Ouvre la base de données
  Future<Database> get database async {
    _db ??= await _initialiser();
    return _db!;
  }

  Future<Database> _initialiser() async {
    final chemin = await getDatabasesPath();
    final cheminComplet = join(chemin, 'confidantsante.db');

    return await openDatabase(
      cheminComplet,
      onCreate: _creerTables,
      version: 7,
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await _creerTableRendezVous(db);
        }
        if (oldVersion < 3) {
          await _creerTableSoignants(db);
          await _seedSoignant(db);
        }
        if (oldVersion < 4) {
          await _creerTableMessages(db);
        }
        if (oldVersion < 5) {
          // Ajoute la date de création des rappels (calcul d'observance).
          await db.execute(
            "ALTER TABLE rappels ADD COLUMN date_creation TEXT",
          );
          // Re-hache le mot de passe du soignant de démo (était en clair).
          await db.update(
            'soignants',
            {
              'mot_de_passe': PasswordService.hash(
                identifiant: soignantDemoMatricule,
                motDePasse: 'soignant123',
              ),
            },
            where: 'matricule = ?',
            whereArgs: [soignantDemoMatricule],
          );
        }
        if (oldVersion < 6) {
          // Protocole de traitement : durée + lien rappel ↔ traitement.
          await db.execute("ALTER TABLE traitements ADD COLUMN date_fin TEXT");
          await db.execute("ALTER TABLE traitements ADD COLUMN duree_mois INTEGER");
          await db.execute("ALTER TABLE rappels ADD COLUMN date_fin TEXT");
          await db.execute("ALTER TABLE rappels ADD COLUMN traitement_id INTEGER");
        }
        if (oldVersion < 7) {
          // Identifiant Firestore pour dédupliquer les protocoles synchronisés.
          await db.execute("ALTER TABLE traitements ADD COLUMN remote_id TEXT");
        }
      },
    );
  }

  // Crée toutes les tables au premier lancement
  Future<void> _creerTables(Database db, int version) async {

    // Table patients
    await db.execute('''
      CREATE TABLE patients (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nom TEXT NOT NULL,
        numero TEXT NOT NULL UNIQUE,
        mot_de_passe TEXT NOT NULL,
        soignant TEXT,
        hopital TEXT,
        date_creation TEXT
      )
    ''');

    // Table traitements
    await db.execute('''
      CREATE TABLE traitements (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        patient_id INTEGER NOT NULL,
        nom_medicament TEXT NOT NULL,
        dosage TEXT,
        heure TEXT,
        jours_actifs TEXT DEFAULT 'tous',
        est_actif INTEGER DEFAULT 1,
        date_debut TEXT,
        date_fin TEXT,
        duree_mois INTEGER,
        remote_id TEXT,
        FOREIGN KEY (patient_id) REFERENCES patients(id)
      )
    ''');

    // Table prises — chaque confirmation de prise
    await db.execute('''
      CREATE TABLE prises (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        traitement_id INTEGER NOT NULL,
        patient_id INTEGER NOT NULL,
        date_heure TEXT NOT NULL,
        statut TEXT DEFAULT 'pris',
        synchronise INTEGER DEFAULT 0,
        FOREIGN KEY (traitement_id) REFERENCES traitements(id)
      )
    ''');

    // Table rappels
    await db.execute('''
      CREATE TABLE rappels (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        patient_id INTEGER NOT NULL,
        nom_medicament TEXT NOT NULL,
        dosage TEXT,
        heure TEXT NOT NULL,
        est_actif INTEGER DEFAULT 1,
        date_creation TEXT,
        date_fin TEXT,
        traitement_id INTEGER,
        FOREIGN KEY (patient_id) REFERENCES patients(id)
      )
    ''');

    await _creerTableRendezVous(db);
    await _creerTableSoignants(db);
    await _seedSoignant(db);
    await _creerTableMessages(db);
  }

  // ── Définitions de tables réutilisables (création + migration) ─────────────
  Future<void> _creerTableRendezVous(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS rendez_vous (
        id          INTEGER PRIMARY KEY AUTOINCREMENT,
        patient_id  INTEGER NOT NULL,
        motif       TEXT    NOT NULL,
        lieu        TEXT    DEFAULT '',
        date        TEXT    NOT NULL,
        statut      TEXT    DEFAULT 'planifie',
        FOREIGN KEY (patient_id) REFERENCES patients(id)
      )
    ''');
  }

  Future<void> _creerTableSoignants(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS soignants (
        id            INTEGER PRIMARY KEY AUTOINCREMENT,
        nom           TEXT    NOT NULL,
        matricule     TEXT    NOT NULL UNIQUE,
        mot_de_passe  TEXT    NOT NULL,
        specialite    TEXT    DEFAULT 'Médecin',
        service       TEXT    DEFAULT 'VIH/SIDA',
        date_creation TEXT
      )
    ''');
  }

  Future<void> _seedSoignant(Database db) async {
    await db.insert(
      'soignants',
      {
        'nom':          'Dr. Yves Ndetereyuwe',
        'matricule':    soignantDemoMatricule,
        'mot_de_passe': PasswordService.hash(
          identifiant: soignantDemoMatricule,
          motDePasse: 'soignant123',
        ),
        'specialite':   'Médecin infectiologue',
        'service':      'VIH/SIDA',
        'date_creation': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  Future<void> _creerTableMessages(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS messages (
        id               INTEGER PRIMARY KEY AUTOINCREMENT,
        conversation_id  TEXT    NOT NULL,
        expediteur_id    TEXT    NOT NULL,
        expediteur_role  TEXT    NOT NULL,
        destinataire_id  TEXT    NOT NULL,
        texte            TEXT    NOT NULL,
        timestamp        TEXT    NOT NULL,
        lu               INTEGER DEFAULT 0
      )
    ''');
  }

  // ── PATIENTS ──────────────────────────────────────────────────────────────

  // Crée un nouveau patient (mot de passe haché)
  Future<int> creerPatient({
    required String nom,
    required String numero,
    required String motDePasse,
  }) async {
    final db = await database;
    return await db.insert(
      'patients',
      {
        'nom': nom,
        'numero': numero,
        'mot_de_passe': PasswordService.hash(
          identifiant: numero,
          motDePasse: motDePasse,
        ),
        'date_creation': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  // Vérifie les identifiants de connexion (comparaison du hachage)
  Future<Map<String, dynamic>?> connecterPatient({
    required String numero,
    required String motDePasse,
  }) async {
    final db = await database;
    final resultats = await db.query(
      'patients',
      where: 'numero = ?',
      whereArgs: [numero],
    );
    if (resultats.isEmpty) return null;
    final patient = resultats.first;
    final hachage = patient['mot_de_passe'] as String? ?? '';
    final ok = PasswordService.verifier(
      identifiant: numero,
      motDePasse: motDePasse,
      hachageStocke: hachage,
    );
    return ok ? patient : null;
  }

  // Récupère un patient par son numéro
  Future<Map<String, dynamic>?> getPatient(String numero) async {
    final db = await database;
    final resultats = await db.query(
      'patients',
      where: 'numero = ?',
      whereArgs: [numero],
    );
    return resultats.isNotEmpty ? resultats.first : null;
  }

  // Vérifie si un patient existe déjà
  Future<bool> patientExiste(String numero) async {
    final db = await database;
    final resultats = await db.query(
      'patients',
      where: 'numero = ?',
      whereArgs: [numero],
    );
    return resultats.isNotEmpty;
  }

  // ── RAPPELS ───────────────────────────────────────────────────────────────

  // Ajoute un rappel
  Future<int> ajouterRappel({
    required int patientId,
    required String nomMedicament,
    required String dosage,
    required String heure,
  }) async {
    final db = await database;
    return await db.insert('rappels', {
      'patient_id': patientId,
      'nom_medicament': nomMedicament,
      'dosage': dosage,
      'heure': heure,
      'est_actif': 1,
      'date_creation': DateTime.now().toIso8601String(),
    });
  }

  // Récupère tous les rappels d'un patient
  Future<List<Map<String, dynamic>>> getRappels(int patientId) async {
    final db = await database;
    return await db.query(
      'rappels',
      where: 'patient_id = ? AND est_actif = 1',
      whereArgs: [patientId],
      orderBy: 'heure ASC',
    );
  }

  // Supprime un rappel
  Future<void> supprimerRappel(int id) async {
    final db = await database;
    await db.update(
      'rappels',
      {'est_actif': 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ── PRISES ────────────────────────────────────────────────────────────────

  /// Enregistre une prise de médicament.
  /// Idempotent : une seule prise par rappel et par jour. Retourne l'id inséré,
  /// ou 0 si une prise existait déjà aujourd'hui pour ce rappel.
  Future<int> enregistrerPrise({
    required int traitementId,
    required int patientId,
    required String statut,
  }) async {
    final db = await database;

    if (statut == 'pris' && await aPrisAujourdhui(traitementId, patientId)) {
      return 0;
    }

    return await db.insert('prises', {
      'traitement_id': traitementId,
      'patient_id': patientId,
      'date_heure': DateTime.now().toIso8601String(),
      'statut': statut,
      'synchronise': 0,
    });
  }

  /// Indique si une prise « pris » a déjà été enregistrée aujourd'hui pour ce rappel.
  Future<bool> aPrisAujourdhui(int traitementId, int patientId) async {
    final db = await database;
    final aujourd = DateTime.now();
    final debut = DateTime(aujourd.year, aujourd.month, aujourd.day)
        .toIso8601String();
    final fin = DateTime(aujourd.year, aujourd.month, aujourd.day, 23, 59, 59)
        .toIso8601String();
    final res = await db.query(
      'prises',
      where:
          'traitement_id = ? AND patient_id = ? AND statut = ? AND date_heure BETWEEN ? AND ?',
      whereArgs: [traitementId, patientId, 'pris', debut, fin],
      limit: 1,
    );
    return res.isNotEmpty;
  }

  /// Ensemble des ids de rappels pris aujourd'hui (pour l'état des cases UI).
  Future<Set<int>> getPrisesIdsAujourdhui(int patientId) async {
    final prises = await getPrisesAujourdhui(patientId);
    return prises
        .where((p) => p['statut'] == 'pris')
        .map((p) => p['traitement_id'] as int)
        .toSet();
  }

  // Récupère les prises du jour
  Future<List<Map<String, dynamic>>> getPrisesAujourdhui(
      int patientId,
      ) async {
    final db = await database;
    final aujourd = DateTime.now();
    final debut = DateTime(aujourd.year, aujourd.month, aujourd.day)
        .toIso8601String();
    final fin = DateTime(aujourd.year, aujourd.month, aujourd.day, 23, 59, 59)
        .toIso8601String();

    return await db.query(
      'prises',
      where: 'patient_id = ? AND date_heure BETWEEN ? AND ?',
      whereArgs: [patientId, debut, fin],
      orderBy: 'date_heure DESC',
    );
  }

  /// Calcule le taux d'observance sur 30 jours.
  ///
  /// Observance = doses prises / doses attendues, où les doses attendues sont
  /// estimées à partir de chaque rappel actif et de sa date de création
  /// (une dose attendue par jour depuis la création, plafonnée à 30 jours).
  /// Une prise par rappel et par jour est comptée au maximum.
  Future<double> getTauxObservance(int patientId) async {
    final db = await database;
    final maintenant = DateTime.now();
    final debutFenetre = DateTime(maintenant.year, maintenant.month, maintenant.day)
        .subtract(const Duration(days: 29));

    final rappels = await db.query(
      'rappels',
      where: 'patient_id = ? AND est_actif = 1',
      whereArgs: [patientId],
    );
    if (rappels.isEmpty) return 0.0;

    // Doses attendues
    int attendues = 0;
    for (final r in rappels) {
      final creationStr = r['date_creation'] as String?;
      final creation = creationStr != null
          ? DateTime.tryParse(creationStr)
          : null;
      final debutRappel =
          (creation != null && creation.isAfter(debutFenetre))
              ? DateTime(creation.year, creation.month, creation.day)
              : debutFenetre;
      final jours = maintenant.difference(debutRappel).inDays + 1;
      attendues += jours.clamp(1, 30);
    }
    if (attendues == 0) return 0.0;

    // Doses prises distinctes (rappel, jour) sur 30 jours
    final prises = await db.query(
      'prises',
      where: 'patient_id = ? AND statut = ? AND date_heure > ?',
      whereArgs: [patientId, 'pris', debutFenetre.toIso8601String()],
    );
    final joursPris = <String>{};
    for (final p in prises) {
      final dt = DateTime.tryParse(p['date_heure'] as String? ?? '');
      if (dt == null) continue;
      joursPris.add('${p['traitement_id']}_${dt.year}-${dt.month}-${dt.day}');
    }

    final taux = (joursPris.length / attendues) * 100;
    return taux.clamp(0, 100).toDouble();
  }

  // Récupère l'historique des 30 derniers jours
  Future<List<Map<String, dynamic>>> getHistorique30j(
      int patientId,
      ) async {
    final db = await database;
    final debut = DateTime.now()
        .subtract(const Duration(days: 30))
        .toIso8601String();

    return await db.query(
      'prises',
      where: 'patient_id = ? AND date_heure > ?',
      whereArgs: [patientId, debut],
      orderBy: 'date_heure ASC',
    );
  }

  // ── RENDEZ-VOUS ────────────────────────────────────────────────────────────
  /// Récupère tous les rendez-vous d'un patient
  Future<List<Map<String, dynamic>>> getRendezVous(int patientId) async {
    final db = await database;
    return await db.query(
      'rendez_vous',
      where: 'patient_id = ?',
      whereArgs: [patientId],
      orderBy: 'date ASC',
    );
  }

  /// Supprime un rendez-vous par son id
  Future<void> supprimerRendezVous(int id) async {
    final db = await database;
    await db.delete('rendez_vous', where: 'id = ?', whereArgs: [id]);
  }

  /// Prochain rendez-vous d'un patient (pour le dashboard)
  Future<Map<String, dynamic>?> getProchainRendezVous(int patientId) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    final res = await db.query(
      'rendez_vous',
      where: 'patient_id = ? AND date > ?',
      whereArgs: [patientId, now],
      orderBy: 'date ASC',
      limit: 1,
    );
    return res.isNotEmpty ? res.first : null;
  }

  Future<int> ajouterRendezVous({
    required int patientId,
    required String motif,
    required String lieu,
    required String date,
  }) async {
    final db = await database;
    return await db.insert('rendez_vous', {
      'patient_id': patientId,
      'motif':      motif,
      'lieu':       lieu,
      'date':       date,
      'statut':     'planifie',
    });
  }

  // ── SOIGNANTS ─────────────────────────────────────────────────────────────

  /// Vérifie les identifiants du soignant (comparaison du hachage)
  Future<Map<String, dynamic>?> connecterSoignant({
    required String matricule,
    required String motDePasse,
  }) async {
    final db = await database;
    final res = await db.query(
      'soignants',
      where: 'matricule = ?',
      whereArgs: [matricule],
    );
    if (res.isEmpty) return null;
    final soignant = res.first;
    final ok = PasswordService.verifier(
      identifiant: matricule,
      motDePasse: motDePasse,
      hachageStocke: soignant['mot_de_passe'] as String? ?? '',
    );
    return ok ? soignant : null;
  }

  /// Récupère tous les patients (pour le dashboard soignant)
  Future<List<Map<String, dynamic>>> getTousPatients() async {
    final db = await database;
    return await db.query('patients', orderBy: 'nom ASC');
  }

  /// Crée un patient depuis le dashboard soignant (mot de passe haché)
  Future<int> creerPatientParSoignant({
    required String nom,
    required String numero,
    required String motDePasse,
    String? soignant,
    String? hopital,
  }) async {
    final db = await database;
    return await db.insert(
      'patients',
      {
        'nom':          nom,
        'numero':       numero,
        'mot_de_passe': PasswordService.hash(
          identifiant: numero,
          motDePasse: motDePasse,
        ),
        'soignant':     soignant ?? 'Dr. Yves Ndetereyuwe',
        'hopital':      hopital ?? 'Centre Hospitalier Congo-Chine',
        'date_creation': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  /// Calcule le taux d'observance d'un patient spécifique (local)
  Future<double> getObservancePatient(int patientId) async {
    return await getTauxObservance(patientId);
  }

  /// Vérifie si un numéro de patient existe déjà
  Future<bool> numeroExiste(String numero) async {
    return await patientExiste(numero);
  }

  // ── TRAITEMENTS ───────────────────────────────────────────────────────────

  // Ajoute un traitement
  Future<int> ajouterTraitement({
    required int patientId,
    required String nomMedicament,
    required String dosage,
    required String heure,
  }) async {
    final db = await database;
    return await db.insert('traitements', {
      'patient_id': patientId,
      'nom_medicament': nomMedicament,
      'dosage': dosage,
      'heure': heure,
      'date_debut': DateTime.now().toIso8601String(),
      'est_actif': 1,
    });
  }

  // Récupère les traitements actifs d'un patient
  Future<List<Map<String, dynamic>>> getTraitements(
      int patientId,
      ) async {
    final db = await database;
    return await db.query(
      'traitements',
      where: 'patient_id = ? AND est_actif = 1',
      whereArgs: [patientId],
    );
  }

  // ── PROTOCOLES (médecin → patient) ─────────────────────────────────────────

  /// Médecin : attribue un protocole (médicament + dosage + durée) à un patient.
  /// L'heure reste vide : c'est le patient qui la choisira ensuite.
  Future<int> assignerProtocole({
    required int patientId,
    required String nomMedicament,
    required String dosage,
    required int dureeMois,
  }) async {
    final db = await database;
    final debut = DateTime.now();
    // DateTime gère le débordement de mois (ex. mois 13 → année suivante).
    final fin = DateTime(debut.year, debut.month + dureeMois, debut.day);
    return await db.insert('traitements', {
      'patient_id':     patientId,
      'nom_medicament': nomMedicament,
      'dosage':         dosage,
      'heure':          '',
      'date_debut':     debut.toIso8601String(),
      'date_fin':       fin.toIso8601String(),
      'duree_mois':     dureeMois,
      'est_actif':      1,
    });
  }

  /// Récupère un traitement par son id.
  Future<Map<String, dynamic>?> getTraitementParId(int id) async {
    final db = await database;
    final r = await db.query('traitements',
        where: 'id = ?', whereArgs: [id], limit: 1);
    return r.isNotEmpty ? r.first : null;
  }

  /// Insère un protocole reçu de Firestore s'il n'existe pas déjà localement
  /// (déduplication par remote_id). Ne touche pas à un protocole déjà présent
  /// (donc préserve l'heure éventuellement choisie par le patient).
  Future<void> upsertProtocoleDepuisFirestore({
    required int patientId,
    required String remoteId,
    required String nomMedicament,
    required String dosage,
    String? dateDebut,
    String? dateFin,
    int? dureeMois,
  }) async {
    final db = await database;
    final existant = await db.query(
      'traitements',
      where: 'patient_id = ? AND remote_id = ?',
      whereArgs: [patientId, remoteId],
      limit: 1,
    );
    if (existant.isNotEmpty) return;
    await db.insert('traitements', {
      'patient_id':     patientId,
      'nom_medicament': nomMedicament,
      'dosage':         dosage,
      'heure':          '',
      'date_debut':     dateDebut,
      'date_fin':       dateFin,
      'duree_mois':     dureeMois,
      'est_actif':      1,
      'remote_id':      remoteId,
    });
  }

  /// Patient : protocoles attribués dont l'heure n'est pas encore définie.
  Future<List<Map<String, dynamic>>> getProtocolesAConfigurer(
      int patientId) async {
    final db = await database;
    return await db.query(
      'traitements',
      where: "patient_id = ? AND est_actif = 1 AND (heure IS NULL OR heure = '')",
      whereArgs: [patientId],
      orderBy: 'date_debut DESC',
    );
  }

  /// Patient : fixe l'heure d'un protocole et crée le rappel quotidien associé
  /// (valable jusqu'à la date de fin du protocole). Retourne l'id du rappel.
  Future<int> definirHeureProtocole({
    required int traitementId,
    required int patientId,
    required String nomMedicament,
    required String dosage,
    required String heure,
    String? dateFin,
  }) async {
    final db = await database;
    await db.update(
      'traitements',
      {'heure': heure},
      where: 'id = ?',
      whereArgs: [traitementId],
    );
    return await db.insert('rappels', {
      'patient_id':     patientId,
      'nom_medicament': nomMedicament,
      'dosage':         dosage,
      'heure':          heure,
      'est_actif':      1,
      'date_creation':  DateTime.now().toIso8601String(),
      'date_fin':       dateFin,
      'traitement_id':  traitementId,
    });
  }

  /// Désactive les rappels dont la date de fin est dépassée.
  /// Retourne les ids désactivés (pour annuler leurs notifications).
  Future<List<int>> desactiverRappelsExpires(int patientId) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    final expires = await db.query(
      'rappels',
      where:
          "patient_id = ? AND est_actif = 1 AND date_fin IS NOT NULL AND date_fin < ?",
      whereArgs: [patientId, now],
    );
    for (final r in expires) {
      await db.update('rappels', {'est_actif': 0},
          where: 'id = ?', whereArgs: [r['id']]);
    }
    return expires.map((r) => r['id'] as int).toList();
  }

  // Ferme la base de données
  Future<void> fermer() async {
    final db = _db;
    if (db != null) {
      await db.close();
      _db = null;
    }
  }

  // ── MESSAGES (cache local, complément du temps réel Firestore) ─────────────
  Future<int> envoyerMessage({
    required String conversationId,
    required String expediteurId,
    required String expediteurRole,
    required String destinataireId,
    required String texte,
  }) async {
    final db = await database;
    return await db.insert('messages', {
      'conversation_id':  conversationId,
      'expediteur_id':    expediteurId,
      'expediteur_role':  expediteurRole,
      'destinataire_id':  destinataireId,
      'texte':            texte,
      'timestamp':        DateTime.now().toIso8601String(),
      'lu':               0,
    });
  }

  /// Récupère tous les messages d'une conversation
  Future<List<Map<String, dynamic>>> getMessages(
      String conversationId) async {
    final db = await database;
    return await db.query(
      'messages',
      where:   'conversation_id = ?',
      whereArgs: [conversationId],
      orderBy: 'timestamp ASC',
    );
  }

  /// Marque les messages comme lus
  Future<void> marquerLus(String conversationId, String monId) async {
    final db = await database;
    await db.update(
      'messages',
      {'lu': 1},
      where:     'conversation_id = ? AND destinataire_id = ? AND lu = 0',
      whereArgs: [conversationId, monId],
    );
  }

  /// Compte les messages non lus pour un destinataire
  Future<int> getNonLus(String monId) async {
    final db = await database;
    final res = await db.query(
      'messages',
      where:     'destinataire_id = ? AND lu = 0',
      whereArgs: [monId],
    );
    return res.length;
  }
}
