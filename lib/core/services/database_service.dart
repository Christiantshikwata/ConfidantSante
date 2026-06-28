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
      version: 10,
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
        if (oldVersion < 8) {
          // Rattachement d'un patient à son médecin référent (matricule).
          await db.execute(
              "ALTER TABLE patients ADD COLUMN soignant_matricule TEXT");
        }
        if (oldVersion < 9) {
          // Logique hospitalière : le médecin prescrit le traitement et fixe le
          // rendez-vous. On rattache donc ces deux objets au matricule du
          // soignant ; remote_id permet de dédupliquer les RDV synchronisés.
          await _ajouterColonneSiAbsente(
              db, 'traitements', 'soignant_matricule', 'TEXT');
          await _ajouterColonneSiAbsente(
              db, 'rendez_vous', 'soignant_matricule', 'TEXT');
          await _ajouterColonneSiAbsente(
              db, 'rendez_vous', 'remote_id', 'TEXT');
        }
        if (oldVersion < 10) {
          // Informations cliniques et administratives du patient (saisies par
          // le médecin lors de l'ajout).
          await _ajouterColonneSiAbsente(db, 'patients', 'adresse', 'TEXT');
          await _ajouterColonneSiAbsente(db, 'patients', 'genre', 'TEXT');
          await _ajouterColonneSiAbsente(
              db, 'patients', 'taux_serologique', 'TEXT');
          await _ajouterColonneSiAbsente(
              db, 'patients', 'contact_urgence_nom', 'TEXT');
          await _ajouterColonneSiAbsente(
              db, 'patients', 'contact_urgence_tel', 'TEXT');
        }
      },
    );
  }

  // Ajoute une colonne uniquement si elle n'existe pas déjà (migration sûre).
  Future<void> _ajouterColonneSiAbsente(
      Database db, String table, String colonne, String type) async {
    final infos = await db.rawQuery('PRAGMA table_info($table)');
    final existe = infos.any((c) => c['name'] == colonne);
    if (!existe) {
      await db.execute('ALTER TABLE $table ADD COLUMN $colonne $type');
    }
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
        soignant_matricule TEXT,
        hopital TEXT,
        date_creation TEXT,
        adresse TEXT,
        genre TEXT,
        taux_serologique TEXT,
        contact_urgence_nom TEXT,
        contact_urgence_tel TEXT
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
        soignant_matricule TEXT,
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
        id                 INTEGER PRIMARY KEY AUTOINCREMENT,
        patient_id         INTEGER NOT NULL,
        motif              TEXT    NOT NULL,
        lieu               TEXT    DEFAULT '',
        date               TEXT    NOT NULL,
        statut             TEXT    DEFAULT 'planifie',
        soignant_matricule TEXT,
        remote_id          TEXT,
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
  /// Après réconciliation (cf. reconcilierPrisesManquees), la table `prises`
  /// contient une entrée par jour écoulé et par rappel : « pris » ou « manque ».
  /// Observance = prises confirmées / (prises + manquées).
  Future<double> getTauxObservance(int patientId) async {
    final db = await database;
    final debut = DateTime.now()
        .subtract(const Duration(days: 30))
        .toIso8601String();

    final total = await db.query(
      'prises',
      where: 'patient_id = ? AND date_heure > ?',
      whereArgs: [patientId, debut],
    );
    if (total.isEmpty) return 0.0;

    final pris = total.where((p) => p['statut'] == 'pris').length;
    return (pris / total.length) * 100;
  }

  /// Réconciliation des doses manquées : pour chaque rappel actif, marque
  /// « manque » chaque jour écoulé (jusqu'à hier, sans dépasser la date de fin
  /// du protocole) où aucune prise n'a été enregistrée. Idempotent.
  Future<void> reconcilierPrisesManquees(int patientId) async {
    final db = await database;
    final rappels = await db.query(
      'rappels',
      where: 'patient_id = ? AND est_actif = 1',
      whereArgs: [patientId],
    );
    if (rappels.isEmpty) return;

    final now = DateTime.now();
    final today0 = DateTime(now.year, now.month, now.day);
    final fenetreDebut = today0.subtract(const Duration(days: 29));
    // On ne traite que jusqu'à HIER (la journée en cours n'est pas terminée).
    final hier = today0.subtract(const Duration(days: 1));

    for (final r in rappels) {
      final id = r['id'] as int;
      final creationStr = r['date_creation'] as String?;
      final creation =
          creationStr != null ? DateTime.tryParse(creationStr) : null;
      if (creation == null) continue; // sans date de début, on ne sait pas

      final finStr = r['date_fin'] as String?;
      final fin = finStr != null ? DateTime.tryParse(finStr) : null;

      var jour = DateTime(creation.year, creation.month, creation.day);
      if (jour.isBefore(fenetreDebut)) jour = fenetreDebut;

      var dernier = hier;
      if (fin != null) {
        final finJour = DateTime(fin.year, fin.month, fin.day);
        if (finJour.isBefore(dernier)) dernier = finJour;
      }

      while (!jour.isAfter(dernier)) {
        final debutJ = jour.toIso8601String();
        final finJ =
            DateTime(jour.year, jour.month, jour.day, 23, 59, 59)
                .toIso8601String();
        final existe = await db.query(
          'prises',
          where:
              'traitement_id = ? AND patient_id = ? AND date_heure BETWEEN ? AND ?',
          whereArgs: [id, patientId, debutJ, finJ],
          limit: 1,
        );
        if (existe.isEmpty) {
          await db.insert('prises', {
            'traitement_id': id,
            'patient_id': patientId,
            'date_heure':
                DateTime(jour.year, jour.month, jour.day, 12, 0)
                    .toIso8601String(),
            'statut': 'manque',
            'synchronise': 0,
          });
        }
        jour = jour.add(const Duration(days: 1));
      }
    }
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

  /// Regroupe une liste de prises par jour calendaire (utile quand le patient
  /// suit plusieurs protocoles : une seule entrée par date au lieu d'une par
  /// médicament). Retourne une liste triée par date croissante, chaque élément
  /// contenant : date (DateTime du jour), total, pris et taux (0..1).
  static List<Map<String, dynamic>> grouperParJour(
      List<Map<String, dynamic>> prises) {
    final Map<String, Map<String, dynamic>> parJour = {};
    for (final p in prises) {
      final dt = DateTime.tryParse(p['date_heure'] as String? ?? '');
      if (dt == null) continue;
      final jour = DateTime(dt.year, dt.month, dt.day);
      final cle = jour.toIso8601String();
      final m = parJour.putIfAbsent(
          cle, () => {'date': jour, 'total': 0, 'pris': 0});
      m['total'] = (m['total'] as int) + 1;
      if (p['statut'] == 'pris') m['pris'] = (m['pris'] as int) + 1;
    }
    final liste = parJour.values.toList()
      ..sort((a, b) =>
          (a['date'] as DateTime).compareTo(b['date'] as DateTime));
    for (final m in liste) {
      final total = m['total'] as int;
      m['taux'] = total > 0 ? (m['pris'] as int) / total : 0.0;
    }
    return liste;
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

  /// Médecin : fixe un rendez-vous pour un patient. Le matricule du soignant
  /// auteur du rendez-vous est conservé (logique hospitalière : un rendez-vous
  /// lie le patient ET le médecin).
  Future<int> ajouterRendezVous({
    required int patientId,
    required String motif,
    required String lieu,
    required String date,
    String? soignantMatricule,
  }) async {
    final db = await database;
    return await db.insert('rendez_vous', {
      'patient_id':         patientId,
      'motif':              motif,
      'lieu':               lieu,
      'date':               date,
      'statut':             'planifie',
      'soignant_matricule': soignantMatricule,
    });
  }

  /// Patient : insère un rendez-vous reçu de Firestore s'il n'existe pas déjà
  /// localement (déduplication par remote_id).
  Future<void> upsertRendezVousDepuisFirestore({
    required int patientId,
    required String remoteId,
    required String motif,
    required String lieu,
    required String date,
    String? statut,
    String? soignantMatricule,
  }) async {
    final db = await database;
    final existant = await db.query(
      'rendez_vous',
      where: 'patient_id = ? AND remote_id = ?',
      whereArgs: [patientId, remoteId],
      limit: 1,
    );
    if (existant.isNotEmpty) {
      await db.update(
        'rendez_vous',
        {
          'motif':  motif,
          'lieu':   lieu,
          'date':   date,
          'statut': statut ?? 'planifie',
        },
        where: 'patient_id = ? AND remote_id = ?',
        whereArgs: [patientId, remoteId],
      );
      return;
    }
    await db.insert('rendez_vous', {
      'patient_id':         patientId,
      'motif':              motif,
      'lieu':               lieu,
      'date':               date,
      'statut':             statut ?? 'planifie',
      'soignant_matricule': soignantMatricule,
      'remote_id':          remoteId,
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

  /// Crée un patient depuis le dashboard soignant (mot de passe haché),
  /// rattaché au médecin référent (matricule).
  Future<int> creerPatientParSoignant({
    required String nom,
    required String numero,
    required String motDePasse,
    String? soignant,
    String? soignantMatricule,
    String? hopital,
    String? adresse,
    String? genre,
    String? tauxSerologique,
    String? contactUrgenceNom,
    String? contactUrgenceTel,
  }) async {
    final db = await database;
    return await db.insert(
      'patients',
      {
        'nom':                 nom,
        'numero':              numero,
        'mot_de_passe':        PasswordService.hash(
          identifiant: numero,
          motDePasse: motDePasse,
        ),
        'soignant':            soignant ?? 'Dr. Yves Ndetereyuwe',
        'soignant_matricule':  soignantMatricule,
        'hopital':             hopital ?? 'Centre Hospitalier Congo-Chine',
        'date_creation':       DateTime.now().toIso8601String(),
        'adresse':             adresse,
        'genre':               genre,
        'taux_serologique':    tauxSerologique,
        'contact_urgence_nom': contactUrgenceNom,
        'contact_urgence_tel': contactUrgenceTel,
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  // ── GESTION DES MÉDECINS (admin) ───────────────────────────────────────────

  /// Le médecin de démonstration fait office d'administrateur.
  bool estAdmin(String? matricule) => matricule == soignantDemoMatricule;

  /// Crée un nouveau médecin (mot de passe haché, salé par matricule).
  Future<int> creerSoignant({
    required String nom,
    required String matricule,
    required String motDePasse,
    String? specialite,
  }) async {
    final db = await database;
    return await db.insert(
      'soignants',
      {
        'nom':           nom,
        'matricule':     matricule,
        'mot_de_passe':  PasswordService.hash(
          identifiant: matricule,
          motDePasse: motDePasse,
        ),
        'specialite':    specialite ?? 'Médecin',
        'service':       'VIH/SIDA',
        'date_creation': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  /// Crée un médecin avec un mot de passe DÉJÀ haché (compte récupéré de
  /// Firestore lors d'une première connexion sur le téléphone du médecin).
  Future<int> creerSoignantAvecHash({
    required String nom,
    required String matricule,
    required String hashMotDePasse,
    String? specialite,
  }) async {
    final db = await database;
    return await db.insert(
      'soignants',
      {
        'nom':           nom,
        'matricule':     matricule,
        'mot_de_passe':  hashMotDePasse,
        'specialite':    specialite ?? 'Médecin',
        'service':       'VIH/SIDA',
        'date_creation': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  /// Insère/maj un patient reçu de Firestore (vue du médecin sur ses patients).
  /// Dédup par numéro ; si le patient existe déjà, met à jour le rattachement.
  Future<void> upsertPatientDepuisFirestore({
    required String numero,
    required String nom,
    String? soignant,
    String? soignantMatricule,
    String? hopital,
    String? hashMotDePasse,
    String? adresse,
    String? genre,
    String? tauxSerologique,
    String? contactUrgenceNom,
    String? contactUrgenceTel,
  }) async {
    final db = await database;
    final existant = await db.query('patients',
        where: 'numero = ?', whereArgs: [numero], limit: 1);
    if (existant.isNotEmpty) {
      await db.update(
        'patients',
        {
          'soignant_matricule':  soignantMatricule,
          if (soignant != null) 'soignant': soignant,
          if (adresse != null) 'adresse': adresse,
          if (genre != null) 'genre': genre,
          if (tauxSerologique != null) 'taux_serologique': tauxSerologique,
          if (contactUrgenceNom != null) 'contact_urgence_nom': contactUrgenceNom,
          if (contactUrgenceTel != null) 'contact_urgence_tel': contactUrgenceTel,
        },
        where: 'numero = ?',
        whereArgs: [numero],
      );
      return;
    }
    await db.insert(
      'patients',
      {
        'nom':                 nom,
        'numero':              numero,
        'mot_de_passe':        hashMotDePasse ?? '',
        'soignant':            soignant,
        'soignant_matricule':  soignantMatricule,
        'hopital':             hopital,
        'date_creation':       DateTime.now().toIso8601String(),
        'adresse':             adresse,
        'genre':               genre,
        'taux_serologique':    tauxSerologique,
        'contact_urgence_nom': contactUrgenceNom,
        'contact_urgence_tel': contactUrgenceTel,
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  /// Liste de tous les médecins.
  Future<List<Map<String, dynamic>>> getTousSoignants() async {
    final db = await database;
    return await db.query('soignants', orderBy: 'nom ASC');
  }

  /// Vérifie si un matricule de médecin existe déjà.
  Future<bool> matriculeExiste(String matricule) async {
    final db = await database;
    final res = await db.query('soignants',
        where: 'matricule = ?', whereArgs: [matricule], limit: 1);
    return res.isNotEmpty;
  }

  /// Patients rattachés à un médecin précis.
  Future<List<Map<String, dynamic>>> getPatientsParSoignant(
      String matricule) async {
    final db = await database;
    return await db.query(
      'patients',
      where: 'soignant_matricule = ?',
      whereArgs: [matricule],
      orderBy: 'nom ASC',
    );
  }

  /// Récupère un médecin par son matricule (ou null).
  Future<Map<String, dynamic>?> getSoignantParMatricule(
      String matricule) async {
    final db = await database;
    final res = await db.query('soignants',
        where: 'matricule = ?', whereArgs: [matricule], limit: 1);
    return res.isNotEmpty ? res.first : null;
  }

  /// Migration : rattache un patient à un autre médecin (matricule + nom).
  Future<void> changerSoignantPatient({
    required int patientId,
    required String matricule,
    String? nomSoignant,
  }) async {
    final db = await database;
    await db.update(
      'patients',
      {
        'soignant_matricule': matricule,
        if (nomSoignant != null) 'soignant': nomSoignant,
      },
      where: 'id = ?',
      whereArgs: [patientId],
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

  /// Crée un patient avec un mot de passe DÉJÀ haché (compte récupéré de
  /// Firestore lors d'une première connexion sur le téléphone du patient).
  Future<int> creerPatientAvecHash({
    required String nom,
    required String numero,
    required String hashMotDePasse,
    String? soignant,
    String? hopital,
  }) async {
    final db = await database;
    return await db.insert(
      'patients',
      {
        'nom':           nom,
        'numero':        numero,
        'mot_de_passe':  hashMotDePasse,
        'soignant':      soignant,
        'hopital':       hopital,
        'date_creation': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
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
    String? soignantMatricule,
  }) async {
    final db = await database;
    final debut = DateTime.now();
    // DateTime gère le débordement de mois (ex. mois 13 → année suivante).
    final fin = DateTime(debut.year, debut.month + dureeMois, debut.day);
    return await db.insert('traitements', {
      'patient_id':         patientId,
      'nom_medicament':     nomMedicament,
      'dosage':             dosage,
      'heure':              '',
      'date_debut':         debut.toIso8601String(),
      'date_fin':           fin.toIso8601String(),
      'duree_mois':         dureeMois,
      'est_actif':          1,
      'soignant_matricule': soignantMatricule,
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
