import 'package:flutter/cupertino.dart';
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
      // 1. Population State
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

      // 2. CPI State
        case Dataset.CPI_STATE:
          if (stateId != null) {
            batch.insert(
              'economy',
              {
                'state_id': stateId,
                'date': item['date'],
                'cpi_division': item['division']?.toString(),
                'cpi_index': (item['index'] as num?)?.toDouble(),
              },
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
          }
          break;

      // 3. Crime District
        case Dataset.CRIME_DISTRICT:
          if (stateId != null) {
            batch.insert(
              'crime',
              {
                'state_id': stateId,
                'date': item['date'],
                'district': item['district']?.toString(),
                'crime_category': item['category'] ?? 'overall',
                'crime_type': item['type'] ?? 'all',
                'cases': (item['crimes'] as num?)?.toInt() ?? 0,
              },
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
          }
          break;

      // 4. Household Income District
        case Dataset.HH_INCOME_DISTRICT:
          if (stateId != null) {
            batch.insert(
              'economy',
              {
                'state_id': stateId,
                'date': item['date'],
                'district': item['district']?.toString(),
                'income_mean': (item['income_mean'] as num?)?.toDouble(),
                'income_median': (item['income_median'] as num?)?.toDouble(),
              },
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
          }
          break;

      // 5. Fuel Price (National)
        case Dataset.FUELPRICE:
          batch.insert(
            'fuelprice',
            {
              'date': item['date'],
              'ron95': (item['ron95'] as num?)?.toDouble(),
              'ron97': (item['ron97'] as num?)?.toDouble(),
              'diesel': (item['diesel'] as num?)?.toDouble(),
              'diesel_eastmsia': (item['diesel_eastmsia'] as num?)?.toDouble(),
              'series_type': item['series_type']?.toString(),
            },
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
          break;

      // 6. Hospital Beds
        case Dataset.HOSPITAL_BEDS:
          if (stateId != null) {
            batch.insert(
              'healthcare',
              {
                'state_id': stateId,
                'date': item['date'],
                'district': item['district']?.toString(),
                'hospital_type': item['type']?.toString(),
                'beds': (item['beds'] as num?)?.toInt() ?? 0,
              },
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
          }
          break;

      // 7. Healthcare Staff
        case Dataset.HEALTHCARE_STAFF:
          if (stateId != null) {
            batch.insert(
              'healthcare',
              {
                'state_id': stateId,
                'date': item['date'],
                'staff_type': item['type']?.toString(),
                'staff_count': (item['staff'] as num?)?.toInt() ?? 0,
              },
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
          }
          break;

      // 8. Drug Addicts by Drug Type
        case Dataset.DRUG_ADDICTS_DRUGTYPE:
          if (stateId != null) {
            batch.insert(
              'drug_crime',
              {
                'state_id': stateId,
                'date': item['date'],
                'total': (item['total'] as num?)?.toInt() ?? 0,
                'opiate': (item['opiate'] as num?)?.toInt() ?? 0,
                'cannabis': (item['cannabis'] as num?)?.toInt() ?? 0,
                'meth_crystalline': (item['methamphetamine (crystalline)'] as num?)?.toInt() ?? 0,
                'ats': (item['amphetamine-type stimulants (ats)'] as num?)?.toInt() ?? 0,
                'psychotropic_pill': (item['psychotropic pill'] as num?)?.toInt() ?? 0,
                'others': (item['others'] as num?)?.toInt() ?? 0,
              },
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
          }
          break;

      // 9. Teachers in District
        case Dataset.TEACHERS_DISTRICT:
          if (stateId != null) {
            batch.insert(
              'education',
              {
                'state_id': stateId,
                'date': item['date'],
                'district': item['district']?.toString(),
                'stage': item['stage']?.toString(),
                'sex': item['sex']?.toString(),
                'teachers_count': (item['teachers'] as num?)?.toInt() ?? 0,
              },
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
          }
          break;

      // 10. SDG 04-6-1: Literacy & Numeracy
        case Dataset.SDG_04_6_1:
          if (stateId != null) {
            batch.insert(
              'education',
              {
                'state_id': stateId,
                'date': item['date'],
                'sex': item['sex']?.toString(),
                'literacy_proportion': (item['proportion'] as num?)?.toDouble() ?? 0.0,
              },
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
          }
          break;

      // 11. HIES: Household Income, Expenditure & Poverty
        case Dataset.HIES_DISTRICT:
          if (stateId != null) {
            batch.insert(
              'economy',
              {
                'state_id': stateId,
                'date': item['date'],
                'district': item['district']?.toString(),
                'gini_coefficient': (item['gini'] as num?)?.toDouble(),
                'poverty_rate': (item['poverty'] as num?)?.toDouble(),
                'income_mean': (item['income_mean'] as num?)?.toDouble(),
                'income_median': (item['income_median'] as num?)?.toDouble(),
                'expenditure_mean': (item['expenditure_mean'] as num?)?.toDouble(),
              },
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
          }
          break;

      // 12. Labour Force Statistics
        case Dataset.LFS_DISTRICT:
          if (stateId != null) {
            batch.insert(
              'economy',
              {
                'state_id': stateId,
                'date': item['date'],
                'district': item['district']?.toString(),
                'labour_force': (item['lf'] as num?)?.toDouble(),
                'participation_rate': (item['p_rate'] as num?)?.toDouble(),
                'unemployment_rate': (item['u_rate'] as num?)?.toDouble(),
              },
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
          }
          break;

      // 13. Forest Reserve Area
        case Dataset.FOREST_RESERVE_STATE:
          if (stateId != null) {
            batch.insert(
              'environment',
              {
                'state_id': stateId,
                'date': item['date'],
                'forest_reserve_area': (item['area'] as num?)?.toDouble() ?? 0.0,
              },
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
          }
          break;

      // 14. Real GDP District
        case Dataset.GDP_DISTRICT_REAL_SUPPLY:
          if (stateId != null) {
            batch.insert(
              'economy',
              {
                'state_id': stateId,
                'date': item['date'],
                'district': item['district']?.toString(),
                'gdp_value': (item['value'] as num?)?.toDouble(),
                'gdp_sector': item['sector']?.toString(),
              },
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
          }
          break;

      // 15. Basic Amenities Access
        case Dataset.HH_ACCESS_AMENITIES:
          if (stateId != null) {
            batch.insert(
              'utilities',
              {
                'state_id': stateId,
                'date': item['date'],
                'district': item['district']?.toString(),
                'electricity': (item['electricity'] as num?)?.toDouble(),
                'piped_water': (item['piped_water'] as num?)?.toDouble(),
                'sanitation': (item['sanitation'] as num?)?.toDouble(),
              },
              conflictAlgorithm: ConflictAlgorithm.replace,
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
      'state', 'population', 'economy', 'crime',
      'drug_crime', 'healthcare', 'education',
      'utilities', 'environment', 'fuelprice'
    ];

    debugPrint('📊 --- DATABASE CACHE VERIFICATION ---');
    for (String table in tables) {
      final count = Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM $table')
      );
      debugPrint('   -> Table "$table": $count rows');
    }
    debugPrint('---------------------------------------');
  }
}