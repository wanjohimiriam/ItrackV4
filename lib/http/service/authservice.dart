// ignore_for_file: curly_braces_in_flow_control_structures, avoid_print

import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:itrack/http/model/authmodels.dart';
import 'package:itrack/http/service/endpoints.dart';  // Add this import


class AuthService {
  // Use endpoints from ApiEndPoints class
  static String get baseUrl => ApiEndPoints.baseUrl;

  // Helper method to log API calls
  void _logApiCall(
    String endpoint,
    String method,
    Map<String, dynamic>? requestBody,
  ) {
    print('🌐 API Call: $method $endpoint');
    if (requestBody != null) {
      // Create safe request body without sensitive data
      final safeBody = Map<String, dynamic>.from(requestBody);
      // Remove sensitive fields for logging
      safeBody.remove('password');
      safeBody.remove('temporaryPassword');
      safeBody.remove('newPassword');
      safeBody.remove('confirmPassword');
      if (safeBody.containsKey('password'))
        safeBody['password'] = '***hidden***';
      if (safeBody.containsKey('temporaryPassword'))
        safeBody['temporaryPassword'] = '***hidden***';
      if (safeBody.containsKey('newPassword'))
        safeBody['newPassword'] = '***hidden***';
      if (safeBody.containsKey('confirmPassword'))
        safeBody['confirmPassword'] = '***hidden***';

      print('📤 Request Body: ${jsonEncode(safeBody)}');
    }
  }

  void _logApiResponse(String endpoint, int statusCode, dynamic responseData) {
    print('📥 API Response: $endpoint');
    print('📊 Status Code: $statusCode');
    print('📋 Raw Response: $responseData');

    if (responseData is Map<String, dynamic>) {
      // Create safe response data without sensitive info
      final safeResponse = Map<String, dynamic>.from(responseData);
      if (safeResponse.containsKey('token')) {
        final token = safeResponse['token'];
        safeResponse['token'] = token != null
            ? 'Bearer ${token.toString().substring(0, 10)}...'
            : 'null';
      }
      if (safeResponse.containsKey('refreshToken')) {
        final refreshToken = safeResponse['refreshToken'];
        safeResponse['refreshToken'] = refreshToken != null
            ? 'Refresh ${refreshToken.toString().substring(0, 10)}...'
            : 'null';
      }

      print('📋 Sanitized Response: ${jsonEncode(safeResponse)}');
    }
  }

  void _logError(String endpoint, dynamic error) {
    print('❌ API Error: $endpoint');
    print('💥 Error Details: $error');
  }

  // Helper method to check if status code indicates success
  bool _isSuccessStatusCode(int statusCode) {
    return statusCode >= 200 && statusCode < 300;
  }

  // Login endpoint - Uses ApiEndPoints
  Future<AuthResponse> login(LoginRequest request) async {
    final endpoint = ApiEndPoints.login;
    _logApiCall(endpoint, 'POST', request.toJson());

    try {
      print('🔐 Attempting login for user: ${request.email}');

      final response = await http.post(
        Uri.parse('${baseUrl}$endpoint'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(request.toJson()),
      );

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      _logApiResponse(endpoint, response.statusCode, data);

      if (_isSuccessStatusCode(response.statusCode)) {
        try {
          // Check for success using 'flag' field from API response
          final isSuccess = data['flag'] == true || data['success'] == true;
          
          if ((data['token'] != null) && isSuccess) {
            return AuthResponse(
              success: true, // Always true for successful response with token
              message: data['message'] ?? 'Login successful',
              data: data, // Pass full data for user info
              token: data['token'],
              refreshToken: data['refreshToken'],
              // Removed isFirstLogin since it's not implemented in current API
            );
          }
          
          // Try to parse using AuthResponse.fromJson as fallback
          final authResponse = AuthResponse.fromJson(data);
          return authResponse;
        } catch (parseError) {
          // Fallback: create manual success response if we have token and flag is true
          if (data['token'] != null && data['flag'] == true) {
            return AuthResponse(
              success: true,
              message: data['message'] ?? 'Login successful',
              data: data,
              token: data['token'],
            );
          }
          
          return AuthResponse(
            success: false,
            message: data['message'] ?? 'Login failed',
          );
        }
      } else {
        print('❌ Login failed with status ${response.statusCode}');
        return AuthResponse(
          success: false,
          message: data['message'] ?? 'Login failed',
        );
      }
    } catch (e) {
      _logError(endpoint, e);
      print('💔 Login network error for: ${request.email}');
      return AuthResponse(success: false, message: 'Network error: $e');
    }
  }

  // COMMENTED OUT: First login attempt (not implemented in current API)
  // Future<AuthResponse> firstLoginAttempt(FirstLoginRequest request) async {
  //   const endpoint = 'Account/first-login-reset/';
  //   _logApiCall(endpoint, 'POST', request.toJson());

  //   try {
  //     print('🔄 First login attempt for user: ${request.email}');

  //     final response = await http.post(
  //       Uri.parse('${baseUrl}$endpoint'),
  //       headers: {'Content-Type': 'application/json'},
  //       body: jsonEncode(request.toJson()),
  //     );

  //     final data = jsonDecode(response.body) as Map<String, dynamic>;
  //     _logApiResponse(endpoint, response.statusCode, data);

  //     if (_isSuccessStatusCode(response.statusCode)) {
  //       try {
  //         final authResponse = AuthResponse.fromJson(data);
  //         print('✅ First login reset successful for: ${request.email}');
  //         print('🎫 Token received: ${authResponse.token != null ? "YES" : "NO"}');

  //         // Force success and ensure we have proper data structure
  //         return AuthResponse(
  //           success: true,
  //           message: authResponse.message ?? data['message'] ?? 'Password reset successful',
  //           data: data, // Pass full data
  //           token: authResponse.token ?? data['token'],
  //           refreshToken: authResponse.refreshToken ?? data['refreshToken'],
  //           isFirstLogin: false, // No longer first login after reset
  //         );
  //       } catch (parseError) {
  //         print('⚠️ First login response parsing error, creating manual response');
          
  //         // Fallback: create manual success response
  //         return AuthResponse(
  //           success: true,
  //           message: data['message'] ?? 'Password reset successful',
  //           data: data,
  //           token: data['token'],
  //           refreshToken: data['refreshToken'],
  //           isFirstLogin: false,
  //         );
  //       }
  //     } else {
  //       print('❌ First login reset failed with status ${response.statusCode}');
  //       return AuthResponse(
  //         success: false,
  //         message: data['message'] ?? 'First login reset failed',
  //       );
  //     }
  //   } catch (e) {
  //     _logError(endpoint, e);
  //     print('💔 First login reset network/system error for: ${request.email}');
  //     return AuthResponse(success: false, message: 'Network error: $e');
  //   }
  // }

  // Forgot password - Uses ApiEndPoints
  Future<AuthResponse> forgotPassword(ForgotPasswordRequest request) async {
    final endpoint = ApiEndPoints.forgotPassword;
    _logApiCall(endpoint, 'POST', request.toJson());

    try {
      print('📧 Sending forgot password request for: ${request.email}');

      final response = await http.post(
        Uri.parse('${baseUrl}$endpoint'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(request.toJson()),
      );

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      _logApiResponse(endpoint, response.statusCode, data);

      if (_isSuccessStatusCode(response.statusCode)) {
        final authResponse = AuthResponse.fromJson(data);
        print('✅ Forgot password request sent successfully to: ${request.email}');

        return authResponse;
      } else {
        print('❌ Forgot password request failed with status ${response.statusCode}');
        return AuthResponse(
          success: false,
          message: data['message'] ?? 'Forgot password request failed',
        );
      }
    } catch (e) {
      _logError(endpoint, e);
      return AuthResponse(success: false, message: 'Network error: $e');
    }
  }

  // Reset password - Uses ApiEndPoints with token replacement
  Future<AuthResponse> resetPassword(ResetPasswordRequest request) async {
    // Replace {token} placeholder in ApiEndPoints.resetPassword with actual token
    final endpoint = ApiEndPoints.resetPassword.replaceAll('{token}', request.code);
    _logApiCall(endpoint, 'POST', request.toJson());

    try {
      print('🔐 Resetting password for: ${request.email}');
      print('🔑 Reset code provided: ${request.code.isNotEmpty ? "YES" : "NO"}');

      final response = await http.post(
        Uri.parse('${baseUrl}$endpoint'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(request.toJson()),
      );

      print('📊 Password Reset Response Status: ${response.statusCode}');
      print('📋 Password Reset Response Body: ${response.body}');

      // Handle different response types
      dynamic data;
      try {
        data = jsonDecode(response.body);
      } catch (jsonError) {
        print('⚠️ Response is not valid JSON: ${response.body}');
        // If response is not JSON but status indicates success, treat as success
        if (_isSuccessStatusCode(response.statusCode)) {
          print('✅ Password reset successful (non-JSON response)');
          return AuthResponse(
            success: true,
            message: 'Password reset successful',
          );
        } else {
          print('❌ Password reset failed (non-JSON response)');
          return AuthResponse(success: false, message: 'Password reset failed');
        }
      }

      _logApiResponse(endpoint, response.statusCode, data);

      if (_isSuccessStatusCode(response.statusCode)) {
        try {
          final authResponse = AuthResponse.fromJson(data);
          // Force success to true since API returned successful status
          return AuthResponse(
            success: true,
            message: authResponse.message ?? data['message'] ?? 'Password reset successful',
            data: authResponse.data,
            token: authResponse.token,
            refreshToken: authResponse.refreshToken,
          );
        } catch (parseError) {
          // Create manual success response
          return AuthResponse(
            success: true,
            message: data['message'] ?? 'Password reset successful',
          );
        }
      } else {
        print('❌ Password reset failed with status ${response.statusCode}');
        final message = data is Map
            ? (data['message'] ?? 'Password reset failed')
            : 'Password reset failed';

        return AuthResponse(success: false, message: message);
      }
    } catch (e) {
      _logError(endpoint, e);
      print('💔 Password reset network/system error for: ${request.email}');
      return AuthResponse(success: false, message: 'Network error: $e');
    }
  }

  // Refresh token - Uses ApiEndPoints
  Future<AuthResponse> refreshToken(String refreshToken) async {
    final endpoint = ApiEndPoints.refreshIndicator;
    print('🌐 API Call: POST $endpoint');
    print('🔄 Attempting token refresh...');
    print('🎫 Refresh token provided: ${refreshToken.isNotEmpty ? "YES" : "NO"}');

    try {
      final response = await http.post(
        Uri.parse('${baseUrl}$endpoint'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $refreshToken',
        },
      );

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      _logApiResponse(endpoint, response.statusCode, data);

      if (_isSuccessStatusCode(response.statusCode)) {
        final authResponse = AuthResponse.fromJson(data);
        print('✅ Token refresh successful');
        print('🎫 New token received: ${authResponse.token != null ? "YES" : "NO"}');
        print('🔄 New refresh token received: ${authResponse.refreshToken != null ? "YES" : "NO"}');

        return authResponse;
      } else {
        print('❌ Token refresh failed with status ${response.statusCode}');
        return AuthResponse(
          success: false,
          message: data['message'] ?? 'Token refresh failed',
        );
      }
    } catch (e) {
      _logError(endpoint, e);
      return AuthResponse(success: false, message: 'Network error: $e');
    }
  }

  // Logout - Uses ApiEndPoints
  Future<AuthResponse> logout(String token) async {
    final endpoint = ApiEndPoints.logout;
    print('🌐 API Call: POST $endpoint');
    print('🚪 Attempting logout...');
    print('🎫 Token provided: ${token.isNotEmpty ? "YES" : "NO"}');

    try {
      final response = await http.post(
        Uri.parse('${baseUrl}$endpoint'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (_isSuccessStatusCode(response.statusCode)) {
        print('✅ Logout successful');
        return AuthResponse(success: true, message: 'Logged out successfully');
      } else {
        print('❌ Logout failed with status ${response.statusCode}');
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        _logApiResponse(endpoint, response.statusCode, data);

        return AuthResponse(success: false, message: 'Logout failed');
      }
    } catch (e) {
      _logError(endpoint, e);
      return AuthResponse(success: false, message: 'Network error: $e');
    }
  }

  // Helper method to log service health
  void logServiceHealth() {
    print('🏥 AuthService Health Check');
    print('🌍 Base URL: $baseUrl');
    print('⚡ Service Status: Active');
  }

  // Debug method to test password reset endpoint response
  Future<void> debugPasswordResetResponse(ResetPasswordRequest request) async {
    final endpoint = ApiEndPoints.resetPassword.replaceAll('{token}', request.code);
    print('🔍 DEBUG: Testing password reset endpoint...');

    try {
      final response = await http.post(
        Uri.parse('${baseUrl}$endpoint'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(request.toJson()),
      );

      print('🔍 DEBUG Results:');
      print('📊 Status Code: ${response.statusCode}');
      print('📋 Headers: ${response.headers}');
      print('📋 Body: ${response.body}');
      print('🔍 Is Success Status: ${_isSuccessStatusCode(response.statusCode)}');
      print('🔍 Body Type: ${response.body.runtimeType}');

      if (response.body.isNotEmpty) {
        try {
          final parsed = jsonDecode(response.body);
          print('🔍 Parsed JSON Type: ${parsed.runtimeType}');
          print('🔍 Parsed JSON: $parsed');
        } catch (e) {
          print('🔍 JSON Parse Error: $e');
        }
      }
    } catch (e) {
      print('🔍 DEBUG Error: $e');
    }
  }

  // COMMENTED OUT: Debug methods for first login (not implemented in current API)
  // Future<void> debugFirstLoginResponse(FirstLoginRequest request) async {
  //   const endpoint = 'Account/first-login-reset/';
  //   print('🔍 DEBUG: Testing first login reset endpoint...');

  //   try {
  //     final response = await http.post(
  //       Uri.parse('${baseUrl}$endpoint'),
  //       headers: {'Content-Type': 'application/json'},
  //       body: jsonEncode(request.toJson()),
  //     );

  //     print('🔍 FIRST LOGIN DEBUG Results:');
  //     print('📊 Status Code: ${response.statusCode}');
  //     print('📋 Headers: ${response.headers}');
  //     print('📋 Body: ${response.body}');
  //     print('🔍 Is Success Status: ${_isSuccessStatusCode(response.statusCode)}');
  //     print('🔍 Body Type: ${response.body.runtimeType}');

  //     if (response.body.isNotEmpty) {
  //       try {
  //         final parsed = jsonDecode(response.body);
  //         print('🔍 Parsed JSON Type: ${parsed.runtimeType}');
  //         print('🔍 Parsed JSON: $parsed');
          
  //         // Check for specific fields
  //         if (parsed is Map<String, dynamic>) {
  //           print('🔍 Token in response: ${parsed['token'] != null}');
  //           print('🔍 User data in response: ${parsed['user'] != null || parsed['data'] != null}');
  //           print('🔍 Success flag: ${parsed['success']}');
  //           print('🔍 Message: ${parsed['message']}');
  //         }
  //       } catch (e) {
  //         print('🔍 JSON Parse Error: $e');
  //       }
  //     }
  //   } catch (e) {
  //     print('🔍 DEBUG Error: $e');
  //   }
  // }

  // Updated debug method for login response analysis - Uses ApiEndPoints
  Future<void> debugLoginResponse(LoginRequest request) async {
    final endpoint = ApiEndPoints.login;
    print('🔍 DEBUG: Testing login endpoint...');

    try {
      final response = await http.post(
        Uri.parse('${baseUrl}$endpoint'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(request.toJson()),
      );

      print('🔍 LOGIN DEBUG Results:');
      print('📊 Status Code: ${response.statusCode}');
      print('📋 Headers: ${response.headers}');
      print('📋 Body: ${response.body}');
      print('🔍 Is Success Status: ${_isSuccessStatusCode(response.statusCode)}');

      if (response.body.isNotEmpty) {
        try {
          final parsed = jsonDecode(response.body);
          print('🔍 Parsed JSON: $parsed');
          
          if (parsed is Map<String, dynamic>) {
            print('🔍 Token present: ${parsed['token'] != null}');
            print('🔍 User data present: ${parsed['user'] != null || parsed['data'] != null}');
          }
        } catch (e) {
          print('🔍 JSON Parse Error: $e');
        }
      }
    } catch (e) {
      print('🔍 DEBUG Error: $e');
    }
  }
}