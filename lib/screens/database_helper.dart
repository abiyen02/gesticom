import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

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
        date_depart TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');
  }

  /// 🔹 **Récupérer les effectifs (clients présents)**
  Future<List<Map<String, dynamic>>> getEffectifs() async {
    final db = await instance.database;
    return await db.query('effectifs', orderBy: 'nom ASC');
  }

  /// 🔹 **Mettre à jour les repas d’un client**
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

  /// 🔹 **Récupérer les arrivées**
  Future<List<Map<String, dynamic>>> getArrivees() async {
    final db = await instance.database;
    return await db.query('arrivees', orderBy: 'date_arrivee DESC');
  }

  /// 🔹 **Récupérer les départs**
  Future<List<Map<String, dynamic>>> getDeparts() async {
    final db = await instance.database;
    return await db.query('departs', orderBy: 'date_depart DESC');
  }

  /// 🔹 **Ajouter une arrivée**
  Future<void> addArrivee(String matricule, String nom, String chambre) async {
    final db = await instance.database;
    await db.insert(
      'arrivees',
      {
        'matricule': matricule,
        'nom': nom,
        'chambre': chambre,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    // 🔹 Ajouter aussi dans les effectifs
    await db.insert(
      'effectifs',
      {
        'matricule': matricule,
        'nom': nom,
        'chambre': chambre,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// 🔹 **Ajouter un départ**
  Future<void> addDepart(String matricule) async {
    final db = await instance.database;
    await db.insert(
      'departs',
      {
        'matricule': matricule,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    // 🔹 Supprimer de la table des effectifs et des arrivées
    await db.delete('arrivees', where: 'matricule = ?', whereArgs: [matricule]);
    await db
        .delete('effectifs', where: 'matricule = ?', whereArgs: [matricule]);
  }
}
