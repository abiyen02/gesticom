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
    await db.execute('''
    CREATE TABLE mouvements (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      type TEXT NOT NULL,
      heure TEXT NOT NULL
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

    await db.insert(
      'effectifs',
      {
        'matricule': matricule,
        'nom': nom,
        'chambre': chambre,
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );

    // Ajouter à la main courante avec l'heure en premier
    await db.insert(
      'main_courante',
      {
        'heure': dateHeure,
        'description':
            "$dateHeure - Nouvelle arrivée : $nom ($matricule) - Chambre $chambre",
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

  Future<void> addDepart(String matricule, String type, bool recupereMatelas,
      bool recuperePaquetage) async {
    final db = await instance.database;
    final String dateHeure =
        DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());

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

    // Ajouter à la main courante avec matelas et paquetage
    await db.insert(
      'main_courante',
      {
        'heure': dateHeure,
        'description':
            "$dateHeure - Départ : ${client['nom']} ($matricule) - Chambre ${client['chambre']} - Type: $type",
        'paquetage': recuperePaquetage ? 1 : 0,
        'matelas': recupereMatelas ? 1 : 0,
        'repas': 0, // Pas concerné par les départs
        'commentaire': '',
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    log("✅ Départ enregistré et ajouté dans la main courante.");
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

  // ✅ Fonction pour ajouter un mouvement
  Future<void> addMouvement(String type) async {
    final db = await database;
    await db.insert(
      'mouvements',
      {
        'type': type,
        'heure': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // ✅ Fonction pour récupérer les mouvements
  Future<List<Map<String, dynamic>>> getMouvements() async {
    final db = await database;
    return await db.query('mouvements', orderBy: "heure DESC");
  }

// Mettre à jour un mouvement existant
  Future<int> updateMouvement(int id, String newText) async {
    final db = await database;
    return await db.update(
      'mouvements',
      {'type': newText},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

// Supprimer un mouvement
  Future<int> deleteMouvement(int id) async {
    final db = await database;
    return await db.delete(
      'mouvements',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
