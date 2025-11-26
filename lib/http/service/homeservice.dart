import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:itrack/http/model/assetresponsemodel.dart';
import 'package:itrack/http/model/locationcountmodel.dart';
import 'package:itrack/http/service/endpoints.dart';


class DashboardService {
  final http.Client _client;
  final String? authToken;

  DashboardService({http.Client? client, this.authToken}) 
      : _client = client ?? http.Client();

  Map<String, String> _getHeaders() {
    return {
      'Content-Type': 'application/json',
      if (authToken != null) 'Authorization': 'Bearer $authToken',
    };
  }

  // Get all assets by location
  Future<List<LocationCountModel>> getAllAssetsByLocation(
    String tenantId,
    String locationId,
  ) async {
    try {
      final url = Uri.parse(
        '${ApiEndPoints.baseUrl}${ApiEndPoints.getAllAssetsByLocation}?tenantId=$tenantId&locationId=$locationId'
      );

      final response = await _client.get(url, headers: _getHeaders());

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => LocationCountModel.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load location counts: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching location counts: $e');
    }
  }

  // Get today's assets by person and date
  Future<List<AssetResponseModel>> getTodaysAssets(
    String currentDate,
    String createdBy,
    String tenantId,
    String locationId,
  ) async {
    try {
      final url = Uri.parse(
        '${ApiEndPoints.baseUrl}${ApiEndPoints.getAllAssetsByDateByPerson}?currentDate=$currentDate&createdBy=$createdBy&tenantId=$tenantId&locationId=$locationId'
      );

      final response = await _client.get(url, headers: _getHeaders());

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => AssetResponseModel.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load today\'s assets: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching today\'s assets: $e');
    }
  }

  // Get audit count by location
  Future<List<LocationAuditCountModel>> getAuditCountByLocation(
    String tenantId,
    String locationId,
  ) async {
    try {
      final url = Uri.parse(
        '${ApiEndPoints.baseUrl}${ApiEndPoints.getAllAssetAuditCountLocation}?tenantId=$tenantId&locationId=$locationId'
      );

      final response = await _client.get(url, headers: _getHeaders());

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => LocationAuditCountModel.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load audit counts: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching audit counts: $e');
    }
  }

  void dispose() {
    _client.close();
  }
}