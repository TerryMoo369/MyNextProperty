import 'package:flutter/services.dart' show rootBundle;
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    return openDatabase(
      join(await getDatabasesPath(), 'database.db'),
      version: 1,
      onCreate: (db, version) async {
        final batch = db.batch();
        final sqlFiles = [
          'assets/sql/state.sql',
          'assets/sql/population.sql',
          'assets/sql/crime.sql',
          'assets/sql/drug_crime.sql',
          'assets/sql/economy.sql',
          'assets/sql/fuelprice.sql',
          'assets/sql/healthcare.sql',
          'assets/sql/education.sql',
          'assets/sql/utilities.sql',
          'assets/sql/environment.sql',
        ];

        for (String file in sqlFiles) {
          final sqlScript = await rootBundle.loadString(file);
          batch.execute(sqlScript);
        }
        await batch.commit(noResult: true);
      },
    );
  }

  /// Ensures a state exists in the dimension table and returns its ID
  Future<int> getOrCreateStateId(String stateName) async {
    final db = await database;
    final List<Map<String, dynamic>> result = await db.query(
      'state',
      columns: ['id'],
      where: 'state_name = ?',
      whereArgs: [stateName],
    );

    if (result.isNotEmpty) {
      return result.first['id'] as int;
    }

    return await db.insert(
      'state',
      {'state_name': stateName},
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  /// Exposes batch for external transaction management
  Future<Batch> getBatch() async {
    final db = await database;
    return db.batch();
  }

  /// Standard raw query execution for the Repository layer
  Future<List<Map<String, dynamic>>> rawQuery(String sql, [List<Object?>? arguments]) async {
    final db = await database;
    return await db.rawQuery(sql, arguments);
  }

  void batchUpsert(
      Batch batch, {
        required String table,
        required Map<String, dynamic> data,
        required List<String> conflictColumns,
      }) {
    if (data.isEmpty) return;

    final columns = data.keys.join(', ');
    final placeholders = List.filled(data.length, '?').join(', ');
    final conflictColsString = conflictColumns.join(', ');

    final updateColumns = data.keys
        .where((key) => !conflictColumns.contains(key))
        .map((key) => '$key = excluded.$key')
        .join(', ');

    String sql;
    if (updateColumns.isEmpty) {
      sql = '''
        INSERT INTO $table ($columns)
        VALUES ($placeholders)
        ON CONFLICT($conflictColsString) DO NOTHING;
      ''';
    } else {
      // Standard UPSERT
      sql = '''
        INSERT INTO $table ($columns)
        VALUES ($placeholders)
        ON CONFLICT($conflictColsString) DO UPDATE SET $updateColumns;
      ''';
    }

    batch.rawInsert(sql, data.values.toList());
  }
}