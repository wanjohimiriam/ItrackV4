import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:itrack/http/service/dashboard_service.dart';
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

  @override
  void onInit() {
    super.onInit();
    print('🟡 DashboardController onInit() started');
    _initialize();
  }

  Future<void> _initialize() async {
    print('🟡 DashboardController _initialize() started');
    await _loadUserData();
    _updateGreeting();
    _updateTime();
    await fetchDashboardData();
  }

  /// Load user data from SharedPreferences
  Future<void> _loadUserData() async {
    try {
      print('🟡 Loading user data from SharedPreferences...');
      final prefs = await SharedPreferences.getInstance();
      
      // ✅ Try multiple key formats for compatibility
      userId = prefs.getString('user_id') ?? prefs.getString('userId');
      locationId = prefs.getString('main_location_id') ?? prefs.getString('locationId');
      username.value = prefs.getString('username') ?? prefs.getString('user_name') ?? 'User';
      mainLocation.value = prefs.getString('main_location_name') ?? prefs.getString('locationName') ?? 'Unknown Location';
      
      print('🔵 Loaded user data:');
      print('   userId: $userId');
      print('   locationId: $locationId');
      print('   username: ${username.value}');
      print('   mainLocation: ${mainLocation.value}');
      
      if (userId == null) {
        print('🔴 WARNING: userId is null');
      }
      if (locationId == null) {
        print('🔴 WARNING: locationId is null');
      }
    } catch (e) {
      print('🔴 Error loading user data: $e');
    }
  }

  // In your DashboardController

Future<void> fetchDashboardData() async {
  try {
    print('🟡 fetchDashboardData() started');
    isLoadingTotal.value = true;
    isLoadingToday.value = true;
    isLoadingAudits.value = true;

    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user_id') ?? '';
    final locationId = prefs.getString('main_location_id') ?? '';

    if (userId.isEmpty || locationId.isEmpty) {
      print('🔴 Missing userId or locationId');
      _showError('User data not found. Please login again.');
      
      // Redirect to login if no user data
      Get.offAllNamed('/login');
      return;
    }

    print('🔵 Fetching dashboard for userId: $userId, locationId: $locationId');

    final dashboardData = await DashboardService.getDashboardSummary(
      userId: userId,
      locationId: locationId,
    );

    if (dashboardData != null) {
      totalAssets.value = dashboardData.totalAuditedAssets;
      todaysAssets.value = dashboardData.todaysAuditedAssets;
      auditCounts.value = dashboardData.getLocationAuditsList();

      print('🟢 Dashboard data loaded successfully');
      print('   Total: ${totalAssets.value}');
      print('   Today: ${todaysAssets.value}');
      print('   Locations: ${auditCounts.length}');
    } else {
      print('🔴 Dashboard response is null');
      _showError('Failed to load dashboard data');
    }
  } catch (e) {
    print('🔴 fetchDashboardData error: $e');
    _showError('Error loading dashboard: $e');
  } finally {
    isLoadingTotal.value = false;
    isLoadingToday.value = false;
    isLoadingAudits.value = false;
    print('🟡 fetchDashboardData() completed');
  }
}

void _showError(String message) {
  Get.snackbar(
    'Error',
    message,
    snackPosition: SnackPosition.BOTTOM,
    backgroundColor: Colors.red,
    colorText: Colors.white,
    duration: const Duration(seconds: 3),
  );
}

  /// Refresh dashboard with pull-to-refresh
  Future<void> refreshDashboard() async {
    print('🟡 Refreshing dashboard...');
    await fetchDashboardData();
  }

  /// Logout user
  Future<void> logout() async {
    try {
      print('🟡 Logging out user...');
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      print('🟢 User data cleared');
      Get.offAllNamed('/login');
    } catch (e) {
      print('🔴 Logout error: $e');
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