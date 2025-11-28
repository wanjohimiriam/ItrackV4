import 'dart:convert';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:itrack/http/service/endpoints.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DashboardService {
  /// Fetch dashboard summary based on user and location
  static Future<DashboardResponse?> getDashboardSummary({
    required String userId,
    required String locationId,
  }) async {
    try {
      // ✅ Get auth token from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token') ?? '';

      if (token.isEmpty) {
        print('🔴 No auth token found, redirecting to login');
        _handleUnauthorized();
        return null;
      }

      // Build URL with query parameters
      final url = Uri.parse(
        '${ApiEndPoints.baseUrl}${ApiEndPoints.getDashboardSummary}',
      ).replace(queryParameters: {
        'UserId': userId,
        'locationId': locationId,
      });

      print('🔵 Dashboard Request URL: $url');

      // ✅ Add Authorization header
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token', // ✅ Add auth token
        },
      );

      print('🔵 Dashboard Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        print('🔵 Dashboard Response Body: ${response.body}');
        final data = json.decode(response.body);
        return DashboardResponse.fromJson(data);
      } else if (response.statusCode == 401) {
        // ✅ Handle 401 Unauthorized
        print('🔴 401 Unauthorized - Redirecting to login');
        _handleUnauthorized();
        return null;
      } else {
        print('🔴 Dashboard API Error: ${response.statusCode}');
        print('🔴 Response: ${response.body}');
        return null;
      }
    } catch (e) {
      print('🔴 Dashboard Service Exception: $e');
      return null;
    }
  }

  /// Handle unauthorized access - clear session and redirect to login
  static void _handleUnauthorized() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Clear all stored credentials
      await prefs.remove('auth_token');
      await prefs.remove('user_id');
      await prefs.remove('tenant_id');
      await prefs.remove('username');
      await prefs.remove('main_location_id');
      await prefs.remove('main_location_name');
      
      print('🟡 Cleared all credentials');
      
      // Redirect to login
      Get.offAllNamed('/login');
      
      // Show message to user
      Get.snackbar(
        'Session Expired',
        'Please login again',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
      );
    } catch (e) {
      print('🔴 Error in _handleUnauthorized: $e');
      Get.offAllNamed('/login');
    }
  }
}

/// Dashboard API Response Model
class DashboardResponse {
  final int totalAuditedAssets;
  final int todaysAuditedAssets;
  final Map<String, LocationAuditDetails> auditsByLocation;

  DashboardResponse({
    required this.totalAuditedAssets,
    required this.todaysAuditedAssets,
    required this.auditsByLocation,
  });

  factory DashboardResponse.fromJson(Map<String, dynamic> json) {
    Map<String, LocationAuditDetails> locationAudits = {};
    
    if (json['auditsByLocation'] != null) {
      (json['auditsByLocation'] as Map<String, dynamic>).forEach((key, value) {
        locationAudits[key] = LocationAuditDetails.fromJson(value);
      });
    }

    return DashboardResponse(
      totalAuditedAssets: json['totalAuditedAssets'] ?? 0,
      todaysAuditedAssets: json['todaysAuditedAssets'] ?? 0,
      auditsByLocation: locationAudits,
    );
  }

  List<LocationAudit> getLocationAuditsList() {
    return auditsByLocation.entries
        .map((entry) => LocationAudit(
              locationName: entry.key,
              details: entry.value,
            ))
        .toList();
  }
}

class LocationAuditDetails {
  final int total;
  final int matched;
  final int mismatched;
  final int notMatched;
  final int newAssets;

  LocationAuditDetails({
    required this.total,
    required this.matched,
    required this.mismatched,
    required this.notMatched,
    required this.newAssets,
  });

  factory LocationAuditDetails.fromJson(Map<String, dynamic> json) {
    return LocationAuditDetails(
      total: json['total'] ?? 0,
      matched: json['matched'] ?? 0,
      mismatched: json['mismatched'] ?? 0,
      notMatched: json['notMatched'] ?? 0,
      newAssets: json['newAssets'] ?? 0,
    );
  }
}

class LocationAudit {
  final String locationName;
  final LocationAuditDetails details;

  LocationAudit({
    required this.locationName,
    required this.details,
  });

  int get total => details.total;
  int get matched => details.matched;
  int get mismatched => details.mismatched;
  int get notMatched => details.notMatched;
  int get newAssets => details.newAssets;
}