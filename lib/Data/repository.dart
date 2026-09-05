import 'databaseHelper.dart';

class DataRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  // Helper to generate '?, ?, ?' for SQL IN clauses based on list length
  String _getPlaceholders(int count) => List.filled(count, '?').join(',');

  // POPULATION
  Future<List<Map<String, dynamic>>> getPopulation(List<String> states) async {
    if (states.isEmpty) return [];
    return await _dbHelper.rawQuery('''
      SELECT s.state_name, SUM(p.population_000) as total_population
      FROM population p
      JOIN state s ON p.state_id = s.id
      WHERE s.state_name IN (${_getPlaceholders(states.length)})
        AND p.date = (SELECT MAX(date) FROM population)
        AND p.sex = 'overall_sex' AND p.age = 'overall_age'
      GROUP BY s.state_name
    ''', states);
  }

  // ECONOMY (Income, Poverty, GDP, Labour)
  Future<List<Map<String, dynamic>>> getEconomyMetrics(List<String> states) async {
    if (states.isEmpty) return [];
    return await _dbHelper.rawQuery('''
    SELECT s.state_name, 
           MAX(e.cpi_index) as cpi,
           MAX(e.income_mean) as mean_income,
           MAX(e.income_median) as median_income,
           MAX(e.expenditure_mean) as expenditure,
           MAX(e.poverty_rate) as poverty_rate,
           MAX(e.gini_coefficient) as gini_coefficient,
           MAX(e.gdp_value) as gdp,
           MAX(e.labour_force) as labour_force,
           MAX(e.participation_rate) as participation_rate,
           MAX(e.unemployment_rate) as unemployment
    FROM economy e
    JOIN state s ON e.state_id = s.id
    WHERE s.state_name IN (${_getPlaceholders(states.length)})
    GROUP BY s.state_name
  ''', states);
  }

  // CRIME
  Future<List<Map<String, dynamic>>> getCrime(List<String> states) async {
    if (states.isEmpty) return [];
    return await _dbHelper.rawQuery('''
      SELECT s.state_name, SUM(c.cases) as total_crimes
      FROM crime c
      JOIN state s ON c.state_id = s.id
      WHERE s.state_name IN (${_getPlaceholders(states.length)})
        AND c.date = (SELECT MAX(date) FROM crime)
      GROUP BY s.state_name
    ''', states);
  }

  // DRUG CRIME
  Future<List<Map<String, dynamic>>> getDrugCrime(List<String> states) async {
    if (states.isEmpty) return [];
    return await _dbHelper.rawQuery('''
      SELECT s.state_name, SUM(d.total) as total_drug_cases
      FROM drug_crime d
      JOIN state s ON d.state_id = s.id
      WHERE s.state_name IN (${_getPlaceholders(states.length)})
        AND d.date = (SELECT MAX(date) FROM drug_crime)
      GROUP BY s.state_name
    ''', states);
  }

  // HEALTHCARE
  Future<List<Map<String, dynamic>>> getHealthcare(List<String> states) async {
    if (states.isEmpty) return [];
    return await _dbHelper.rawQuery('''
      SELECT s.state_name, 
             SUM(h.beds) as total_beds, 
             SUM(h.staff_count) as total_staff
      FROM healthcare h
      JOIN state s ON h.state_id = s.id
      WHERE s.state_name IN (${_getPlaceholders(states.length)})
      GROUP BY s.state_name
    ''', states);
  }

  // EDUCATION
  Future<List<Map<String, dynamic>>> getEducation(List<String> states) async {
    if (states.isEmpty) return [];
    return await _dbHelper.rawQuery('''
      SELECT s.state_name, 
             SUM(e.teachers_count) as total_teachers,
             AVG(e.literacy_proportion) as literacy_rate
      FROM education e
      JOIN state s ON e.state_id = s.id
      WHERE s.state_name IN (${_getPlaceholders(states.length)})
      GROUP BY s.state_name
    ''', states);
  }

  // UTILITIES
  Future<List<Map<String, dynamic>>> getUtilities(List<String> states) async {
    if (states.isEmpty) return [];
    return await _dbHelper.rawQuery('''
      SELECT s.state_name, 
             AVG(u.electricity) as electricity_access,
             AVG(u.piped_water) as water_access,
             AVG(u.sanitation) as sanitation_access
      FROM utilities u
      JOIN state s ON u.state_id = s.id
      WHERE s.state_name IN (${_getPlaceholders(states.length)})
      GROUP BY s.state_name
    ''', states);
  }

  // ENVIRONMENT
  Future<List<Map<String, dynamic>>> getEnvironment(List<String> states) async {
    if (states.isEmpty) return [];
    return await _dbHelper.rawQuery('''
      SELECT s.state_name, SUM(e.forest_reserve_area) as green_space_area
      FROM environment e
      JOIN state s ON e.state_id = s.id
      WHERE s.state_name IN (${_getPlaceholders(states.length)})
      GROUP BY s.state_name
    ''', states);
  }

  // SEARCH SUGGESTIONS
  Future<List<String>> searchLocations(String query) async {
    if (query.trim().isEmpty) return [];
    final stateResults = await _dbHelper.rawQuery(
        "SELECT state_name FROM state WHERE state_name LIKE ? LIMIT 10",
        ['%${query.trim()}%']
    );
    return stateResults.map((row) => row['state_name'] as String).toList();
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

  Future<List<Map<String, dynamic>>> getFuelPrice() async {
    return await _dbHelper.rawQuery('''
      SELECT MAX(date) "date", SUM(ron95) "Ron 95", SUM(ron97)"Ron 97", SUM(diesel)"Diesel", SUM(diesel_eastmsia)
      FROM fuelprice
      WHERE date >= (SELECT MAX(date)
                     FROM fuelprice
                     WHERE series_type = 'level');
    ''');


  }
}