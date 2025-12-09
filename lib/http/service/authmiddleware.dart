import 'dart:convert';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:itrack/http/model/authmodels.dart';
import 'package:itrack/http/service/authservice.dart';
import 'package:itrack/http/service/authstorage.dart';
import 'package:itrack/http/service/endpoints.dart'; // Add this import

class AuthMiddleware {
  // Use baseUrl from ApiEndPoints instead of hardcoded value
  static String get baseUrl => ApiEndPoints.baseUrl;
  
  static AuthMiddleware? _instance;
  final AuthStorage _authStorage = AuthStorage.instance;
  final AuthService _authService = AuthService();

  // Singleton pattern
  static AuthMiddleware get instance {
    _instance ??= AuthMiddleware._internal();
    return _instance!;
  }

  AuthMiddleware._internal();

  // Initialize middleware
  Future<void> init() async {
    await _authStorage.init();
    print('🟢 AuthMiddleware initialized with baseUrl: $baseUrl');
    
    // Debug: Check if we have auth data
    final hasToken = await _authStorage.getAuthToken() != null;
    final isAuth = await _authStorage.isAuthenticated();
    print('🔍 AuthMiddleware init check - Has token: $hasToken, Is authenticated: $isAuth');
  }

  // Make authenticated HTTP request with automatic token refresh
  Future<http.Response> authenticatedRequest({
    required String method,
    required String endpoint,
    Map<String, dynamic>? body,
    Map<String, String>? additionalHeaders,
    bool requiresAuth = true,
  }) async {
    // Check if authentication is required
    if (requiresAuth) {
      final isAuthenticated = await _authStorage.isAuthenticated();
      if (!isAuthenticated) {
        print('🔴 User not authenticated - redirecting to login');
        print('🔍 Debug: Checking auth storage state...');
        await _authStorage.debugAuthState();
        await _handleAuthFailure();
        throw AuthException('User not authenticated');
      }

      // Check if token needs refresh
      final shouldRefresh = await _authStorage.shouldRefreshToken();
      if (shouldRefresh) {
        print('🔄 Token needs refresh, attempting refresh...');
        final refreshSuccess = await _refreshTokenIfNeeded();
        if (!refreshSuccess) {
          print('🔴 Token refresh failed');
          await _handleAuthFailure();
          throw AuthException('Failed to refresh token');
        }
        print('🟢 Token refreshed successfully');
      }
    }

    // Get headers with auth token
    print('🔵 AuthMiddleware: Getting auth headers...');
    final headers = await _authStorage.getAuthHeaders();
    if (additionalHeaders != null) {
      headers.addAll(additionalHeaders);
    }

    // Build the full URL using ApiEndPoints baseUrl
    final fullUrl = '$baseUrl$endpoint';
    final uri = Uri.parse(fullUrl);
    
    print('🟡 Making API request to: $fullUrl');
    print('🔵 Headers: ${headers.containsKey('Authorization') ? "✅ Has Auth Token" : "🔴 NO AUTH TOKEN"}');
    if (headers.containsKey('Authorization')) {
      final authHeader = headers['Authorization']!;
      print('🔵 Auth header preview: ${authHeader.substring(0, 30)}...');
    }

    http.Response response;

    try {
      switch (method.toUpperCase()) {
        case 'GET':
          response = await http.get(uri, headers: headers);
          break;
        case 'POST':
          response = await http.post(
            uri,
            headers: headers,
            body: body != null ? jsonEncode(body) : null,
          );
          break;
        case 'PUT':
          response = await http.put(
            uri,
            headers: headers,
            body: body != null ? jsonEncode(body) : null,
          );
          break;
        case 'DELETE':
          response = await http.delete(uri, headers: headers);
          break;
        case 'PATCH':
          response = await http.patch(
            uri,
            headers: headers,
            body: body != null ? jsonEncode(body) : null,
          );
          break;
        default:
          throw ArgumentError('Unsupported HTTP method: $method');
      }

      // Handle response
      await _handleResponse(response, fullUrl, requiresAuth);
      return response;
    } catch (e) {
      print('🔴 Network error: $e');
      rethrow;
    }
  }

  // Handle response and check for auth errors
  Future<void> _handleResponse(
    http.Response response, 
    String endpoint, 
    bool requiresAuth,
  ) async {
    print('🔵 Response Status: ${response.statusCode} for $endpoint');

    // Check for unauthorized response
    if (response.statusCode == 401 && requiresAuth) {
      print('🔴 401 Unauthorized - attempting token refresh...');
      // Try to refresh token once
      final refreshSuccess = await _refreshTokenIfNeeded();
      
      if (!refreshSuccess) {
        // Refresh failed, logout user
        print('🔴 Token refresh failed - logging out');
        await _handleAuthFailure();
        throw AuthException('Authentication failed');
      }
      print('🟢 Token refreshed after 401');
    }

    // Check for other auth-related errors
    if (response.statusCode == 403) {
      print('🔴 403 Forbidden');
      throw AuthException('Access forbidden');
    }

    // Log API errors for debugging
    if (response.statusCode >= 400) {
      print('🔴 API Error - Endpoint: $endpoint, Status: ${response.statusCode}, Body: ${response.body}');
    } else {
      print('🟢 API Success - Endpoint: $endpoint, Status: ${response.statusCode}');
    }
  }

  // Refresh token if needed
  Future<bool> _refreshTokenIfNeeded() async {
    try {
      final refreshToken = await _authStorage.getRefreshToken();
      if (refreshToken == null) {
        print('🔴 No refresh token available');
        return false;
      }

      print('🔄 Refreshing token...');
      final response = await _authService.refreshToken(refreshToken);
      
      if (response.success && response.token != null) {
        await _authStorage.saveAuthResponse(response);
        print('🟢 Token refresh successful');
        return true;
      }
      
      print('🔴 Token refresh failed in API response');
      return false;
    } catch (e) {
      print('🔴 Token refresh failed: $e');
      return false;
    }
  }

  // Handle authentication failure
  Future<void> _handleAuthFailure() async {
    try {
      print('🟡 Handling auth failure...');
      // Clear stored auth data
      await _authStorage.clearAuthData();
      
      // Navigate to login screen
      Get.offAllNamed('/login');
      
      // Show message to user
      Get.snackbar(
        'Session Expired',
        'Please login again to continue',
        snackPosition: SnackPosition.BOTTOM,
      );
      print('🟢 Auth failure handled - user redirected to login');
    } catch (e) {
      print('🔴 Error handling auth failure: $e');
    }
  }

  // Validate current session
  Future<bool> validateSession() async {
    try {
      final isAuthenticated = await _authStorage.isAuthenticated();
      print('🔍 Session validation - isAuthenticated: $isAuthenticated');
      
      if (!isAuthenticated) {
        return false;
      }

      // Check if token needs refresh
      final shouldRefresh = await _authStorage.shouldRefreshToken();
      if (shouldRefresh) {
        print('🔄 Session needs refresh');
        return await _refreshTokenIfNeeded();
      }

      print('🟢 Session is valid');
      return true;
    } catch (e) {
      print('🔴 Session validation failed: $e');
      return false;
    }
  }

  // Force logout
  Future<void> forceLogout() async {
    try {
      print('🟡 Force logout initiated');
      final token = await _authStorage.getAuthToken();
      if (token != null) {
        // Try to logout from server
        await _authService.logout(token);
      }
    } catch (e) {
      print('🔴 Server logout failed: $e');
    } finally {
      await _handleAuthFailure();
    }
  }

  // Get current user
  Future<User?> getCurrentUser() async {
    return await _authStorage.getUser();
  }

  // Check if user is authenticated
  Future<bool> isAuthenticated() async {
    final isAuth = await _authStorage.isAuthenticated();
    print('🔍 Auth check: $isAuth');
    return isAuth;
  }

  // Get auth token
  Future<String?> getAuthToken() async {
    final token = await _authStorage.getAuthToken();
    print('🔍 Token check: ${token != null ? "Token exists" : "No token"}');
    return token;
  }

  // Convenience methods for common HTTP operations
  Future<http.Response> get(String endpoint, {bool requiresAuth = true}) async {
    return await authenticatedRequest(
      method: 'GET',
      endpoint: endpoint,
      requiresAuth: requiresAuth,
    );
  }

  Future<http.Response> post(
    String endpoint, {
    Map<String, dynamic>? body,
    bool requiresAuth = true,
  }) async {
    return await authenticatedRequest(
      method: 'POST',
      endpoint: endpoint,
      body: body,
      requiresAuth: requiresAuth,
    );
  }

  Future<http.Response> put(
    String endpoint, {
    Map<String, dynamic>? body,
    bool requiresAuth = true,
  }) async {
    return await authenticatedRequest(
      method: 'PUT',
      endpoint: endpoint,
      body: body,
      requiresAuth: requiresAuth,
    );
  }

  Future<http.Response> delete(String endpoint, {bool requiresAuth = true}) async {
    return await authenticatedRequest(
      method: 'DELETE',
      endpoint: endpoint,
      requiresAuth: requiresAuth,
    );
  }

  Future<http.Response> patch(
    String endpoint, {
    Map<String, dynamic>? body,
    bool requiresAuth = true,
  }) async {
    return await authenticatedRequest(
      method: 'PATCH',
      endpoint: endpoint,
      body: body,
      requiresAuth: requiresAuth,
    );
  }
}

// Custom exception for auth-related errors
class AuthException implements Exception {
  final String message;
  
  AuthException(this.message);
  
  @override
  String toString() => 'AuthException: $message';
}

// Auth middleware binding for GetX
class AuthBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AuthMiddleware>(() => AuthMiddleware.instance);
  }
}