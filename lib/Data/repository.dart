import 'databaseHelper.dart';

class DataRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  Future<List<Map<String, dynamic>>> getPopulationTrends(List<String> states) async {
    if (states.isEmpty) return [];

    final placeholders = List.filled(states.length, '?').join(',');

    return await _dbHelper.rawQuery('''
      SELECT r.state_name, p.date, p.population_000 
      FROM population p
      JOIN regions r ON p.region_id = r.region_id
      WHERE r.state_name IN ($placeholders) 
        AND p.sex = 'both' AND p.age = 'overall'
      ORDER BY p.date ASC
    ''', states);
  }

  Future<List<Map<String, dynamic>>> getLatestEconomicData() async {
    return await _dbHelper.rawQuery('''
      SELECT r.state_name, e.income_median, e.poverty_absolute, e.cpi_index 
      FROM economy e
      JOIN regions r ON e.region_id = r.region_id
      WHERE e.date = (SELECT MAX(date) FROM economy)
    ''');
  }

  Future<List<Map<String, dynamic>>> getStateRevenueHistory(String stateName) async {
    return await _dbHelper.rawQuery('''
      SELECT f.date, f.amount_rm_mil 
      FROM state_finance f
      JOIN regions r ON f.region_id = r.region_id
      WHERE r.state_name = ? AND f.finance_type = 'revenue'
      ORDER BY f.date DESC
    ''', [stateName]);
  }
}