import 'package:sqflite/sqflite.dart';
import '../Data/dataGovApi.dart';
import '../Data/databaseHelper.dart';
import '../Data/queryBuilder.dart';
import '../Data/Dataset.dart';

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
      int? stateId;

      if (stateName != null) {
        stateId = await _dbHelper.getOrCreateStateId(stateName);
      }

      switch (datasetId) {
        case Dataset.POPULATION_STATE:
          if (stateId != null) {
            batch.insert(
              'population',
              {
                'state_id': stateId,
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

        case Dataset.CPI_STATE:
          if (stateId != null) {
            batch.insert(
              'economy',
              {
                'state_id': stateId,
                'date': item['date'],
                'cpi_index': (item['index'] as num?)?.toDouble(),
              },
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
          }
          break;

        case Dataset.CRIME_DISTRICT:
          if (stateId != null) {
            batch.insert(
              'crime',
              {
                'state_id': stateId,
                'date': item['date'],
                'crime_category': item['category'] ?? 'overall',
                'cases': (item['crimes'] as num?)?.toInt() ?? 0,
              },
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
          }
          break;

        case Dataset.STATE_REVENUE:
          if (stateId != null) {
            batch.insert(
              'state_finance',
              {
                'state_id': stateId,
                'date': item['date'],
                'finance_type': 'revenue',
                'category': item['revenue_type'] ?? 'total',
                'amount_rm_mil': (item['amount'] as num?)?.toDouble() ?? 0.0,
              },
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
          }
          break;

        case Dataset.HH_BASIC_AMENITIES_STATE:
          if (stateId != null) {
            batch.insert(
              'utilities',
              {
                'state_id': stateId,
                'date': item['date'],
                'utility_type': item['amenity_type'] ?? 'unknown',
                'access_percentage': (item['percentage'] as num?)?.toDouble() ?? 0.0,
              },
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
          }
          break;

        case Dataset.FUELPRICE:
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