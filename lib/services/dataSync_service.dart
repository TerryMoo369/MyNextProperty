import 'package:sqflite/sqflite.dart';
import '../Data/dataGovApi.dart';
import '../Data/databaseHelper.dart';
import '../Data/queryBuilder.dart';

class DataSyncService {
  final DataGovApi _apiClient = DataGovApi();
  final DatabaseHelper _dbHelper = DatabaseHelper();

  /// Orchestrates fetching from API and mapping to Local SQLite
  Future<void> syncDataset(String datasetId, {QueryBuilder? queryBuilder}) async {
    // Extract
    final rawData = await _apiClient.fetchDataset(datasetId, queryBuilder: queryBuilder);

    // Transform & Load
    final batch = await _dbHelper.getBatch();

    for (var item in rawData) {
      final stateName = item['state']?.toString();
      int? regionId;

      if (stateName != null) {
        regionId = await _dbHelper.getOrCreateRegionId(stateName);
      }

      switch (datasetId) {
        case 'population_state':
          if (regionId != null) {
            batch.insert(
              'population',
              {
                'region_id': regionId,
                'date': item['date'],
                'sex': item['sex'],
                'age': item['age'],
                'ethnicity': item['ethnicity'],
                'population_000': (item['population'] as num?)?.toDouble() ?? 0.0,
              },
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
          }
          break;

        case 'cpi_state':
          if (regionId != null) {
            batch.insert(
              'economy',
              {
                'region_id': regionId,
                'date': item['date'],
                'cpi_index': (item['index'] as num?)?.toDouble(),
              },
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
          }
          break;

        case 'crime_district':
          if (regionId != null) {
            batch.insert(
              'crime',
              {
                'region_id': regionId,
                'date': item['date'],
                'crime_category': item['category'] ?? 'overall',
                'cases': (item['crimes'] as num?)?.toInt() ?? 0,
              },
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
          }
          break;

        case 'state_revenue':
          if (regionId != null) {
            batch.insert(
              'state_finance',
              {
                'region_id': regionId,
                'date': item['date'],
                'finance_type': 'revenue',
                'category': item['revenue_type'] ?? 'total',
                'amount_rm_mil': (item['amount'] as num?)?.toDouble() ?? 0.0,
              },
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
          }
          break;

        case 'hh_basic_amenities_state':
          if (regionId != null) {
            batch.insert(
              'utilities',
              {
                'region_id': regionId,
                'date': item['date'],
                'utility_type': item['amenity_type'] ?? 'unknown',
                'access_percentage': (item['percentage'] as num?)?.toDouble() ?? 0.0,
              },
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
          }
          break;

        case 'fuelprice':
          batch.insert(
            'fuelprice',
            {
              'date': item['date'],
              'ron95': (item['ron95'] as num?)?.toDouble(),
              'ron97': (item['ron97'] as num?)?.toDouble(),
              'diesel': (item['diesel'] as num?)?.toDouble(),
            },
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
          break;
      }
    }

    // Commit Transaction
    await batch.commit(noResult: true);
  }
}