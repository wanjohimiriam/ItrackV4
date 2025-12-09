// ignore_for_file: avoid_print

import 'dart:convert';
import 'package:get/get.dart';
import 'package:itrack/http/service/companyservice.dart';
import 'package:itrack/http/service/authstorage.dart';
import 'package:itrack/http/service/authmiddleware.dart';
import 'package:itrack/http/service/error_handler.dart';
import 'package:itrack/http/service/storage_keys.dart';
import 'package:itrack/http/model/locationmodel.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CompanyController extends GetxController {
  final CompanyService _companyService = CompanyService();
  final AuthStorage _authStorage = AuthStorage.instance;
  final AuthMiddleware _authMiddleware = AuthMiddleware.instance;

  var isLoading = false.obs;
  var locations = <Location>[].obs;
  var selectedLocation = Rxn<Location>();
  var errorMessage = ''.obs;
  var isAuthenticated = false.obs;
  var lastLoadTime = Rxn<DateTime>();
  
  // Cache duration - 5 minutes
  static const cacheDuration = Duration(minutes: 5);

  @override
  void onInit() {
    super.onInit();
    ErrorHandler.logInfo('CompanyController initialized', context: 'CompanyController');
    // Initialize auth when controller is created
    initializeAuth();
  }
  
  bool _shouldReloadLocations() {
    if (locations.isEmpty) return true;
    if (lastLoadTime.value == null) return true;
    
    final timeSinceLoad = DateTime.now().difference(lastLoadTime.value!);
    final shouldReload = timeSinceLoad > cacheDuration;
    
    ErrorHandler.logInfo(
      'Cache check: ${shouldReload ? "RELOAD" : "USE CACHE"} (age: ${timeSinceLoad.inMinutes}min)',
      context: 'CompanyController',
    );
    
    return shouldReload;
  }
  
  Future<List<Location>?> _loadLocationsFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedJson = prefs.getString('cached_locations');
      final cachedTime = prefs.getString('cached_locations_time');
      
      if (cachedJson == null || cachedTime == null) return null;
      
      final cacheAge = DateTime.now().difference(DateTime.parse(cachedTime));
      if (cacheAge > cacheDuration) {
        ErrorHandler.logInfo('Cache expired (${cacheAge.inMinutes}min old)', context: 'CompanyController');
        return null;
      }
      
      final List<dynamic> jsonList = json.decode(cachedJson);
      final locations = jsonList.map((json) => Location.fromJson(json)).toList();
      
      lastLoadTime.value = DateTime.parse(cachedTime);
      ErrorHandler.logInfo('Loaded ${locations.length} locations from SharedPreferences', context: 'CompanyController');
      
      return locations;
    } catch (e) {
      ErrorHandler.logWarning('Failed to load from cache: $e', context: 'CompanyController');
      return null;
    }
  }
  
  Future<void> _saveLocationsToCache(List<Location> locations) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = locations.map((loc) => loc.toJson()).toList();
      final jsonString = json.encode(jsonList);
      
      await prefs.setString('cached_locations', jsonString);
      await prefs.setString('cached_locations_time', DateTime.now().toIso8601String());
      
      ErrorHandler.logInfo('Saved ${locations.length} locations to SharedPreferences', context: 'CompanyController');
    } catch (e) {
      ErrorHandler.logWarning('Failed to save to cache: $e', context: 'CompanyController');
    }
  }

  Future<void> initializeAuth() async {
    try {
      ErrorHandler.logInfo('initializeAuth() started', context: 'CompanyController');

      // Initialize auth middleware
      await _authMiddleware.init();
      ErrorHandler.logInfo('AuthMiddleware initialized', context: 'CompanyController');

      // Check authentication status
      isAuthenticated.value = await _authStorage.isAuthenticated();
      ErrorHandler.logInfo('Authentication status: ${isAuthenticated.value}', context: 'CompanyController');

      if (isAuthenticated.value) {
        ErrorHandler.logInfo('User is authenticated, checking if locations need reload...', context: 'CompanyController');
        
        // Only load if cache is expired or empty
        if (_shouldReloadLocations()) {
          await loadLocations();
        } else {
          ErrorHandler.logInfo('Using cached locations (${locations.length} items)', context: 'CompanyController');
        }
        
        await loadSavedLocation();
      } else {
        errorMessage.value = 'User not authenticated';
        ErrorHandler.logWarning('User not authenticated, redirecting to login', context: 'CompanyController');
        Get.offAllNamed('/login');
      }
    } catch (e) {
      errorMessage.value = 'Authentication error: ${e.toString()}';
      ErrorHandler.handle(e, context: 'CompanyController.initializeAuth');
      Get.offAllNamed('/login');
    }
  }

  Future<void> loadLocations() async {
    try {
      ErrorHandler.logInfo('loadLocations() started', context: 'CompanyController');
      isLoading.value = true;
      errorMessage.value = '';

      // Try to load from cache first
      final cachedLocations = await _loadLocationsFromCache();
      if (cachedLocations != null && cachedLocations.isNotEmpty) {
        locations.assignAll(cachedLocations);
        ErrorHandler.logInfo('Loaded ${cachedLocations.length} locations from cache', context: 'CompanyController');
      }

      // Validate session first
      final sessionValid = await _authMiddleware.validateSession();
      ErrorHandler.logInfo('Session validation: $sessionValid', context: 'CompanyController');

      if (!sessionValid) {
        errorMessage.value = 'Session expired. Please login again.';
        ErrorHandler.logWarning('Session invalid, redirecting to login', context: 'CompanyController');
        Get.offAllNamed('/login');
        return;
      }

      // Load locations from API
      ErrorHandler.logInfo('Calling getLocations() from CompanyService...', context: 'CompanyController');
      final locationsList = await _companyService.getLocations();

      ErrorHandler.logInfo('Locations list received. Count: ${locationsList.length}', context: 'CompanyController');

      locations.assignAll(locationsList);
      lastLoadTime.value = DateTime.now();
      
      // Save to cache
      await _saveLocationsToCache(locationsList);
      ErrorHandler.logInfo('Locations assigned to observable. locations.length: ${locations.length}', context: 'CompanyController');

      // If no locations, show appropriate message
      if (locationsList.isEmpty) {
        errorMessage.value = 'No locations available for your account.';
        ErrorHandler.showWarning(
          'No locations are currently available. Please contact administrator.',
          title: 'No Locations',
        );
      }
    } on AuthException catch (e) {
      errorMessage.value = 'Authentication failed: ${e.message}';
      ErrorHandler.handle(e, context: 'CompanyController.loadLocations');
      await _handleAuthFailure();
    } catch (e) {
      errorMessage.value = 'Failed to load locations: ${e.toString()}';
      ErrorHandler.handle(e, context: 'CompanyController.loadLocations');
    } finally {
      isLoading.value = false;
      ErrorHandler.logInfo('loadLocations() completed', context: 'CompanyController');
    }
  }

  Future<void> loadSavedLocation() async {
    try {
      ErrorHandler.logInfo('loadSavedLocation() started', context: 'CompanyController');
      final savedLocation = await _companyService.getSavedLocation();
      ErrorHandler.logInfo('Saved location from storage: ${savedLocation?.id} - ${savedLocation?.name}', context: 'CompanyController');

      if (savedLocation != null) {
        ErrorHandler.logInfo('Searching for saved location in current locations list', context: 'CompanyController');
        final currentLocation = locations.firstWhere(
          (location) => location.id == savedLocation.id,
          orElse: () {
            ErrorHandler.logWarning('Saved location not found in current locations list', context: 'CompanyController');
            return Location();
          },
        );

        if (currentLocation.id != null) {
          selectedLocation.value = currentLocation;
          ErrorHandler.logInfo('Saved location restored: ${currentLocation.name}', context: 'CompanyController');
        } else {
          ErrorHandler.logWarning('Current location has null ID, not restoring', context: 'CompanyController');
        }
      } else {
        ErrorHandler.logInfo('No saved location found in storage', context: 'CompanyController');
      }
    } catch (e) {
      ErrorHandler.handle(e, context: 'CompanyController.loadSavedLocation', showSnackbar: false);
    }
  }

  void onLocationSelected(Location? location) {
    ErrorHandler.logInfo('onLocationSelected called with: ${location?.name}', context: 'CompanyController');

    selectedLocation.value = location;

    if (location != null) {
      ErrorHandler.logInfo('Location selected: ${location.name} (${location.id})', context: 'CompanyController');
      _saveLocationSelection(location);
    } else {
      ErrorHandler.logWarning('Location selection is null', context: 'CompanyController');
    }
  }

  Future<void> _saveLocationSelection(Location location) async {
    try {
      ErrorHandler.logInfo('Saving location: ${location.name}', context: 'CompanyController');
      await _companyService.saveSelectedLocation(location);

      // Save to SharedPreferences using centralized keys
      await _authStorage.init();
      final prefs = await SharedPreferences.getInstance();

      await prefs.setString(StorageKeys.locationId, location.id ?? '');
      await prefs.setString(StorageKeys.locationName, location.name ?? '');
      await prefs.setString(StorageKeys.locationCode, location.code ?? '');

      ErrorHandler.logInfo('Location saved: ${location.name} (${location.code})', context: 'CompanyController');
    } catch (e) {
      errorMessage.value = 'Failed to save location: ${e.toString()}';
      ErrorHandler.handle(e, context: 'CompanyController._saveLocationSelection');
    }
  }

  bool validateSelection() {
    final isValid =
        selectedLocation.value != null &&
        selectedLocation.value!.id != null &&
        selectedLocation.value!.id!.isNotEmpty;

    ErrorHandler.logInfo('validateSelection(): $isValid (selected: ${selectedLocation.value?.name})', context: 'CompanyController');
    return isValid;
  }

  Future<void> proceedToHome() async {
    ErrorHandler.logInfo('proceedToHome() called', context: 'CompanyController');

    if (!validateSelection()) {
      ErrorHandler.showWarning(
        'Please select a location to proceed',
        title: 'Selection Required',
      );
      return;
    }

    try {
      isLoading.value = true;
      ErrorHandler.logInfo('Proceeding to home, checking authentication...', context: 'CompanyController');

      // Double-check authentication before proceeding
      final authValid = await _authMiddleware.validateSession();
      ErrorHandler.logInfo('Final auth validation: $authValid', context: 'CompanyController');

      if (!authValid) {
        throw AuthException('Session validation failed');
      }

      // Save final location selection
      await _saveLocationSelection(selectedLocation.value!);

      // Navigate to home
      ErrorHandler.logInfo('All validations passed, navigating to home', context: 'CompanyController');
      Get.offAllNamed('/home');
    } on AuthException catch (e) {
      errorMessage.value = 'Authentication error: ${e.message}';
      ErrorHandler.handle(e, context: 'CompanyController.proceedToHome');
      await _handleAuthFailure();
    } catch (e) {
      errorMessage.value = 'Error proceeding to home: ${e.toString()}';
      ErrorHandler.handle(e, context: 'CompanyController.proceedToHome');
    } finally {
      isLoading.value = false;
      ErrorHandler.logInfo('proceedToHome() completed', context: 'CompanyController');
    }
  }

  Future<void> _handleAuthFailure() async {
    try {
      ErrorHandler.logInfo('_handleAuthFailure() started', context: 'CompanyController');

      // Clear company-specific data
      await _companyService.clearSavedLocation();

      // Clear all auth data via middleware
      await _authMiddleware.forceLogout();

      // Navigate to login
      ErrorHandler.logWarning('Auth failure handled, redirecting to login', context: 'CompanyController');
      Get.offAllNamed('/login');
    } catch (e) {
      ErrorHandler.handle(e, context: 'CompanyController._handleAuthFailure', showSnackbar: false);
    }
  }

  // Refresh locations manually
  Future<void> refreshLocations() async {
    ErrorHandler.logInfo('Manual refresh requested', context: 'CompanyController');
    await loadLocations();
  }

  @override
  void onClose() {
    ErrorHandler.logInfo('CompanyController disposed', context: 'CompanyController');
    super.onClose();
  }
}
