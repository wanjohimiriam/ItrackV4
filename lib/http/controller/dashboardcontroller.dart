import 'package:get/get.dart';
import 'package:itrack/http/service/dashboard_service.dart';
import 'package:itrack/http/service/error_handler.dart';
import 'package:itrack/http/service/storage_keys.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DashboardController extends GetxController {
  // Dashboard data
  var totalAssets = 0.obs;
  var todaysAssets = 0.obs;
  var auditCounts = <LocationAudit>[].obs;
  
  // Loading states
  var isLoadingTotal = false.obs;
  var isLoadingToday = false.obs;
  var isLoadingAudits = false.obs;
  
  // User info
  var username = ''.obs;
  var mainLocation = ''.obs;
  var greeting = ''.obs;
  var currentTime = ''.obs;
  
  // User credentials
  String? userId;
  String? locationId;
  
  // Cache management
  var lastLoadTime = Rxn<DateTime>();
  static const cacheDuration = Duration(minutes: 2);

  @override
  void onInit() {
    super.onInit();
    ErrorHandler.logInfo('DashboardController onInit() started', context: 'DashboardController');
    _initialize();
  }
  
  bool _shouldReloadDashboard() {
    if (lastLoadTime.value == null) return true;
    
    final timeSinceLoad = DateTime.now().difference(lastLoadTime.value!);
    final shouldReload = timeSinceLoad > cacheDuration;
    
    ErrorHandler.logInfo(
      'Dashboard cache check: ${shouldReload ? "RELOAD" : "USE CACHE"} (age: ${timeSinceLoad.inSeconds}s)',
      context: 'DashboardController',
    );
    
    return shouldReload;
  }
  
  Future<void> _loadDashboardFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedTotal = prefs.getInt('cached_total_assets');
      final cachedToday = prefs.getInt('cached_today_assets');
      final cachedTime = prefs.getString('cached_dashboard_time');
      
      if (cachedTime == null) return;
      
      final cacheAge = DateTime.now().difference(DateTime.parse(cachedTime));
      if (cacheAge > cacheDuration) {
        ErrorHandler.logInfo('Dashboard cache expired (${cacheAge.inMinutes}min old)', context: 'DashboardController');
        return;
      }
      
      if (cachedTotal != null) totalAssets.value = cachedTotal;
      if (cachedToday != null) todaysAssets.value = cachedToday;
      lastLoadTime.value = DateTime.parse(cachedTime);
      
      ErrorHandler.logInfo('Loaded dashboard from SharedPreferences (Total: $cachedTotal, Today: $cachedToday)', context: 'DashboardController');
    } catch (e) {
      ErrorHandler.logWarning('Failed to load dashboard from cache: $e', context: 'DashboardController');
    }
  }
  
  Future<void> _saveDashboardToCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('cached_total_assets', totalAssets.value);
      await prefs.setInt('cached_today_assets', todaysAssets.value);
      await prefs.setString('cached_dashboard_time', DateTime.now().toIso8601String());
      
      ErrorHandler.logInfo('Saved dashboard to SharedPreferences', context: 'DashboardController');
    } catch (e) {
      ErrorHandler.logWarning('Failed to save dashboard to cache: $e', context: 'DashboardController');
    }
  }

  Future<void> _initialize() async {
    ErrorHandler.logInfo('DashboardController _initialize() started', context: 'DashboardController');
    await _loadUserData();
    _updateGreeting();
    _updateTime();
    
    // Load from cache first for instant display
    await _loadDashboardFromCache();
    
    // Only fetch if cache is expired
    if (_shouldReloadDashboard()) {
      await fetchDashboardData();
    } else {
      ErrorHandler.logInfo('Using cached dashboard data', context: 'DashboardController');
    }
  }

  /// Load user data from SharedPreferences
  Future<void> _loadUserData() async {
    try {
      ErrorHandler.logInfo('Loading user data from SharedPreferences...', context: 'DashboardController');
      final prefs = await SharedPreferences.getInstance();
      
      // Use centralized storage keys
      userId = prefs.getString(StorageKeys.userId);
      locationId = prefs.getString(StorageKeys.locationId);
      username.value = prefs.getString(StorageKeys.userName) ?? 'User';
      mainLocation.value = prefs.getString(StorageKeys.locationName) ?? 'Unknown Location';
      
      ErrorHandler.logInfo('Loaded user data: userId=$userId, locationId=$locationId', context: 'DashboardController');
      
      if (userId == null) {
        ErrorHandler.logWarning('userId is null', context: 'DashboardController');
      }
      if (locationId == null) {
        ErrorHandler.logWarning('locationId is null', context: 'DashboardController');
      }
    } catch (e) {
      ErrorHandler.handle(e, context: 'DashboardController._loadUserData', showSnackbar: false);
    }
  }

  // In your DashboardController

Future<void> fetchDashboardData() async {
  try {
    ErrorHandler.logInfo('fetchDashboardData() started', context: 'DashboardController');
    isLoadingTotal.value = true;
    isLoadingToday.value = true;
    isLoadingAudits.value = true;

    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString(StorageKeys.userId) ?? '';
    final locationId = prefs.getString(StorageKeys.locationId) ?? '';

    if (userId.isEmpty || locationId.isEmpty) {
      ErrorHandler.logWarning('Missing userId or locationId', context: 'DashboardController');
      ErrorHandler.handle('User data not found. Please login again.', context: 'DashboardController');
      
      // Redirect to login if no user data
      Get.offAllNamed('/login');
      return;
    }

    ErrorHandler.logInfo('Fetching dashboard for userId: $userId, locationId: $locationId', context: 'DashboardController');

    final dashboardData = await DashboardService.getDashboardSummary(
      userId: userId,
      locationId: locationId,
    );

    if (dashboardData != null) {
      totalAssets.value = dashboardData.totalAuditedAssets;
      todaysAssets.value = dashboardData.todaysAuditedAssets;
      auditCounts.value = dashboardData.getLocationAuditsList();
      lastLoadTime.value = DateTime.now();
      
      // Save to cache
      await _saveDashboardToCache();

      ErrorHandler.logInfo('Dashboard data loaded: Total=${totalAssets.value}, Today=${todaysAssets.value}', context: 'DashboardController');
    } else {
      ErrorHandler.handle('Failed to load dashboard data', context: 'DashboardController');
    }
  } catch (e) {
    ErrorHandler.handle(e, context: 'DashboardController.fetchDashboardData');
  } finally {
    isLoadingTotal.value = false;
    isLoadingToday.value = false;
    isLoadingAudits.value = false;
    ErrorHandler.logInfo('fetchDashboardData() completed', context: 'DashboardController');
  }
}

  /// Refresh dashboard with pull-to-refresh
  Future<void> refreshDashboard() async {
    ErrorHandler.logInfo('Refreshing dashboard...', context: 'DashboardController');
    await fetchDashboardData();
  }

  /// Logout user
  Future<void> logout() async {
    try {
      ErrorHandler.logInfo('Logging out user...', context: 'DashboardController');
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      ErrorHandler.logInfo('User data cleared', context: 'DashboardController');
      Get.offAllNamed('/login');
    } catch (e) {
      ErrorHandler.handle(e, context: 'DashboardController.logout', showSnackbar: false);
      Get.offAllNamed('/login');
    }
  }

  void _updateGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      greeting.value = 'Good Morning';
    } else if (hour < 17) {
      greeting.value = 'Good Afternoon';
    } else {
      greeting.value = 'Good Evening';
    }
  }

  void _updateTime() {
    final now = DateTime.now();
    currentTime.value = _formatDateTime(now);
  }

  String _formatDateTime(DateTime dateTime) {
    return '${_formatDate(dateTime)} • ${_formatTime(dateTime)}';
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  String _formatTime(DateTime time) {
    final hour = time.hour > 12 ? time.hour - 12 : (time.hour == 0 ? 12 : time.hour);
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }
}