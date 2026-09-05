import 'dart:convert';
import 'dart:isolate';

import 'package:http/http.dart' as http;

import '../data/query_builder.dart';

class Dataset {
  // Population
  static const String POPULATION_STATE = 'population_state';

  // Economy, Income & Cost of Living
  static const String CPI_STATE = 'cpi_state';
  static const String HH_INCOME_DISTRICT = 'hh_income_district';
  static const String HIES_DISTRICT = 'hies_district';
  static const String LFS_DISTRICT = 'lfs_district';
  static const String GDP_DISTRICT_REAL_SUPPLY = 'gdp_district_real_supply';
  static const String FUELPRICE = 'fuelprice';

  // Crime & Safety
  static const String CRIME_DISTRICT = 'crime_district';
  static const String DRUG_ADDICTS_DRUGTYPE = 'drug_addicts_drugtype';

  // Healthcare
  static const String HOSPITAL_BEDS = 'hospital_beds';
  static const String HEALTHCARE_STAFF = 'healthcare_staff';

  // Education
  static const String TEACHERS_DISTRICT = 'teachers_district';
  static const String SDG_04_6_1 = 'sdg_04-6-1';

  // Amenities & Environment
  static const String HH_ACCESS_AMENITIES = 'hh_access_amenities';
  static const String FOREST_RESERVE_STATE = 'forest_reserve_state';
}

class DataGovApi {
  Future<List<dynamic>> fetchDataset(
    String datasetId, {
    QueryBuilder? queryBuilder,
  }) async {
    final queryString = queryBuilder?.build() ?? '';
    final apiUrl =
        'https://api.data.gov.my/data-catalogue?id=$datasetId${queryString.isNotEmpty ? '&$queryString' : ''}';

    final response = await http.get(Uri.parse(apiUrl));

    if (response.statusCode != 200) {
      throw Exception(
        'API Error: ${response.statusCode} for dataset $datasetId',
      );
    }

    // Decode JSON off the main thread to prevent UI lag
    return await Isolate.run(() => jsonDecode(response.body) as List<dynamic>);
  }
}
