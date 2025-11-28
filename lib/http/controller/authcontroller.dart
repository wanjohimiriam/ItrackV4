// ignore_for_file: avoid_print

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:itrack/http/model/authmodels.dart';
import 'package:itrack/http/service/authmiddleware.dart';
import 'package:itrack/http/service/authservice.dart';
import 'package:itrack/http/service/authstorage.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AuthState {
  initial,
  loading,
  authenticated,
  unauthenticated,
  firstTimeLogin,
  forgotPassword,
  resetPassword,
}

class AuthController extends GetxController {
  final AuthService _authService = AuthService();
  final AuthStorage _authStorage = AuthStorage.instance;
  final AuthMiddleware _authMiddleware = AuthMiddleware.instance;

  // ===========================================
  // AUTHENTICATION STATE & USER DATA
  // ===========================================

  // Core authentication observables
  final Rx<AuthState> _authState = AuthState.initial.obs;
  final Rx<User?> _currentUser = Rx<User?>(null);
  final RxString _errorMessage = ''.obs;
  final RxBool _isLoading = false.obs;
  final RxString _tempEmail = ''.obs;

  // ===========================================
  // UI CONTROLLERS & FORM KEYS
  // ===========================================

  // Login form
  final loginFormKey = GlobalKey<FormState>();
  final loginEmailController = TextEditingController();
  final loginPasswordController = TextEditingController();
  final RxBool obscureLoginPassword = true.obs;
  final RxBool rememberMe = true.obs;

  // First login reset form
  final firstLoginFormKey = GlobalKey<FormState>();
  final temporaryPasswordController = TextEditingController();
  final newPasswordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final RxBool obscureNewPassword = true.obs;
  final RxBool obscureConfirmPassword = true.obs;

  // Forgot password form
  final forgotPasswordFormKey = GlobalKey<FormState>();
  final forgotEmailController = TextEditingController();

  // Reset password form
  final resetPasswordFormKey = GlobalKey<FormState>();
  final otpController = TextEditingController();
  final resetNewPasswordController = TextEditingController();
  final resetConfirmPasswordController = TextEditingController();
  final RxBool obscureResetNewPassword = true.obs;
  final RxBool obscureResetConfirmPassword = true.obs;

  // ===========================================
  // GETTERS
  // ===========================================

  AuthState get authState => _authState.value;
  User? get currentUser => _currentUser.value;
  String get errorMessage => _errorMessage.value;
  bool get isLoading => _isLoading.value;
  String get tempEmail => _tempEmail.value;

  // ===========================================
  // LIFECYCLE METHODS
  // ===========================================

  @override
  void onInit() {
    super.onInit();
    print('🎯 AuthController: Initializing...');
    _initializeAuth();
  }

  @override
  void onClose() {
    print('🎯 AuthController: Closing...');
    _disposeControllers();
    super.onClose();
  }

  void _disposeControllers() {
    loginEmailController.dispose();
    loginPasswordController.dispose();
    temporaryPasswordController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    forgotEmailController.dispose();
    otpController.dispose();
    resetNewPasswordController.dispose();
    resetConfirmPasswordController.dispose();
  }

  void _logStateChange(AuthState oldState, AuthState newState) {
    print('🔄 Auth State Change: ${oldState.name} → ${newState.name}');
  }

  void _logMethodEntry(String methodName, [Map<String, dynamic>? params]) {
    print('📥 AuthController.$methodName() - Entry');
    if (params != null) {
      final safeParams = Map<String, dynamic>.from(params);
      safeParams.remove('password');
      safeParams.remove('temporaryPassword');
      safeParams.remove('newPassword');
      safeParams.remove('confirmPassword');
      if (safeParams.isNotEmpty) {
        print('📋 Parameters: $safeParams');
      }
    }
  }

  void _logMethodExit(String methodName, [String? result]) {
    print(
      '📤 AuthController.$methodName() - Exit${result != null ? " ($result)" : ""}',
    );
  }

  void _setLoading(bool loading) {
    final oldValue = _isLoading.value;
    _isLoading.value = loading;
    if (oldValue != loading) {
      print('⏳ Loading state: $loading');
    }
  }

  void _setError(String error) {
    _errorMessage.value = error;
    print('❌ Auth Error: $error');
  }

  void _clearError() {
    final hadError = _errorMessage.value.isNotEmpty;
    _errorMessage.value = '';
    if (hadError) {
      print('🧹 Error cleared');
    }
  }

  void _setAuthState(AuthState newState) {
    final oldState = _authState.value;
    _authState.value = newState;
    if (oldState != newState) {
      _logStateChange(oldState, newState);
    }
  }

  // ===========================================
  // PASSWORD VISIBILITY TOGGLES
  // ===========================================

  void toggleLoginPasswordVisibility() {
    obscureLoginPassword.value = !obscureLoginPassword.value;
  }

  void toggleNewPasswordVisibility() {
    obscureNewPassword.value = !obscureNewPassword.value;
  }

  void toggleConfirmPasswordVisibility() {
    obscureConfirmPassword.value = !obscureConfirmPassword.value;
  }

  void toggleResetNewPasswordVisibility() {
    obscureResetNewPassword.value = !obscureResetNewPassword.value;
  }

  void toggleResetConfirmPasswordVisibility() {
    obscureResetConfirmPassword.value = !obscureResetConfirmPassword.value;
  }

  // ===========================================
  // CORE AUTHENTICATION METHODS
  // ===========================================

  // Initialize authentication
  Future<void> _initializeAuth() async {
    _logMethodEntry('_initializeAuth');

    try {
      _setLoading(true);
      print('🔧 Initializing auth storage...');
      await _authStorage.init();

      print('🔧 Initializing auth middleware...');
      await _authMiddleware.init();

      print('🔧 Checking initial auth status...');
      await checkAuthStatus();

      _logMethodExit('_initializeAuth', 'Success');
    } catch (e) {
      print('❌ Auth initialization failed: $e');
      _setAuthState(AuthState.unauthenticated);
      _logMethodExit('_initializeAuth', 'Failed');
    } finally {
      _setLoading(false);
    }
  }

  // Check if user is already authenticated
  Future<void> checkAuthStatus() async {
    _logMethodEntry('checkAuthStatus');

    try {
      print('🔍 Checking authentication status...');
      final isAuthenticated = await _authStorage.isAuthenticated();
      print('🔍 Storage says authenticated: $isAuthenticated');

      if (isAuthenticated) {
        print('✅ User appears to be authenticated, fetching user data...');

        final user = await _authStorage.getUser();
        final token = await _authStorage.getAuthToken();

        print('👤 User data exists: ${user != null}');
        print('🎫 Token exists: ${token != null}');

        if (user != null && token != null) {
          print('✅ Valid auth session found');
          print('👤 User: ${user.email ?? "Unknown"}');

          _currentUser.value = user;
          _setAuthState(AuthState.authenticated);

          // Validate session in background
          print('🔄 Validating session in background...');
          _validateSessionInBackground();

          // Navigate to company selection if not already there
          if (Get.currentRoute != '/company' && Get.currentRoute != '/home') {
            print('🏢 Navigating to company selection screen...');
            Get.offAllNamed('/company');
          } else {
            print('🏢 Already on authenticated screen');
          }
        } else {
          print('⚠️ Incomplete auth data - clearing...');
          await _authStorage.clearAuthData();
          _setAuthState(AuthState.unauthenticated);

          // Navigate to login if not already there
          if (Get.currentRoute != '/login') {
            Get.offAllNamed('/login');
          }
        }
      } else {
        print('❌ User not authenticated');
        _setAuthState(AuthState.unauthenticated);
      }

      _logMethodExit('checkAuthStatus', 'Success');
    } catch (e) {
      print('❌ Error checking auth status: $e');
      _setAuthState(AuthState.unauthenticated);
      _logMethodExit('checkAuthStatus', 'Error');
    }
  }

  // Validate session in background
  Future<void> _validateSessionInBackground() async {
    _logMethodEntry('_validateSessionInBackground');

    try {
      print('🔍 Validating current session...');
      final isValid = await _authMiddleware.validateSession();

      if (isValid) {
        print('✅ Session validation successful');
        _logMethodExit('_validateSessionInBackground', 'Valid');
      } else {
        print('❌ Session validation failed - logging out');
        await logout();
        _logMethodExit('_validateSessionInBackground', 'Invalid - Logged out');
      }
    } catch (e) {
      print('⚠️ Session validation error: $e');
      _logMethodExit('_validateSessionInBackground', 'Error - Continuing');
    }
  }

  // ===========================================
  // LOGIN & AUTHENTICATION FLOW
  // ===========================================

  // Main login method
  Future<void> login() async {
    if (loginFormKey.currentState == null ||
        !loginFormKey.currentState!.validate()) {
      return;
    }

    final email = loginEmailController.text.trim();
    final password = loginPasswordController.text.trim();

    _logMethodEntry('login', {'email': email, 'rememberMe': rememberMe.value});

    try {
      _setLoading(true);
      _clearError();

      print('🔐 Creating login request...');
      final request = LoginRequest(
        email: email,
        password: password,
        rememberMe: rememberMe.value,
      );

      print('🌐 Calling auth service login...');
      final response = await _authService.login(request);

      if (response.success) {
        print('✅ Login API call successful');
        print('🔍 Checking first login status: ${response.isFirstLogin}');
        print('🔍 Response data: ${response.data}');

        bool isFirstLogin = false;

        // Check multiple possible sources for first login flag
        if (response.isFirstLogin == true) {
          print('🆕 First login detected from response.isFirstLogin');
          isFirstLogin = true;
        } else if (response.data != null) {
          final data = response.data!;
          if (data['isFirstLogin'] == true ||
              data['is_first_login'] == true ||
              data['firstLogin'] == true ||
              data['first_login'] == true) {
            print('🆕 First login detected from response data');
            isFirstLogin = true;
          }
        }

        if (isFirstLogin) {
          print('🆕 FIRST TIME LOGIN DETECTED - Redirecting to password reset');
          _tempEmail.value = email;
          _setAuthState(AuthState.firstTimeLogin);
          _setError('First time login: Please reset your password to continue');

          print('🔄 Navigating to first login reset screen...');
          Get.toNamed('/first-login-reset');
          _logMethodExit('login', 'First login redirect');
        } else {
          print('✅ Regular login - processing auth data...');
          await _handleSuccessfulAuth(response);
          _logMethodExit('login', 'Success');
        }
      } else {
        print('❌ Login failed: ${response.message}');
        _setError(response.message ?? 'Login failed');
        _setAuthState(AuthState.unauthenticated);
        _logMethodExit('login', 'Failed - ${response.message}');
      }
    } catch (e) {
      print('❌ Login exception: $e');
      _setError('An error occurred during login');
      _setAuthState(AuthState.unauthenticated);
      _logMethodExit('login', 'Exception');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _handleSuccessfulAuth(AuthResponse response) async {
    try {
      print('📥 AuthController._handleSuccessfulAuth() - Entry');
      print('🔍 Validating auth response...');
      print('🔍 Response token: ${response.token?.substring(0, 50)}...');
      
      // Save auth response to storage
      print('💾 Saving auth response to storage...');
      await _authStorage.saveAuthResponse(response);
      print('✅ Auth response saved successfully');
      
      // Extract and save user data from JWT token
      print('🔍 About to extract user data from JWT token...');
      final token = response.token;
      
      if (token != null && token.isNotEmpty) {
        print('✅ Token is valid, calling _saveUserDataFromToken...');
        await _saveUserDataFromToken(token);
        print('✅ _saveUserDataFromToken completed');
      } else {
        print('🔴 Token is null or empty! Cannot extract user data.');
      }
      
      // Extract user from JWT and set current user
      print('🔍 Extracting user object from JWT token...');
      final user = _extractUserFromJWT(token ?? '');
      if (user != null) {
        _currentUser.value = user;
        print('👤 Current user set: ${user.email}');
      } else {
        print('🔴 Failed to extract user from JWT');
      }
      
      // Verify saved data
      print('🔍 Verifying saved auth data...');
      final isAuth = await _authStorage.isAuthenticated();
      print('✅ User authenticated: $isAuth');
      
      // Verify SharedPreferences
      print('🔍 Verifying SharedPreferences directly...');
      final prefs = await SharedPreferences.getInstance();
      final savedUserId = prefs.getString('userId');
      final savedUserName = prefs.getString('username');
      print('🔵 Direct check - userId: $savedUserId');
      print('🔵 Direct check - username: $savedUserName');
      
      // Set authenticated state
      _setAuthState(AuthState.authenticated);
      
      // Navigate to company location selection
      print('🏠 Navigating to company location selection...');
      Get.offAllNamed('/company');
      
      print('📤 AuthController._handleSuccessfulAuth() - Exit (Success)');
    } catch (e, stackTrace) {
      print('🔴 Error in _handleSuccessfulAuth: $e');
      print('🔴 Stack trace: $stackTrace');
      throw Exception('Failed to process auth response: $e');
    }
  }

  // Helper method to extract user data from JWT token and save to SharedPreferences
  Future<void> _saveUserDataFromToken(String token) async {
    try {
      print('🔍 Extracting user data from JWT token...');
      
      // Remove "Bearer " prefix if present
      final jwtToken = token.replaceFirst('Bearer ', '');
      
      // Parse JWT token
      final parts = jwtToken.split('.');
      if (parts.length != 3) {
        print('🔴 Invalid JWT token format');
        return;
      }
      
      // Decode the payload (second part)
      final payload = parts[1];
      
      // Normalize base64 string (add padding if needed)
      String normalized = payload;
      while (normalized.length % 4 != 0) {
        normalized += '=';
      }
      
      final decoded = utf8.decode(base64Url.decode(normalized));
      final claims = json.decode(decoded) as Map<String, dynamic>;
      
      print('🔍 JWT Claims: ${claims.keys.toList()}');
      
      // Extract user data
      final userId = claims['sub'] as String?;
      final userName = claims['name'] as String?;
      final userEmail = claims['email'] as String?;
      
      if (userId == null) {
        print('🔴 No user ID found in token');
        return;
      }
      
      // Save to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      
      // Save user ID with multiple key formats for compatibility
      await prefs.setString('user_id', userId);
      await prefs.setString('userId', userId);
      
      // Save other user info
      if (userName != null) {
        await prefs.setString('username', userName);
        await prefs.setString('user_name', userName);
      }
      
      if (userEmail != null) {
        await prefs.setString('user_email', userEmail);
        await prefs.setString('email', userEmail);
      }
      
      print('🟢 User data saved from token:');
      print('   userId: $userId');
      print('   username: $userName');
      print('   email: $userEmail');
      
    } catch (e) {
      print('🔴 Error extracting user data from token: $e');
      print('🔴 Stack trace: ${StackTrace.current}');
    }
  }

  // Helper method to extract user object from JWT token (for _currentUser)
  User? _extractUserFromJWT(String token) {
    try {
      // Remove "Bearer " prefix if present
      final jwtToken = token.replaceFirst('Bearer ', '');
      
      // Decode JWT token
      final parts = jwtToken.split('.');
      if (parts.length != 3) {
        print('⚠️ Invalid JWT token format');
        return null;
      }

      // Decode payload (second part)
      final payload = parts[1];
      
      // Add padding if needed for base64 decoding
      String normalized = payload;
      while (normalized.length % 4 != 0) {
        normalized += '=';
      }
      
      final decoded = utf8.decode(base64Url.decode(normalized));
      final Map<String, dynamic> claims = jsonDecode(decoded);

      print('🔍 JWT Claims: ${claims.keys.toList()}');

      // Extract user information from JWT claims
      return User(
        id: claims['sub']?.toString(),
        name: claims['name']?.toString(),
        email: claims['email']?.toString(),
      );
    } catch (e) {
      print('⚠️ Failed to extract user from JWT: $e');
      return null;
    }
  }

  // ===========================================
  // PASSWORD RESET FLOW
  // ===========================================

  // Step 1: Request password reset (send OTP to email)
  Future<void> requestPasswordReset() async {
    if (!forgotPasswordFormKey.currentState!.validate()) {
      return;
    }

    _logMethodEntry('requestPasswordReset');
    _setLoading(true);
    final email = forgotEmailController.text.trim();

    try {
      print('📧 Creating forgot password request for: $email');
      final request = ForgotPasswordRequest(email: email);
      final response = await _authService.forgotPassword(request);

      print('=== FORGOT PASSWORD API Response Debug ===');
      print('Response success: ${response.success}');
      print('Response message: ${response.message}');
      print('Response data: ${response.data}');
      print('========================================');

      _setLoading(false);

      // Check if response contains success message even if success flag is false
      if (response.success ||
          (response.message != null &&
              response.message!.toLowerCase().contains('sent'))) {
        print(
          '✅ Forgot password request successful - navigating to reset screen',
        );

        _tempEmail.value = email;
        _setAuthState(AuthState.resetPassword);

        // Navigate to reset password screen with email
        Get.toNamed('/reset-password', arguments: {'email': email});
        _logMethodExit('requestPasswordReset', 'Success');
      } else {
        print('❌ Forgot password request failed: ${response.message}');
        _setError(response.message ?? 'Failed to send reset code');
        _logMethodExit('requestPasswordReset', 'Failed');
      }
    } catch (e) {
      print('❌ Forgot password exception: $e');
      _setLoading(false);
      _setError('An error occurred while sending reset code');
      _logMethodExit('requestPasswordReset', 'Exception');
    }
  }

  // Step 2: Confirm password reset with OTP and new password
  Future<void> confirmPasswordReset() async {
    _logMethodEntry('confirmPasswordReset');

    // Get email from arguments or stored email
    final email = Get.arguments?['email'] ?? _tempEmail.value;

    // Manual validation
    if (email.isEmpty) {
      _setError('Email is required');
      return;
    }

    if (otpController.text.trim().isEmpty) {
      _setError('OTP is required');
      return;
    }

    if (resetNewPasswordController.text.trim().isEmpty) {
      _setError('New password is required');
      return;
    }

    if (resetNewPasswordController.text.trim().length < 8) {
      _setError('Password must be at least 8 characters');
      return;
    }

    if (resetConfirmPasswordController.text.trim().isEmpty) {
      _setError('Please confirm your password');
      return;
    }

    if (resetNewPasswordController.text.trim() !=
        resetConfirmPasswordController.text.trim()) {
      _setError('Passwords do not match');
      return;
    }

    _setLoading(true);

    try {
      print('🔐 Creating reset password request for: $email');
      final request = ResetPasswordRequest(
        email: email,
        code: otpController.text.trim(),
        newPassword: resetNewPasswordController.text.trim(),
        confirmPassword: resetConfirmPasswordController.text.trim(),
      );

      print('🌐 Calling auth service reset password...');
      final response = await _authService.resetPassword(request);

      _setLoading(false);

      if (response.success) {
        print('✅ Password reset successful');
        _clearPasswordResetForm();
        _setAuthState(AuthState.unauthenticated);
        _tempEmail.value = '';

        await _showPasswordResetSuccessDialog();
        _logMethodExit('confirmPasswordReset', 'Success');
      } else {
        print('❌ Password reset failed: ${response.message}');
        _setError(response.message ?? 'Password reset failed');
        _logMethodExit('confirmPasswordReset', 'Failed');
      }
    } catch (e) {
      print('❌ Password reset exception: $e');
      _setLoading(false);
      _setError('An error occurred during password reset');
      _logMethodExit('confirmPasswordReset', 'Exception');
    }
  }

  // Resend OTP code
  Future<void> resendCode() async {
    _logMethodEntry('resendCode');

    final email = Get.arguments?['email'] ?? _tempEmail.value;

    if (email.isEmpty) {
      _setError('Email not found');
      return;
    }

    _setLoading(true);

    try {
      print('📧 Resending OTP for: $email');
      final request = ForgotPasswordRequest(email: email);
      final response = await _authService.forgotPassword(request);

      _setLoading(false);

      if (response.success) {
        // Clear any previous errors on success
        _clearError();
        _logMethodExit('resendCode', 'Success');
      } else {
        _setError(response.message ?? 'Failed to resend code');
        _logMethodExit('resendCode', 'Failed');
      }
    } catch (e) {
      print('❌ Resend code exception: $e');
      _setLoading(false);
      _setError('An error occurred while resending code');
      _logMethodExit('resendCode', 'Exception');
    }
  }

  // ===========================================
  // TOKEN & SESSION MANAGEMENT
  // ===========================================

  // Manual token refresh
  Future<void> refreshToken() async {
    _logMethodEntry('refreshToken');

    try {
      print('🔄 Manual token refresh requested...');
      final success = await _authMiddleware.validateSession();

      if (!success) {
        print('❌ Token refresh failed - logging out');
        await logout();
        _logMethodExit('refreshToken', 'Failed - Logged out');
      } else {
        print('✅ Token refresh successful');
        // Update user data after refresh
        final user = await _authStorage.getUser();
        if (user != null) {
          _currentUser.value = user;
          print('👤 User data updated after refresh');
        }
        _logMethodExit('refreshToken', 'Success');
      }
    } catch (e) {
      print('❌ Token refresh exception: $e');
      await logout();
      _logMethodExit('refreshToken', 'Exception - Logged out');
    }
  }

  // Logout
  Future<void> logout() async {
    _logMethodEntry('logout');

    try {
      _setLoading(true);
      print('🚪 Initiating logout process...');

      await _authMiddleware.forceLogout();

      _currentUser.value = null;
      _setAuthState(AuthState.unauthenticated);
      _tempEmail.value = '';

      // Clear all forms
      _clearAllForms();

      print('✅ User logged out successfully');
      _logMethodExit('logout', 'Success');
    } catch (e) {
      print('❌ Logout error: $e');
      // Still clear local state even if server logout fails
      await _authStorage.clearAuthData();
      _currentUser.value = null;
      _setAuthState(AuthState.unauthenticated);
      _clearAllForms();
      _logMethodExit('logout', 'Partial success with errors');
    } finally {
      _setLoading(false);
    }
  }

  // ===========================================
  // NAVIGATION HELPERS
  // ===========================================

  void navigateToForgotPassword() {
    print('🔄 Navigating to forgot password screen...');
    _setAuthState(AuthState.forgotPassword);
    _clearError();
    Get.toNamed('/forgot-password');
  }

  void navigateToLogin() {
    print('🔄 Navigating to login screen...');
    _setAuthState(AuthState.unauthenticated);
    _clearError();
    _clearAllForms();
    Get.offAllNamed('/login');
  }

  // ===========================================
  // UTILITY METHODS
  // ===========================================

  // Get current user info
  Future<User?> getCurrentUser() async {
    _logMethodEntry('getCurrentUser');
    final user = await _authMiddleware.getCurrentUser();
    print('👤 Current user request: ${user?.email ?? "No user"}');
    _logMethodExit('getCurrentUser');
    return user;
  }

  // Check authentication status
  Future<bool> isAuthenticated() async {
    _logMethodEntry('isAuthenticated');
    final isAuth = await _authMiddleware.isAuthenticated();
    print('🔍 Authentication check result: $isAuth');
    _logMethodExit('isAuthenticated');
    return isAuth;
  }

  // Get auth token for manual API calls
  Future<String?> getAuthToken() async {
    _logMethodEntry('getAuthToken');
    final token = await _authMiddleware.getAuthToken();
    print(
      '🎫 Token request: ${token != null ? "Token available" : "No token"}',
    );
    _logMethodExit('getAuthToken');
    return token;
  }

  // ===========================================
  // UI HELPER METHODS
  // ===========================================

  // Success dialog for password reset
  Future<void> _showPasswordResetSuccessDialog() async {
    await Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Success Icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.check_circle, color: Colors.green, size: 60),
              ),
              SizedBox(height: 20),

              // Title
              Text(
                'Success!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 10),

              // Message
              Text(
                'Your password has been reset successfully. Please login with your new password.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              ),
              SizedBox(height: 25),

              // Okay Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Get.back(); // Close dialog
                    navigateToLogin(); // Navigate to login
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD32F2F),
                    padding: EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    'Okay',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: false,
    );
  }

  // ===========================================
  // FORM MANAGEMENT & VALIDATION
  // ===========================================

  // Clear login form
  void _clearLoginForm() {
    loginEmailController.clear();
    loginPasswordController.clear();
    obscureLoginPassword.value = true;
    rememberMe.value = true;
  }

  // Clear password reset forms
  void _clearPasswordResetForm() {
    forgotEmailController.clear();
    otpController.clear();
    resetNewPasswordController.clear();
    resetConfirmPasswordController.clear();
    obscureResetNewPassword.value = true;
    obscureResetConfirmPassword.value = true;
  }

  // Clear first login form
  void _clearFirstLoginForm() {
    temporaryPasswordController.clear();
    newPasswordController.clear();
    confirmPasswordController.clear();
    obscureNewPassword.value = true;
    obscureConfirmPassword.value = true;
  }

  // Clear all forms
  void _clearAllForms() {
    _clearLoginForm();
    _clearPasswordResetForm();
    _clearFirstLoginForm();
  }

  // Validators
  String? validateEmail(String? value) {
    if (value == null || value.isEmpty) return 'Email required';
    if (!GetUtils.isEmail(value)) return 'Invalid email';
    return null;
  }

  String? validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Password required';
    return null;
  }

  String? validateNewPassword(String? value) {
    if (value == null || value.isEmpty) return 'Password required';
    if (value.length < 8) return 'Min 8 characters';
    return null;
  }

  String? validateConfirmPassword(String? value, String passwordToMatch) {
    if (value == null || value.isEmpty) return 'Confirm password';
    if (value != passwordToMatch) return 'Passwords do not match';
    return null;
  }

  String? validateOTP(String? value) {
    if (value == null || value.isEmpty) return 'OTP required';
    return null;
  }

  // ===========================================
  // DEBUG METHODS
  // ===========================================

  // Debug helper methods
  Future<void> debugAuthState() async {
    print('');
    print('🔍 ===== AUTH DEBUG STATE =====');
    print('🎯 Controller State: ${_authState.value.name}');
    print('👤 Current User: ${_currentUser.value?.email ?? "None"}');
    print('⏳ Loading: ${_isLoading.value}');
    print(
      '❌ Error: ${_errorMessage.value.isEmpty ? "None" : _errorMessage.value}',
    );
    print(
      '📧 Temp Email: ${_tempEmail.value.isEmpty ? "None" : _tempEmail.value}',
    );
    print('🏠 Current Route: ${Get.currentRoute}');

    // Check storage state
    final hasToken = await _authStorage.getAuthToken() != null;
    final hasUser = await _authStorage.getUser() != null;
    final isAuth = await _authStorage.isAuthenticated();

    print(
      '💾 Storage - Token: $hasToken, User: $hasUser, Authenticated: $isAuth',
    );
    print('===============================');
    print('');
  }

  // Method to force re-authentication check (useful for debugging)
  Future<void> forceAuthCheck() async {
    print('🔄 Force auth check requested');
    await checkAuthStatus();
  }

  // Method to check if we have a valid token without changing state
  Future<bool> hasValidToken() async {
    try {
      final token = await _authStorage.getAuthToken();
      final isExpired = await _authStorage.isTokenExpired();
      final isValid = token != null && !isExpired;
      print(
        '🎫 Token validity check: $isValid (exists: ${token != null}, expired: $isExpired)',
      );
      return isValid;
    } catch (e) {
      print('❌ Token validity check failed: $e');
      return false;
    }
  }
}