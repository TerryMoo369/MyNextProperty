import 'package:flutter/cupertino.dart';
import 'package:sqflite/sqflite.dart';

import '../data/database_helper.dart';
import '../data/query_builder.dart';
import './data_gov_api_service.dart';

class DataSyncService {
  final DataGovApi _apiClient = DataGovApi();
  final DatabaseHelper _dbHelper = DatabaseHelper();

  Future<void> syncDataset(
    String datasetId, {
    QueryBuilder? queryBuilder,
  }) async {
    final rawData = await _apiClient.fetchDataset(
      datasetId,
      queryBuilder: queryBuilder,
    );

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
            _dbHelper.batchUpsert(
              batch,
              table: 'population',
              data: {
                'state_id': stateId,
                'date': item['date'],
                'sex': item['sex'],
                'age': item['age'],
                'ethnicity': item['ethnicity'],
                'population_000':
                    (item['population'] as num?)?.toDouble() ?? 0.0,
              },
              conflictColumns: ['state_id', 'date', 'sex', 'age', 'ethnicity'],
            );
          }
          break;

        case Dataset.CPI_STATE:
          if (stateId != null) {
            _dbHelper.batchUpsert(
              batch,
              table: 'economy',
              data: {
                'state_id': stateId,
                'date': item['date'],
                'cpi_division': item['division']?.toString(),
                'cpi_index': (item['index'] as num?)?.toDouble(),
              },
              conflictColumns: [
                'state_id',
                'date',
                'district',
                'cpi_division',
                'gdp_sector',
              ],
            );
          }
          break;

        case Dataset.CRIME_DISTRICT:
          if (stateId != null) {
            _dbHelper.batchUpsert(
              batch,
              table: 'crime',
              data: {
                'state_id': stateId,
                'date': item['date'],
                'district': item['district']?.toString(),
                'crime_category': item['category'] ?? 'overall',
                'crime_type': item['type'] ?? 'all',
                'cases': (item['crimes'] as num?)?.toInt() ?? 0,
              },
              conflictColumns: [
                'state_id',
                'date',
                'district',
                'crime_category',
                'crime_type',
              ],
            );
          }
          break;

        case Dataset.HH_INCOME_DISTRICT:
          if (stateId != null) {
            _dbHelper.batchUpsert(
              batch,
              table: 'economy',
              data: {
                'state_id': stateId,
                'date': item['date'],
                'district': item['district']?.toString(),
                'income_mean': (item['income_mean'] as num?)?.toDouble(),
                'income_median': (item['income_median'] as num?)?.toDouble(),
              },
              conflictColumns: [
                'state_id',
                'date',
                'district',
                'cpi_division',
                'gdp_sector',
              ],
            );
          }
          break;

        case Dataset.FUELPRICE:
          _dbHelper.batchUpsert(
            batch,
            table: 'fuelprice',
            data: {
              'date': item['date'],
              'ron95': (item['ron95'] as num?)?.toDouble(),
              'ron97': (item['ron97'] as num?)?.toDouble(),
              'diesel': (item['diesel'] as num?)?.toDouble(),
              'diesel_eastmsia': (item['diesel_eastmsia'] as num?)?.toDouble(),
              'series_type': item['series_type']?.toString(),
            },
            conflictColumns: ['date', 'series_type'],
          );
          break;

        case Dataset.HOSPITAL_BEDS:
          if (stateId != null) {
            _dbHelper.batchUpsert(
              batch,
              table: 'healthcare',
              data: {
                'state_id': stateId,
                'date': item['date'],
                'district': item['district']?.toString(),
                'hospital_type': item['type']?.toString(),
                'beds': (item['beds'] as num?)?.toInt() ?? 0,
              },
              conflictColumns: [
                'date',
                'state_id',
                'district',
                'hospital_type',
                'staff_type',
              ],
            );
          }
          break;

        case Dataset.HEALTHCARE_STAFF:
          if (stateId != null) {
            _dbHelper.batchUpsert(
              batch,
              table: 'healthcare',
              data: {
                'state_id': stateId,
                'date': item['date'],
                'staff_type': item['type']?.toString(),
                'staff_count': (item['staff'] as num?)?.toInt() ?? 0,
              },
              // UPDATE HERE: Added district and hospital_type to match SQL
              conflictColumns: [
                'date',
                'state_id',
                'district',
                'hospital_type',
                'staff_type',
              ],
            );
          }
          break;

        case Dataset.DRUG_ADDICTS_DRUGTYPE:
          if (stateId != null) {
            _dbHelper.batchUpsert(
              batch,
              table: 'drug_crime',
              data: {
                'state_id': stateId,
                'date': item['date'],
                'total': (item['total'] as num?)?.toInt() ?? 0,
                'opiate': (item['opiate'] as num?)?.toInt() ?? 0,
                'cannabis': (item['cannabis'] as num?)?.toInt() ?? 0,
                'meth_crystalline':
                    (item['methamphetamine (crystalline)'] as num?)?.toInt() ??
                    0,
                'ats':
                    (item['amphetamine-type stimulants (ats)'] as num?)
                        ?.toInt() ??
                    0,
                'psychotropic_pill':
                    (item['psychotropic pill'] as num?)?.toInt() ?? 0,
                'others': (item['others'] as num?)?.toInt() ?? 0,
              },
              conflictColumns: ['state_id', 'date'],
            );
          }
          break;

        case Dataset.TEACHERS_DISTRICT:
          if (stateId != null) {
            _dbHelper.batchUpsert(
              batch,
              table: 'education',
              data: {
                'state_id': stateId,
                'date': item['date'],
                'district': item['district']?.toString(),
                'stage': item['stage']?.toString(),
                'sex': item['sex']?.toString(),
                'teachers_count': (item['teachers'] as num?)?.toInt() ?? 0,
              },
              conflictColumns: ['state_id', 'date', 'district', 'stage', 'sex'],
            );
          }
          break;

        case Dataset.SDG_04_6_1:
          if (stateId != null) {
            _dbHelper.batchUpsert(
              batch,
              table: 'education',
              data: {
                'state_id': stateId,
                'date': item['date'],
                'sex': item['sex']?.toString(),
                'literacy_proportion':
                    (item['proportion'] as num?)?.toDouble() ?? 0.0,
              },
              conflictColumns: ['state_id', 'date', 'district', 'stage', 'sex'],
            );
          }
          break;

        case Dataset.HIES_DISTRICT:
          if (stateId != null) {
            _dbHelper.batchUpsert(
              batch,
              table: 'economy',
              data: {
                'state_id': stateId,
                'date': item['date'],
                'district': item['district']?.toString(),
                'gini_coefficient': (item['gini'] as num?)?.toDouble(),
                'poverty_rate': (item['poverty'] as num?)?.toDouble(),
                'income_mean': (item['income_mean'] as num?)?.toDouble(),
                'income_median': (item['income_median'] as num?)?.toDouble(),
                'expenditure_mean': (item['expenditure_mean'] as num?)
                    ?.toDouble(),
              },
              conflictColumns: [
                'state_id',
                'date',
                'district',
                'cpi_division',
                'gdp_sector',
              ],
            );
          }
          break;

        case Dataset.LFS_DISTRICT:
          if (stateId != null) {
            _dbHelper.batchUpsert(
              batch,
              table: 'economy',
              data: {
                'state_id': stateId,
                'date': item['date'],
                'district': item['district']?.toString(),
                'labour_force': (item['lf'] as num?)?.toDouble(),
                'participation_rate': (item['p_rate'] as num?)?.toDouble(),
                'unemployment_rate': (item['u_rate'] as num?)?.toDouble(),
              },
              conflictColumns: [
                'state_id',
                'date',
                'district',
                'cpi_division',
                'gdp_sector',
              ],
            );
          }
          break;

        case Dataset.FOREST_RESERVE_STATE:
          if (stateId != null) {
            _dbHelper.batchUpsert(
              batch,
              table: 'environment',
              data: {
                'state_id': stateId,
                'date': item['date'],
                'forest_reserve_area':
                    (item['area'] as num?)?.toDouble() ?? 0.0,
              },
              conflictColumns: ['state_id', 'date'],
            );
          }
          break;

        case Dataset.GDP_DISTRICT_REAL_SUPPLY:
          if (stateId != null) {
            _dbHelper.batchUpsert(
              batch,
              table: 'economy',
              data: {
                'state_id': stateId,
                'date': item['date'],
                'district': item['district']?.toString(),
                'gdp_value': (item['value'] as num?)?.toDouble(),
                'gdp_sector': item['sector']?.toString(),
              },
              conflictColumns: [
                'state_id',
                'date',
                'district',
                'cpi_division',
                'gdp_sector',
              ],
            );
          }
          break;

        case Dataset.HH_ACCESS_AMENITIES:
          if (stateId != null) {
            _dbHelper.batchUpsert(
              batch,
              table: 'utilities',
              data: {
                'state_id': stateId,
                'date': item['date'],
                'district': item['district']?.toString(),
                'electricity': (item['electricity'] as num?)?.toDouble(),
                'piped_water': (item['piped_water'] as num?)?.toDouble(),
                'sanitation': (item['sanitation'] as num?)?.toDouble(),
              },
              conflictColumns: ['state_id', 'date', 'district'],
            );
          }
          break;
      }
    }

    // Commit Transaction
    await batch.commit(noResult: true);
  }

  /// NEW: Background sync orchestrator with Rate Limit handling
  Future<void> syncAllBackground() async {
    debugPrint('🔄 [DataSync] Starting background data synchronization...');

    final datasets = [
      Dataset.POPULATION_STATE,
      Dataset.CPI_STATE,
      Dataset.CRIME_DISTRICT,
      Dataset.HH_INCOME_DISTRICT,
      Dataset.FUELPRICE,
      Dataset.HOSPITAL_BEDS,
      Dataset.HEALTHCARE_STAFF,
      Dataset.DRUG_ADDICTS_DRUGTYPE,
      Dataset.TEACHERS_DISTRICT,
      Dataset.SDG_04_6_1,
      Dataset.HIES_DISTRICT,
      Dataset.LFS_DISTRICT,
      Dataset.FOREST_RESERVE_STATE,
      Dataset.GDP_DISTRICT_REAL_SUPPLY,
      Dataset.HH_ACCESS_AMENITIES,
    ];

    for (String datasetId in datasets) {
      try {
        debugPrint('⬇️ [DataSync] Fetching dataset: $datasetId');
        // Fetch only the latest data to reduce payload size if necessary
        // In a real scenario, you might use QueryBuilder to limit results here.
        await syncDataset(datasetId);

        // RATE LIMIT PROTECTION: Wait 400ms between API calls (~2.5 req/sec)
        await Future.delayed(const Duration(milliseconds: 400));
      } catch (e) {
        debugPrint('❌ [DataSync] Error syncing $datasetId: $e');
      }
    }

    debugPrint('✅ [DataSync] Background synchronization complete!');
    await verifyDatabase();
  }

  /// NEW: Verifies that data was successfully saved into the SQLite cache
  Future<void> verifyDatabase() async {
    final db = await _dbHelper.database;
    final tables = [
      'state',
      'population',
      'economy',
      'crime',
      'drug_crime',
      'healthcare',
      'education',
      'utilities',
      'environment',
      'fuelprice',
    ];

    debugPrint('📊 --- DATABASE CACHE VERIFICATION ---');
    for (String table in tables) {
      final count = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM $table'),
      );
      debugPrint('   -> Table "$table": $count rows');
    }
    debugPrint('---------------------------------------');
  }
}
