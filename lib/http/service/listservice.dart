import 'dart:convert';
import 'package:itrack/http/model/auditlistmodel.dart';
import 'package:itrack/http/service/authmiddleware.dart';
import 'dart:developer' as developer;

import 'package:itrack/http/service/endpoints.dart';

class AuditListService {
  final AuthMiddleware _authMiddleware = AuthMiddleware.instance;

  // Singleton pattern
  static AuditListService? _instance;
  
  static AuditListService get instance {
    _instance ??= AuditListService._internal();
    return _instance!;
  }

  AuditListService._internal();

  /// Fetch list of audits with mismatches
  Future<List<AssetAuditMismatch>> fetchAuditList() async {
    try {
      developer.log(
        '📡 Fetching audit list from: ${ApiEndPoints.getListofAudits}',
        name: 'AuditListService'
      );

      final response = await _authMiddleware.get(
        ApiEndPoints.getListofAudits,
        requiresAuth: true,
      );

      developer.log(
        '📥 Response received - Status: ${response.statusCode}',
        name: 'AuditListService'
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = jsonDecode(response.body);
        
        developer.log(
          '✅ Successfully parsed ${jsonData.length} audit records',
          name: 'AuditListService'
        );

        final audits = jsonData
            .map((json) => AssetAuditMismatch.fromJson(json))
            .toList();

        // Log sample data
        if (audits.isNotEmpty) {
          developer.log(
            '📋 Sample: ${audits.first.assetName} (${audits.first.barcode}) - ${audits.first.mismatchCount} issues',
            name: 'AuditListService'
          );
        }

        return audits;
      } else if (response.statusCode == 401) {
        developer.log(
          '❌ Unauthorized - Token may be invalid',
          name: 'AuditListService'
        );
        throw AuditServiceException(
          'Unauthorized access. Please login again.',
          statusCode: 401,
        );
      } else if (response.statusCode == 404) {
        developer.log(
          '⚠️ No audit data found',
          name: 'AuditListService'
        );
        return []; // Return empty list for 404
      } else {
        final errorBody = response.body;
        developer.log(
          '❌ API Error - Status: ${response.statusCode}, Body: $errorBody',
          name: 'AuditListService'
        );
        throw AuditServiceException(
          'Failed to fetch audits: ${response.reasonPhrase}',
          statusCode: response.statusCode,
          responseBody: errorBody,
        );
      }
    } on AuthException catch (e) {
      developer.log(
        '❌ Auth Exception: ${e.message}',
        name: 'AuditListService'
      );
      throw AuditServiceException(
        'Authentication failed: ${e.message}',
        statusCode: 401,
      );
    } catch (e, stackTrace) {
      developer.log(
        '❌ Unexpected error: $e',
        name: 'AuditListService',
        error: e,
        stackTrace: stackTrace
      );
      throw AuditServiceException(
        'An unexpected error occurred: ${e.toString()}',
      );
    }
  }

  /// Fetch a specific audit by ID
  Future<AssetAuditMismatch?> fetchAuditById(String auditId) async {
    try {
      developer.log(
        '📡 Fetching audit with ID: $auditId',
        name: 'AuditListService'
      );

      // Assuming there's an endpoint for getting single audit
      final endpoint = 'Asset/assetAudit-mismatch/$auditId';
      
      final response = await _authMiddleware.get(
        endpoint,
        requiresAuth: true,
      );

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        developer.log(
          '✅ Successfully fetched audit: $auditId',
          name: 'AuditListService'
        );
        return AssetAuditMismatch.fromJson(jsonData);
      } else if (response.statusCode == 404) {
        developer.log(
          '⚠️ Audit not found: $auditId',
          name: 'AuditListService'
        );
        return null;
      } else {
        throw AuditServiceException(
          'Failed to fetch audit: ${response.reasonPhrase}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      developer.log(
        '❌ Error fetching audit by ID: $e',
        name: 'AuditListService'
      );
      rethrow;
    }
  }

  /// Resolve an audit mismatch
  Future<bool> resolveAudit(String auditId, {String? notes}) async {
    try {
      developer.log(
        '📝 Resolving audit: $auditId',
        name: 'AuditListService'
      );

      final endpoint = 'Asset/assetAudit-mismatch/$auditId/resolve';
      
      final response = await _authMiddleware.post(
        endpoint,
        body: {
          'auditId': auditId,
          'notes': notes ?? '',
          'resolvedAt': DateTime.now().toIso8601String(),
        },
        requiresAuth: true,
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        developer.log(
          '✅ Audit resolved successfully: $auditId',
          name: 'AuditListService'
        );
        return true;
      } else {
        developer.log(
          '❌ Failed to resolve audit - Status: ${response.statusCode}',
          name: 'AuditListService'
        );
        throw AuditServiceException(
          'Failed to resolve audit: ${response.reasonPhrase}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      developer.log(
        '❌ Error resolving audit: $e',
        name: 'AuditListService'
      );
      rethrow;
    }
  }

  /// Update an audit
  Future<bool> updateAudit(String auditId, Map<String, dynamic> updates) async {
    try {
      developer.log(
        '📝 Updating audit: $auditId',
        name: 'AuditListService'
      );

      final response = await _authMiddleware.put(
        ApiEndPoints.updateAsset,
        body: {
          'id': auditId,
          ...updates,
        },
        requiresAuth: true,
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        developer.log(
          '✅ Audit updated successfully: $auditId',
          name: 'AuditListService'
        );
        return true;
      } else {
        developer.log(
          '❌ Failed to update audit - Status: ${response.statusCode}',
          name: 'AuditListService'
        );
        throw AuditServiceException(
          'Failed to update audit: ${response.reasonPhrase}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      developer.log(
        '❌ Error updating audit: $e',
        name: 'AuditListService'
      );
      rethrow;
    }
  }

  /// Fetch audits by location
  Future<List<AssetAuditMismatch>> fetchAuditsByLocation(String location) async {
    try {
      developer.log(
        '📡 Fetching audits for location: $location',
        name: 'AuditListService'
      );

      final endpoint = 'Asset/assetAudit-mismatch/location/$location';
      
      final response = await _authMiddleware.get(
        endpoint,
        requiresAuth: true,
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = jsonDecode(response.body);
        developer.log(
          '✅ Found ${jsonData.length} audits for location: $location',
          name: 'AuditListService'
        );
        return jsonData
            .map((json) => AssetAuditMismatch.fromJson(json))
            .toList();
      } else if (response.statusCode == 404) {
        return [];
      } else {
        throw AuditServiceException(
          'Failed to fetch audits by location: ${response.reasonPhrase}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      developer.log(
        '❌ Error fetching audits by location: $e',
        name: 'AuditListService'
      );
      rethrow;
    }
  }

  /// Fetch audits by department
  Future<List<AssetAuditMismatch>> fetchAuditsByDepartment(String department) async {
    try {
      developer.log(
        '📡 Fetching audits for department: $department',
        name: 'AuditListService'
      );

      final endpoint = 'Asset/assetAudit-mismatch/department/$department';
      
      final response = await _authMiddleware.get(
        endpoint,
        requiresAuth: true,
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = jsonDecode(response.body);
        developer.log(
          '✅ Found ${jsonData.length} audits for department: $department',
          name: 'AuditListService'
        );
        return jsonData
            .map((json) => AssetAuditMismatch.fromJson(json))
            .toList();
      } else if (response.statusCode == 404) {
        return [];
      } else {
        throw AuditServiceException(
          'Failed to fetch audits by department: ${response.reasonPhrase}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      developer.log(
        '❌ Error fetching audits by department: $e',
        name: 'AuditListService'
      );
      rethrow;
    }
  }

  /// Batch resolve multiple audits
  Future<bool> batchResolveAudits(List<String> auditIds, {String? notes}) async {
    try {
      developer.log(
        '📝 Batch resolving ${auditIds.length} audits',
        name: 'AuditListService'
      );

      final endpoint = 'Asset/assetAudit-mismatch/batch-resolve';
      
      final response = await _authMiddleware.post(
        endpoint,
        body: {
          'auditIds': auditIds,
          'notes': notes ?? '',
          'resolvedAt': DateTime.now().toIso8601String(),
        },
        requiresAuth: true,
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        developer.log(
          '✅ Batch resolved ${auditIds.length} audits successfully',
          name: 'AuditListService'
        );
        return true;
      } else {
        throw AuditServiceException(
          'Failed to batch resolve audits: ${response.reasonPhrase}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      developer.log(
        '❌ Error batch resolving audits: $e',
        name: 'AuditListService'
      );
      rethrow;
    }
  }

  /// Get audit statistics
  Future<Map<String, dynamic>> fetchAuditStatistics() async {
    try {
      developer.log(
        '📊 Fetching audit statistics',
        name: 'AuditListService'
      );

      final endpoint = 'Asset/assetAudit-mismatch/statistics';
      
      final response = await _authMiddleware.get(
        endpoint,
        requiresAuth: true,
      );

      if (response.statusCode == 200) {
        final stats = jsonDecode(response.body);
        developer.log(
          '✅ Statistics fetched successfully',
          name: 'AuditListService'
        );
        return stats;
      } else {
        throw AuditServiceException(
          'Failed to fetch statistics: ${response.reasonPhrase}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      developer.log(
        '❌ Error fetching statistics: $e',
        name: 'AuditListService'
      );
      rethrow;
    }
  }
}

/// Custom exception for audit service errors
class AuditServiceException implements Exception {
  final String message;
  final int? statusCode;
  final String? responseBody;

  AuditServiceException(
    this.message, {
    this.statusCode,
    this.responseBody,
  });

  @override
  String toString() {
    final buffer = StringBuffer('AuditServiceException: $message');
    if (statusCode != null) {
      buffer.write(' (Status: $statusCode)');
    }
    if (responseBody != null) {
      buffer.write('\nResponse: $responseBody');
    }
    return buffer.toString();
  }
}