import 'databaseHelper.dart';

class DataRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  Future<List<Map<String, dynamic>>> getPopulationTrends(List<String> states) async {
    if (states.isEmpty) return [];

    final placeholders = List.filled(states.length, '?').join(',');

    return await _dbHelper.rawQuery('''
      SELECT s.state_name, p.date, p.population_000 
      FROM population p
      JOIN state s ON s.id = s.region_id
      WHERE s.state_name IN ($placeholders) 
        AND p.sex = 'both' AND p.age = 'overall'
      ORDER BY p.date ASC
    ''', states);
  }

  Future<List<Map<String, dynamic>>> getLatestEconomicData() async {
    return await _dbHelper.rawQuery('''
      SELECT s.state_name, e.income_median, e.poverty_absolute, e.cpi_index 
      FROM economy e
      JOIN state s ON e.state_id = s.state_id
      WHERE e.date = (SELECT MAX(date) FROM economy)
    ''');
  }

  Future<List<Map<String, dynamic>>> getStateRevenueHistory(String stateName) async {
    return await _dbHelper.rawQuery('''
      SELECT f.date, f.amount_rm_mil 
      FROM state_finance f
      JOIN state s ON f.state_id = s.state_id
      WHERE s.state_name = ? AND f.finance_type = 'revenue'
      ORDER BY f.date DESC
    ''', [stateName]);
  }

  Future<List<Map<String, dynamic>>> getMapPopulationData() async {
    return await _dbHelper.rawQuery('''
    SELECT DISTINCT
      s.id AS state_id,
      s.state_name,
      p.date,
      p.population_000
    FROM population p
    JOIN state s
      ON p.state_id = s.id
    WHERE p.sex = 'overall_sex'
      AND p.age = 'overall_age'
      AND p.ethnicity = 'overall_ethnicity'
      AND p.date = (
        SELECT MAX(p2.date)
        FROM population p2
        WHERE p2.state_id = p.state_id
          AND p2.sex = 'overall_sex'
          AND p2.age = 'overall_age'
          AND p2.ethnicity = 'overall_ethnicity'
      )
    ORDER BY s.state_name ASC
  ''');
  }

  Future<List<Map<String, dynamic>>> testPopulationTable() async {
    return await _dbHelper.rawQuery('''
    SELECT *
    FROM population
    LIMIT 5
  ''');
  }

}