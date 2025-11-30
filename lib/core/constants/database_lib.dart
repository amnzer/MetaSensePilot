import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:io';
class DBUtils{
  // db name
  static const dbname = 'MetaStats.db';
  static const tablename = 'sensor_data';
  static const columnNames = ["timestamp", "page", "sensor1", "sensor2", "sensor3", "sensor4"];

  static Database? _db;  // <-- cached singleton instance

  /// Get database instance (initializes only once)
  static Future<Database> get db async { // property for db access
    if (_db != null) return _db!;

    _db = await initializeDB();
    return _db!;
  }

  // view dbs
  static Future<void> printDBs() async {
    final dbPath = await getDatabasesPath();
    final dir = Directory(dbPath);

    // list files in dir
    final files = dir.listSync();

    print("Databases in $dbPath:");
    
    for (var f in files) {
      if (f is File && extension(f.path) == ".db") {
        print(" - ${basename(f.path)}");
      }
    }
  }
  // make db
  static Future<Database> initializeDB() async {
    // path
    var databasesPath = await getDatabasesPath();
    String path = join(databasesPath, dbname);

    // init table
    Database database = await openDatabase(path, version: 1,
      onCreate: (Database db, int version) async {
      // When creating the db, create the table
        await db.execute('''
          CREATE TABLE IF NOT EXISTS $tablename(
                  ${columnNames[0]} INTEGER,
                  ${columnNames[1]} INTEGER NOT NULL,
                  ${columnNames[2]} DOUBLE,
                  ${columnNames[3]} DOUBLE,
                  ${columnNames[4]} DOUBLE,
                  ${columnNames[5]} DOUBLE)
          ''');
          // init partition
        await db.execute('''
          CREATE INDEX IF NOT EXISTS idx_timestamp
          ON sensor_data(timestamp)
        ''');
    });
    return database;
  }
  // show db entries
  static void printDBEntries(Database db, {bool desc = true}) async{
    var direction = desc ? 'DESC' : 'ASC';
    print("Printing DB contents (latest few rows)");
    var result = await db.rawQuery("SELECT * FROM $tablename ORDER BY timestamp $direction LIMIT 10"); // if uninitialized do nothing
    if (result.isEmpty){
      print("Nothing in db rip");
      return;
    }
    for (var row in result){
      print(row);
    }
  }

  static void printDBEntriesNew(Database db) async{
    print("Printing DB contents (latest few rows)");
    var result = await db.rawQuery("SELECT * FROM $tablename ORDER BY timestamp DESC LIMIT 10"); // if uninitialized do nothing
    if (result.isEmpty){
      print("Nothing in db rip");
      return;
    }
    for (var row in result){
      print(row);
    }
  }
  // get recent entries
  static void insertRow(Map<String,num> data) async{
    var database = await db;
    database.insert(tablename, data);
  }

 // read db
  static Future<List<Map<String, dynamic>>> getAllSensorData({int? limit, bool orderDesc = true}) async {
    final database = await db;
    var query = 'SELECT * FROM $tablename ORDER BY timestamp ${orderDesc ? 'DESC' : 'ASC'}';
    if (limit != null) {
      query += ' LIMIT $limit';
    }
    return await database.rawQuery(query);
  }

  // get latest sensor data
  static Future<Map<String, dynamic>?> getLatestSensorData() async {
    final results = await getAllSensorData(limit: 1, orderDesc: true);
    return results.isNotEmpty ? results.first : null;
  }

  // get today's sensor data
  static Future<List<Map<String, dynamic>>> getTodaySensorData() async {
    final database = await db;
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final startTimestamp = startOfDay.millisecondsSinceEpoch;
    
    return await database.rawQuery(
      'SELECT * FROM $tablename WHERE timestamp >= ? ORDER BY timestamp ASC',
      [startTimestamp],
    );
  }

  // delete db
  static void deleteDB() async{
    var databasesPath = await getDatabasesPath();
    String path = join(databasesPath, dbname);
    deleteDatabase(path);
  }

}