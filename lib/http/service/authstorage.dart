import 'dart:convert';
import 'package:itrack/http/model/authmodels.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthStorage {
  static const String _authTokenKey = 'auth_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userDataKey = 'user_data';
  static const String _tokenExpiryKey = 'token_expiry';
  static const String _isFirstLoginKey = 'is_first_login';

  static AuthStorage? _instance;
  SharedPreferences? _prefs;

  // Singleton pattern
  static AuthStorage get instance {
    _instance ??= AuthStorage._internal();
    return _instance!;
  }

  AuthStorage._internal();

  // Initialize SharedPreferences
  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  // Save authentication data
  Future<void> saveAuthData({
    required String? token,
    String? refreshToken,
    Map<String, dynamic>? userData,
    DateTime? expiryTime,
    bool? isFirstLogin,
  }) async {
    await init();
    
    if (token != null) {
      await _prefs!.setString(_authTokenKey, token);
      print('Token saved successfully'); // Debug log
    }
    
    if (refreshToken != null) {
      await _prefs!.setString(_refreshTokenKey, refreshToken);
    }
    
    if (userData != null) {
      await _prefs!.setString(_userDataKey, jsonEncode(userData));
    }
    
    if (expiryTime != null) {
      await _prefs!.setString(_tokenExpiryKey, expiryTime.toIso8601String());
    }
    
    if (isFirstLogin != null) {
      await _prefs!.setBool(_isFirstLoginKey, isFirstLogin);
    }
  }

  // Get auth token
  Future<String?> getAuthToken() async {
    await init();
    final token = _prefs!.getString(_authTokenKey);
    print('🔍 getAuthToken called - Token: ${token != null ? "EXISTS (${token.substring(0, 20)}...)" : "NULL"}');
    return token;
  }

  // Get refresh token
  Future<String?> getRefreshToken() async {
    await init();
    return _prefs!.getString(_refreshTokenKey);
  }

  // Get user data
  Future<Map<String, dynamic>?> getUserData() async {
    await init();
    final userDataString = _prefs!.getString(_userDataKey);
    if (userDataString != null) {
      return jsonDecode(userDataString);
    }
    return null;
  }

  // Get user object
  Future<User?> getUser() async {
    final userData = await getUserData();
    if (userData != null) {
      return User.fromJson(userData);
    }
    return null;
  }

  // Get token expiry
  Future<DateTime?> getTokenExpiry() async {
    await init();
    final expiryString = _prefs!.getString(_tokenExpiryKey);
    if (expiryString != null) {
      return DateTime.parse(expiryString);
    }
    return null;
  }

  // Check if token is expired
  Future<bool> isTokenExpired() async {
    final expiry = await getTokenExpiry();
    if (expiry == null) {
      // If no expiry is set, assume token is still valid for better UX
      // This handles cases where the server doesn't send expiry
      return false; 
    }
    final isExpired = DateTime.now().isAfter(expiry);
    print('Token expired check: $isExpired'); // Debug log
    return isExpired;
  }

  // Check if user is authenticated
  Future<bool> isAuthenticated() async {
    final token = await getAuthToken();
    if (token == null) {
      print('Authentication check: No token found');
      return false;
    }
    
    final isExpired = await isTokenExpired();
    final authenticated = !isExpired;
    print('Authentication check: ${authenticated ? "Authenticated" : "Not authenticated"}');
    return authenticated;
  }

  // Check if first login
  Future<bool> isFirstLogin() async {
    await init();
    return _prefs!.getBool(_isFirstLoginKey) ?? false;
  }

  // Update auth token (for refresh scenarios)
  Future<void> updateAuthToken(String token, {DateTime? expiryTime}) async {
    await init();
    await _prefs!.setString(_authTokenKey, token);
    
    if (expiryTime != null) {
      await _prefs!.setString(_tokenExpiryKey, expiryTime.toIso8601String());
    }
    print('Token updated successfully');
  }

  // Clear all auth data
  Future<void> clearAuthData() async {
    await init();
    await _prefs!.remove(_authTokenKey);
    await _prefs!.remove(_refreshTokenKey);
    await _prefs!.remove(_userDataKey);
    await _prefs!.remove(_tokenExpiryKey);
    await _prefs!.remove(_isFirstLoginKey);
    print('All auth data cleared');
  }

  // Save complete auth response
  Future<void> saveAuthResponse(AuthResponse response) async {
    print('🔵 saveAuthResponse called');
    print('🔵 Token from response: ${response.token != null ? response.token!.substring(0, 20) + "..." : "NULL"}');
    print('🔵 Refresh token from response: ${response.refreshToken != null ? "EXISTS" : "NULL"}');
    
    final expiryTime = response.expiration != null 
        ? DateTime.parse(response.expiration!)
        : DateTime.now().add(const Duration(days: 30)); // Default 30 days for better UX

    await saveAuthData(
      token: response.token,
      refreshToken: response.refreshToken,
      userData: response.data,
      expiryTime: expiryTime,
      isFirstLogin: response.isFirstLogin ?? false,
    );
    
    print('✅ Auth response saved successfully');
    
    // Verify it was saved
    final savedToken = await getAuthToken();
    print('🔍 Verification - Token saved: ${savedToken != null ? "YES" : "NO"}');
    if (savedToken != null) {
      print('🔍 Saved token preview: ${savedToken.substring(0, 20)}...');
    }
  }

  // Get auth headers for API calls
  Future<Map<String, String>> getAuthHeaders() async {
    print('🔵 getAuthHeaders called');
    final token = await getAuthToken();
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };
    
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
      print('✅ Auth headers prepared with Bearer token');
    } else {
      print('🔴 WARNING: No token available for auth headers');
      print('🔍 Checking SharedPreferences directly...');
      await init();
      final allKeys = _prefs!.getKeys();
      print('🔍 All keys in SharedPreferences: $allKeys');
      final directToken = _prefs!.getString(_authTokenKey);
      print('🔍 Direct token check: ${directToken != null ? "EXISTS" : "NULL"}');
    }
    
    return headers;
  }

  // Check if refresh is needed (token expires in next 5 minutes)
  Future<bool> shouldRefreshToken() async {
    final expiry = await getTokenExpiry();
    if (expiry == null) {
      // If no expiry, check if we have refresh token
      final refreshToken = await getRefreshToken();
      return refreshToken != null; // Only refresh if we have refresh token
    }
    
    final fiveMinutesFromNow = DateTime.now().add(const Duration(minutes: 5));
    return fiveMinutesFromNow.isAfter(expiry);
  }

  // Additional helper methods for debugging
  Future<void> debugAuthState() async {
    print('=== AUTH DEBUG STATE ===');
    print('Has token: ${await getAuthToken() != null}');
    print('Has refresh token: ${await getRefreshToken() != null}');
    print('Has user data: ${await getUserData() != null}');
    print('Token expired: ${await isTokenExpired()}');
    print('Is authenticated: ${await isAuthenticated()}');
    print('========================');
  }
}