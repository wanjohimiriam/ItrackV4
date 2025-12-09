/// Centralized storage keys for SharedPreferences
/// This ensures consistency across the app and prevents duplicate keys
class StorageKeys {
  // Private constructor to prevent instantiation
  StorageKeys._();

  // Authentication keys
  static const String authToken = 'auth_token';
  static const String refreshToken = 'refresh_token';
  static const String tokenExpiry = 'token_expiry';
  
  // User keys
  static const String userId = 'user_id';
  static const String userName = 'user_name';
  static const String userEmail = 'user_email';
  static const String tenantId = 'tenant_id';
  
  // Location keys
  static const String locationId = 'location_id';
  static const String locationName = 'location_name';
  static const String locationCode = 'location_code';
  
  // App state keys
  static const String rememberMe = 'remember_me';
  static const String isFirstLaunch = 'is_first_launch';
  static const String lastSyncTime = 'last_sync_time';
}
