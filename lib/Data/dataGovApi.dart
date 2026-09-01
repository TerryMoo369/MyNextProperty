import 'dart:convert';
import 'dart:isolate';
import 'package:http/http.dart' as http;
import 'queryBuilder.dart';

class DataGovApi {
  Future<List<dynamic>> fetchDataset(String datasetId, {QueryBuilder? queryBuilder}) async {
    final queryString = queryBuilder?.build() ?? '';
    final apiUrl = 'https://api.data.gov.my/data-catalogue?id=$datasetId${queryString.isNotEmpty ? '&$queryString' : ''}';

    final response = await http.get(Uri.parse(apiUrl));

    if (response.statusCode != 200) {
      throw Exception('API Error: ${response.statusCode} for dataset $datasetId');
    }

    // Decode JSON off the main thread to prevent UI lag
    return await Isolate.run(() => jsonDecode(response.body) as List<dynamic>);
  }
}