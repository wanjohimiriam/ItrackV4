import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:get/get.dart';
import 'package:itrack/http/model/locationmodel.dart';
import 'package:itrack/http/service/endpoints.dart';
import 'package:itrack/http/service/authstorage.dart';
import 'package:itrack/http/service/authmiddleware.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CompanyService {
  final AuthMiddleware _authMiddleware = AuthMiddleware.instance;
  final AuthStorage _authStorage = AuthStorage.instance;
  static const String _locationKey = 'saved_location';

  // Main method - get locations from API only
 Future<List<Location>> getLocations() async {
    try {
      print('🟡 CompanyService: Fetching all locations');
      
      final response = await _authMiddleware.get(ApiEndPoints.getLocations);
      
      print('🔵 Response Status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        
        // Handle paginated response format
        if (jsonData is Map && jsonData.containsKey('data')) {
          final List<dynamic> data = jsonData['data'];
          print('🟢 Fetched ${data.length} locations from API');
          return data.map((json) => Location.fromJson(json)).toList();
        }
        // Handle direct array response
        else if (jsonData is List) {
          print('🟢 Fetched ${jsonData.length} locations from API');
          return jsonData.map((json) => Location.fromJson(json)).toList();
        }
        
        print('⚠️ Unexpected response format');
        return [];
      } else {
        print('🔴 Failed to fetch locations: ${response.statusCode}');
        throw Exception('Failed to load locations: ${response.statusCode}');
      }
    } catch (e) {
      print('🔴 Error in getLocations: $e');
      throw Exception('Error fetching locations: $e');
    }
  }

  // Safe method that returns empty list on non-auth errors
  Future<List<Location>> getLocationsSafe() async {
    try {
      return await getLocations();
    } on AuthException catch (e) {
      print('🔴 Authentication error loading locations: $e');
      rethrow; // Re-throw auth errors as they need special handling
    } catch (e) {
      print('🔴 Error loading locations (returning empty list): $e');
      return []; // Return empty list for non-auth errors
    }
  }

  // Save selected company location to auth storage
 Future<void> saveSelectedLocation(Location location) async {
    try {
      print('🟡 Saving location: ${location.name}');
      final prefs = await SharedPreferences.getInstance();
      final locationJson = json.encode(location.toJson());
      await prefs.setString(_locationKey, locationJson);
      print('🟢 Location saved successfully');
    } catch (e) {
      print('🔴 Error saving location: $e');
      throw Exception('Failed to save location: $e');
    }
  }

  Future<Location?> getSavedLocation() async {
    try {
      print('🟡 Retrieving saved location');
      final prefs = await SharedPreferences.getInstance();
      final locationJson = prefs.getString(_locationKey);
      
      if (locationJson != null) {
        final locationMap = json.decode(locationJson);
        final location = Location.fromJson(locationMap);
        print('🟢 Retrieved saved location: ${location.name}');
        return location;
      }
      
      print('🔵 No saved location found');
      return null;
    } catch (e) {
      print('🔴 Error retrieving saved location: $e');
      return null;
    }
  }

  // Validate if user has selected a location
 Future<bool> hasSelectedLocation() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.containsKey(_locationKey);
    } catch (e) {
      print('🔴 Error checking saved location: $e');
      return false;
    }
  }

  // Clear saved location (for logout scenarios)
 Future<void> clearSavedLocation() async {
    try {
      print('🟡 Clearing saved location');
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_locationKey);
      print('🟢 Saved location cleared');
    } catch (e) {
      print('🔴 Error clearing saved location: $e');
      throw Exception('Failed to clear location: $e');
    }
  }

  // Check if a location is saved
  

  // Debug method to check user authentication state
  Future<Map<String, dynamic>> debugAuthState() async {
    try {
      final user = await _authStorage.getUser();
      final hasToken = await _authStorage.getAuthToken() != null;
      final isAuthenticated = await _authStorage.isAuthenticated();
      final hasLocation = await hasSelectedLocation();
      
      return {
        'hasUser': user != null,
        'userId': user?.id,
        'userName': user?.name,
        'userEmail': user?.email,
        'hasToken': hasToken,
        'isAuthenticated': isAuthenticated,
        'hasSelectedLocation': hasLocation,
        'savedLocation': await getSavedLocation(),
      };
    } catch (e) {
      return {
        'error': e.toString(),
        'hasUser': false,
        'userId': null,
        'hasToken': false,
        'isAuthenticated': false,
        'hasSelectedLocation': false,
      };
    }
  }
}