import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:itrack/http/model/locationcountmodel.dart';
import 'package:itrack/http/service/homeservice.dart';

class DashboardController extends GetxController {
  final DashboardService _dashboardService;

  DashboardController({DashboardService? dashboardService})
      : _dashboardService = dashboardService ?? DashboardService();

  // Observable data
  final RxInt totalAssets = 0.obs;
  final RxInt todaysAssets = 0.obs;
  final RxString greeting = ''.obs;
  final RxString username = ''.obs;
  final RxString currentTime = ''.obs;
  final RxString mainLocation = ''.obs;

  final RxList<LocationCountModel> locationCounts = <LocationCountModel>[].obs;
  final RxList<LocationAuditCountModel> auditCounts = <LocationAuditCountModel>[].obs;

  // Loading states
  final RxBool isLoadingTotal = false.obs;
  final RxBool isLoadingToday = false.obs;
  final RxBool isLoadingLocations = false.obs;
  final RxBool isLoadingAudits = false.obs;

  // User data (from SharedPrefs - inject these)
  String tenantId = '';
  String userId = '';
  String mainLocationId = '';

  @override
  void onInit() {
    super.onInit();
    _initializeData();
    _startTimeUpdater();
  }

  void _initializeData() {
    // TODO: Get from SharedPrefs
    // tenantId = sharedPrefs.getItem("tenantId");
    // userId = sharedPrefs.getItem("userId");
    // mainLocationId = sharedPrefs.getItem("MainLocationId");
    // username.value = sharedPrefs.getItem("userName");
    // mainLocation.value = sharedPrefs.getItem("MainLocation");

    _updateGreeting();
    _loadDashboardData();
  }

  void _startTimeUpdater() {
    // Update time every minute
    ever(currentTime, (_) {});
    _updateTime();
    Future.delayed(const Duration(minutes: 1), () {
      if (!isClosed) {
        _updateTime();
        _startTimeUpdater();
      }
    });
  }

  void _updateTime() {
    final now = DateTime.now();
    currentTime.value = DateFormat('h:mm a').format(now);
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

  Future<void> _loadDashboardData() async {
    await Future.wait([
      getTotalAssets(),
      getTodaysAssets(),
      getLocationCounts(),
      getAuditCounts(),
    ]);
  }

  Future<void> refreshDashboard() async {
    await _loadDashboardData();
  }

  Future<void> getTotalAssets() async {
    try {
      isLoadingTotal.value = true;

      final locations = await _dashboardService.getAllAssetsByLocation(
        tenantId,
        mainLocationId,
      );

      // Calculate total assets from all locations
      int total = 0;
      for (var location in locations) {
        total += location.locCount;
      }

      totalAssets.value = total;
      isLoadingTotal.value = false;
    } catch (e) {
      isLoadingTotal.value = false;
      Get.snackbar(
        'Error',
        'Failed to load total assets: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> getTodaysAssets() async {
    try {
      isLoadingToday.value = true;

      final currentDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
      
      final assets = await _dashboardService.getTodaysAssets(
        currentDate,
        userId,
        tenantId,
        mainLocationId,
      );

      todaysAssets.value = assets.length;
      isLoadingToday.value = false;
    } catch (e) {
      isLoadingToday.value = false;
      Get.snackbar(
        'Error',
        'Failed to load today\'s assets: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> getLocationCounts() async {
    try {
      isLoadingLocations.value = true;

      final locations = await _dashboardService.getAllAssetsByLocation(
        tenantId,
        mainLocationId,
      );

      locationCounts.value = locations;
      isLoadingLocations.value = false;
    } catch (e) {
      isLoadingLocations.value = false;
      Get.snackbar(
        'Error',
        'Failed to load location counts: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> getAuditCounts() async {
    try {
      isLoadingAudits.value = true;

      final audits = await _dashboardService.getAuditCountByLocation(
        tenantId,
        mainLocationId,
      );

      auditCounts.value = audits;
      isLoadingAudits.value = false;
    } catch (e) {
      isLoadingAudits.value = false;
      Get.snackbar(
        'Error',
        'Failed to load audit counts: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  void navigateToRecords() {
    // TODO: Navigate to records screen
    // Get.to(() => RecordsScreen());
  }

  void navigateToProfile() {
    // TODO: Navigate to profile screen
    // Get.to(() => ProfileScreen());
  }

  @override
  void onClose() {
    _dashboardService.dispose();
    super.onClose();
  }
}