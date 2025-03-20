import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:developer';
import 'package:intl/intl.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'gestion.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE effectifs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        matricule TEXT NOT NULL UNIQUE,
        nom TEXT NOT NULL,
        chambre TEXT NOT NULL,
        repas_midi INTEGER DEFAULT 0,
        repas_soir INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE arrivees (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        matricule TEXT NOT NULL,
        nom TEXT NOT NULL,
        chambre TEXT NOT NULL,
        date_arrivee TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    await db.execute('''
      CREATE TABLE departs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        matricule TEXT NOT NULL,
        nom TEXT NOT NULL,
        chambre TEXT NOT NULL,
        type TEXT NOT NULL, 
        date_depart TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    await db.execute('''
      CREATE TABLE main_courante (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        heure TEXT,
        description TEXT,
        paquetage INTEGER DEFAULT 0,
        matelas INTEGER DEFAULT 0,
        repas INTEGER DEFAULT 0,
        commentaire TEXT
      )
    ''');
  }

  Future<List<Map<String, dynamic>>> getEffectifs() async {
    final db = await instance.database;
    return await db.query('effectifs', orderBy: 'nom ASC');
  }

  Future<List<Map<String, dynamic>>> getArrivees() async {
    final db = await instance.database;
    return await db.query('arrivees', orderBy: 'date_arrivee DESC');
  }

  Future<List<Map<String, dynamic>>> getDeparts() async {
    final db = await instance.database;
    return await db.query('departs', orderBy: 'date_depart DESC');
  }

  Future<void> addArrivee(String matricule, String nom, String chambre) async {
    final db = await instance.database;
    final String dateHeure =
        DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());

    // Insérer l'arrivée dans la table 'arrivees'
    await db.insert(
      'arrivees',
      {
        'matricule': matricule,
        'nom': nom,
        'chambre': chambre,
        'date_arrivee': dateHeure,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    // Insérer le client dans la table 'effectifs' s'il n'y est pas déjà
    await db.insert(
      'effectifs',
      {
        'matricule': matricule,
        'nom': nom,
        'chambre': chambre,
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );

    // Ajouter une entrée dans la 'main_courante'
    await db.insert(
      'main_courante',
      {
        'heure': dateHeure,
        'description':
            "Nouvelle arrivée : $nom ($matricule) - Chambre $chambre",
        'paquetage': 0,
        'matelas': 0,
        'repas': 0,
        'commentaire': '',
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    log("✅ Arrivée enregistrée et ajoutée dans la main courante.");
  }

  Future<Map<String, dynamic>?> getClientByMatricule(String matricule) async {
    final db = await instance.database;
    final List<Map<String, dynamic>> result = await db.query(
      'effectifs',
      where: 'matricule = ?',
      whereArgs: [matricule],
    );
    return result.isNotEmpty ? result.first : null;
  }

  Future<void> addDepart(String matricule, String type) async {
    final db = await instance.database;
    final String dateHeure = DateTime.now().toIso8601String();

    final client = await getClientByMatricule(matricule);
    if (client == null) {
      log("❌ Client introuvable dans effectifs");
      return;
    }

    await db.insert(
      'departs',
      {
        'matricule': matricule,
        'nom': client['nom'],
        'chambre': client['chambre'],
        'type': type,
        'date_depart': dateHeure,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    await db
        .delete('effectifs', where: 'matricule = ?', whereArgs: [matricule]);

    log("✅ Client supprimé de effectifs et ajouté à departs !");
  }

  Future<void> updateRepas(
      String matricule, bool repasMidi, bool repasSoir) async {
    final db = await instance.database;
    await db.update(
      'effectifs',
      {
        'repas_midi': repasMidi ? 1 : 0,
        'repas_soir': repasSoir ? 1 : 0,
      },
      where: 'matricule = ?',
      whereArgs: [matricule],
    );
  }
}
