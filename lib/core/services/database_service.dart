import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseService {

  // Singleton — une seule instance dans toute l'app
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  Database? _db;

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
      version: 1,
      onCreate: _creerTables,
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
        heure TEXT NOT NULL,
        jours_actifs TEXT DEFAULT 'tous',
        est_actif INTEGER DEFAULT 1,
        date_debut TEXT,
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
        FOREIGN KEY (patient_id) REFERENCES patients(id)
      )
    ''');
  }

  // ── PATIENTS ──────────────────────────────────────────────────────────────

  // Crée un nouveau patient
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
        'mot_de_passe': motDePasse,
        'date_creation': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  // Vérifie les identifiants de connexion
  Future<Map<String, dynamic>?> connecterPatient({
    required String numero,
    required String motDePasse,
  }) async {
    final db = await database;
    final resultats = await db.query(
      'patients',
      where: 'numero = ? AND mot_de_passe = ?',
      whereArgs: [numero, motDePasse],
    );
    return resultats.isNotEmpty ? resultats.first : null;
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

  // Enregistre une prise de médicament
  Future<int> enregistrerPrise({
    required int traitementId,
    required int patientId,
    required String statut,
  }) async {
    final db = await database;
    return await db.insert('prises', {
      'traitement_id': traitementId,
      'patient_id': patientId,
      'date_heure': DateTime.now().toIso8601String(),
      'statut': statut,
      'synchronise': 0,
    });
  }

  // Récupère les prises du jour
  Future<List<Map<String, dynamic>>> getPrisesAujourdhui(
      int patientId,
      ) async {
    final db = await database;
    final aujourd = DateTime.now();
    final debut = DateTime(aujourd.year, aujourd.month, aujourd.day)
        .toIso8601String();
    final fin = DateTime(aujourd.year, aujourd.month, aujourd.day, 23, 59)
        .toIso8601String();

    return await db.query(
      'prises',
      where: 'patient_id = ? AND date_heure BETWEEN ? AND ?',
      whereArgs: [patientId, debut, fin],
      orderBy: 'date_heure DESC',
    );
  }

  // Calcule le taux d'observance sur 30 jours
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

    final prises = total.where((p) => p['statut'] == 'pris').length;
    return (prises / total.length) * 100;
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

  // Ferme la base de données
  Future<void> fermer() async {
    final db = _db;
    if (db != null) {
      await db.close();
      _db = null;
    }
  }
}