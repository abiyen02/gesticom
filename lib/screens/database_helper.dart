import 'package:path/path.dart';
import 'package:sqflite_common/sqlite_api.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class DatabaseHelper {
  static late DatabaseFactory databaseFactory;
  static void _initializeDatabase() {
    if (kIsWeb) {
      databaseFactory = databaseFactoryFfiWeb;
    } else {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
    assert(databaseFactory != null, 'DatabaseFactory is not initialized');
    print('DatabaseFactory initialized: ${databaseFactory.runtimeType}');
  }

  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init() {
    _initializeDatabase();
  }

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('gesticom.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    if (databaseFactory == null) {
      throw Exception('DatabaseFactory is not initialized');
    }
    return await databaseFactory!.openDatabase(path, options: OpenDatabaseOptions(
      version: 1,
      onCreate: _createDB,
    ));
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE effectifs (
        matricule TEXT PRIMARY KEY,
        nom TEXT,
        chambre TEXT,
        midi INTEGER,
        soir INTEGER,
        commentaire TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE arrivees (
        matricule TEXT PRIMARY KEY,
        nom TEXT,
        chambre TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE departs (
        matricule TEXT PRIMARY KEY
      )
    ''');
  }

  Future<List<Map<String, dynamic>>> getEffectifs() async {
    final db = await instance.database;
    return await db.query('effectifs');
  }

  Future<List<Map<String, dynamic>>> getArrivees() async {
  final db = await instance.database;
  return await db.query('arrivees');
}

  Future<List<Map<String, dynamic>>> getDeparts() async {
    final db = await instance.database;
    return await db.query('departs');
  }

Future<void> addArrivee(String matricule, String nom, String chambre) async {
  final db = await instance.database;
  await db.insert('arrivees', {
    'matricule': matricule,
    'nom': nom,
    'chambre': chambre,
  });
  await db.insert('effectifs', {
    'matricule': matricule,
    'nom': nom,
    'chambre': chambre,
    'midi': 0,
    'soir': 0,
    'commentaire': '',
  });
}

  Future<void> addDepart(String matricule) async {
    final db = await instance.database;
    print("Ajout d'un départ : $matricule");

    try {
      await db.insert('departs', {'matricule': matricule},
          conflictAlgorithm: ConflictAlgorithm.replace);
      int deleted = await db.delete('effectifs', where: 'matricule = ?', whereArgs: [matricule]);

      print("Suppression de effectifs : $deleted enregistrements supprimés.");
    } catch (e) {
      print("Erreur lors de l'ajout d'un départ : $e");
    }
  }
}
