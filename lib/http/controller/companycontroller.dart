// ignore_for_file: avoid_print

import 'package:get/get.dart';
import 'package:itrack/http/service/companyservice.dart';
import 'package:itrack/http/service/authstorage.dart';
import 'package:itrack/http/service/authmiddleware.dart';
import 'package:itrack/http/model/locationmodel.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';

class CompanyController extends GetxController {
  final CompanyService _companyService = CompanyService();
  final AuthStorage _authStorage = AuthStorage.instance;
  final AuthMiddleware _authMiddleware = AuthMiddleware.instance;

  var isLoading = false.obs;
  var locations = <Location>[].obs;
  var selectedLocation = Rxn<Location>();
  var errorMessage = ''.obs;
  var isAuthenticated = false.obs;

  // ✅ Add initialization flag to prevent double initialization
  bool isInitialized = false;

  @override
  void onInit() {
    super.onInit();
    print('🟡 CompanyController initialized');
    // Don't initialize auth here since it might be called before login
  }

  // Call this when the screen is ready
  Future<void> initialize() async {
    // ✅ Prevent double initialization
    if (isInitialized) {
      print('🟡 CompanyController already initialized, skipping...');
      return;
    }

    print('🟡 Starting CompanyController initialization...');
    isInitialized = true;
    await initializeAuth();
  }

  Future<void> initializeAuth() async {
    try {
      print('🟡 initializeAuth() started');

      // Initialize auth middleware
      await _authMiddleware.init();
      print('🟢 AuthMiddleware initialized');

      // Check authentication status
      isAuthenticated.value = await _authStorage.isAuthenticated();
      print('🔵 Authentication status: ${isAuthenticated.value}');

      if (isAuthenticated.value) {
        print('🟢 User is authenticated, loading locations...');
        await loadLocations();
        await loadSavedLocation();
      } else {
        errorMessage.value = 'User not authenticated';
        print('🔴 User not authenticated, redirecting to login');
        Get.offAllNamed('/login');
      }
    } catch (e) {
      errorMessage.value = 'Authentication error: ${e.toString()}';
      print('🔴 initializeAuth() error: $e');
      Get.offAllNamed('/login');
    }
  }

  Future<void> loadLocations() async {
    try {
      print('🟡 loadLocations() started - calling API directly');
      isLoading.value = true;
      errorMessage.value = '';

      // Validate session first
      final sessionValid = await _authMiddleware.validateSession();
      print('🔵 Session validation: $sessionValid');

      if (!sessionValid) {
        errorMessage.value = 'Session expired. Please login again.';
        print('🔴 Session invalid, redirecting to login');
        Get.offAllNamed('/login');
        return;
      }

      // Load locations directly from API
      print('🟡 Calling getLocations() from CompanyService...');
      final locationsList = await _companyService.getLocations();

      print('🔵 Locations list received. Count: ${locationsList.length}');

      // Log each location for debugging
      for (int i = 0; i < locationsList.length; i++) {
        final location = locationsList[i];
        print(
          '📍 Location $i: id=${location.id}, name=${location.name}, code=${location.code}',
        );
      }

      locations.assignAll(locationsList);
      print(
        '🟢 Locations assigned to observable. locations.length: ${locations.length}',
      );

      // If no locations, show appropriate message
      if (locationsList.isEmpty) {
        errorMessage.value = 'No locations available for your account.';
        print('🟡 No locations available for user');

        // Show user-friendly message
        Get.snackbar(
          'No Locations',
          'No locations are currently available. Please contact administrator.',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } on AuthException catch (e) {
      errorMessage.value = 'Authentication failed: ${e.message}';
      print('🔴 AuthException in loadLocations(): ${e.message}');
      await _handleAuthFailure();
    } catch (e) {
      errorMessage.value = 'Failed to load locations: ${e.toString()}';
      print('🔴 Exception in loadLocations(): $e');
    } finally {
      isLoading.value = false;
      print('🟡 loadLocations() completed. isLoading: ${isLoading.value}');
    }
  }

  Future<void> loadSavedLocation() async {
    try {
      print('🟡 loadSavedLocation() started');
      final savedLocation = await _companyService.getSavedLocation();
      print(
        '🔵 Saved location from storage: ${savedLocation?.id} - ${savedLocation?.name}',
      );

      if (savedLocation != null) {
        print('🟡 Searching for saved location in current locations list');
        final currentLocation = locations.firstWhere(
          (location) => location.id == savedLocation.id,
          orElse: () {
            print('🔴 Saved location not found in current locations list');
            return Location();
          },
        );

        if (currentLocation.id != null) {
          selectedLocation.value = currentLocation;
          print('🟢 Saved location restored: ${currentLocation.name}');
        } else {
          print('🔴 Current location has null ID, not restoring');
        }
      } else {
        print('🔵 No saved location found in storage');
      }
    } catch (e) {
      print('🔴 Error loading saved location: $e');
    }
  }

  void onLocationSelected(Location? location) {
    print('🟡 onLocationSelected called with: ${location?.name}');

    selectedLocation.value = location;

    if (location != null) {
      print('🟢 Location selected: ${location.name} (${location.id})');
      _saveLocationSelection(location);
    } else {
      print('🔴 Location selection is null');
    }
  }

  Future<void> _saveLocationSelection(Location location) async {
    try {
      print('🟡 _saveLocationSelection started for: ${location.name}');
      await _companyService.saveSelectedLocation(location);

      // Also save to auth storage for quick access
      await _authStorage.init();
      final prefs = await SharedPreferences.getInstance();

      // ✅ Save with BOTH key formats to be safe
      await prefs.setString('main_location_id', location.id ?? '');
      await prefs.setString('main_location_name', location.name ?? '');
      await prefs.setString('main_location_code', location.code ?? '');

      // ✅ ALSO save with the keys that DashboardController expects
      await prefs.setString('locationId', location.id ?? '');
      await prefs.setString('locationName', location.name ?? '');

      print('🟢 Location selection saved: ${location.name} (${location.code})');
    } catch (e) {
      errorMessage.value = 'Failed to save location: ${e.toString()}';
      print('🔴 Error saving location selection: $e');
    }
  }

  bool validateSelection() {
    final isValid =
        selectedLocation.value != null &&
        selectedLocation.value!.id != null &&
        selectedLocation.value!.id!.isNotEmpty;

    print(
      '🔵 validateSelection(): $isValid (selected: ${selectedLocation.value?.name})',
    );
    return isValid;
  }

  Future<void> proceedToHome() async {
    print('🟡 proceedToHome() called');

    if (!validateSelection()) {
      print('🔴 Validation failed, showing snackbar');
      Get.snackbar(
        'Selection Required',
        'Please select a location to proceed',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return;
    }

    try {
      isLoading.value = true;
      print('🟡 Proceeding to home, checking authentication...');

      // Double-check authentication before proceeding
      final authValid = await _authMiddleware.validateSession();
      print('🔵 Final auth validation: $authValid');

      if (!authValid) {
        throw AuthException('Session validation failed');
      }

      // Save final location selection
      await _saveLocationSelection(selectedLocation.value!);

      // Navigate to home
      print('🟢 All validations passed, navigating to home');
      Get.offAllNamed('/home');
    } on AuthException catch (e) {
      errorMessage.value = 'Authentication error: ${e.message}';
      print('🔴 AuthException in proceedToHome(): ${e.message}');
      await _handleAuthFailure();
    } catch (e) {
      errorMessage.value = 'Error proceeding to home: ${e.toString()}';
      print('🔴 Exception in proceedToHome(): $e');

      Get.snackbar(
        'Error',
        'Failed to proceed: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
      print('🟡 proceedToHome() completed');
    }
  }

  Future<void> _handleAuthFailure() async {
    try {
      print('🟡 _handleAuthFailure() started');

      // Clear company-specific data
      await _companyService.clearSavedLocation();

      // Clear all auth data via middleware
      await _authMiddleware.forceLogout();

      // Navigate to login
      print('🔴 Auth failure handled, redirecting to login');
      Get.offAllNamed('/login');
    } catch (e) {
      print('🔴 Error handling auth failure: $e');
    }
  }

  // Refresh locations manually
  Future<void> refreshLocations() async {
    print('🟡 Manual refresh requested');
    await loadLocations();
  }

  // ✅ Add reset method to clear initialization state (useful for testing)
  void resetInitialization() {
    isInitialized = false;
    print('🔄 Controller initialization state reset');
  }

  @override
  void onClose() {
    print('🔴 CompanyController disposed');
    isInitialized = false;
    super.onClose();
  }
}
