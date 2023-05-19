import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._();

  static Database? _database;

  DatabaseHelper._();

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }

    _database = await initDatabase();
    return _database!;
  }

  Future<Database> initDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, 'markers.db');

    return await openDatabase(path, version: 1, onCreate: _onCreate);
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE markers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        latitude REAL,
        longitude REAL
      )
    ''');
  }

  Future<int> insertMarker(MarkerData marker) async {
    final db = await database;
    return await db.insert('markers', marker.toMap());
  }

  Future<List<MarkerData>> getMarkers() async {
    final db = await instance.database;
    final List<Map<String, dynamic>> maps = await db.query('markers');
    return List.generate(maps.length, (index) {
      return MarkerData.fromMap(maps[index]);
    });
  }

  Future<void> deleteMarker(int id) async {
    final db = await instance.database;
    await db.delete(
      'markers',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}

class MarkerData {
  final int? id;
  final String name;
  final double latitude;
  final double longitude;

  MarkerData({this.id, required this.name, required this.latitude, required this.longitude});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  factory MarkerData.fromMap(Map<String, dynamic> map) {
    return MarkerData(
      id: map['id'],
      name: map['name'],
      latitude: map['latitude'],
      longitude: map['longitude'],
    );
  }


}
