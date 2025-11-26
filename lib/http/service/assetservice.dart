import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:itrack/http/model/assetrequestmodel.dart';
import 'package:itrack/http/model/assetresponsemodel.dart';
import 'package:itrack/http/model/auditrequestmodel.dart';
import 'package:itrack/http/model/getcapturedropdownmodels.dart';
import 'package:itrack/http/service/endpoints.dart';
import 'package:itrack/http/service/authmiddleware.dart';

class AssetService {
  final http.Client _client;
  final AuthMiddleware _authMiddleware;

  AssetService({http.Client? client, AuthMiddleware? authMiddleware}) 
      : _client = client ?? http.Client(),
        _authMiddleware = authMiddleware ?? AuthMiddleware.instance;

  // Get asset by barcode
  Future<AssetResponseModel?> getAssetByBarcode(String barcode) async {
    try {
      final endpoint = ApiEndPoints.getAssetsByBarcode(barcode);
      print('🟡 Fetching asset with endpoint: $endpoint');
      
      final response = await _authMiddleware.get(endpoint);
      print('🔵 API Response Status: ${response.statusCode}');
      print('🔵 API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data == null || data.isEmpty) {
          print('🟡 No asset found for barcode: $barcode');
          return null;
        }
        
        if (data is List) {
          if (data.isEmpty) {
            print('🟡 Empty list returned for barcode: $barcode');
            return null;
          }
          print('🟡 List response, using first item');
          return AssetResponseModel.fromJson(data.first);
        }
        
        if (data is Map<String, dynamic>) {
          if (data['assetDescription'] == null || 
              data['assetDescription'] == 'null' || 
              (data['assetDescription'] as String).isEmpty) {
            print('🟡 Asset found but has empty description');
            return null;
          }
          print('🟡 Single object response found with valid data');
          return AssetResponseModel.fromJson(data);
        }
        
        print('🟡 Unknown response format: $data');
        return null;
        
      } else if (response.statusCode == 404) {
        print('🟡 404 - Asset not found for barcode: $barcode');
        return null;
      } else {
        print('🔴 API Error: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to load asset: ${response.statusCode}');
      }
    } catch (e) {
      print('🔴 Error fetching asset: $e');
      throw Exception('Error fetching asset: $e');
    }
  }

  // Get Plants
  Future<List<PlantModel>> getPlants() async {
    try {
      print('🟡 Fetching plants');
      final response = await _authMiddleware.get(ApiEndPoints.getPlants);
      
      print('🔵 Plants Response Status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final configResponse = ConfigResponse.fromJson(
          json.decode(response.body),
          (json) => PlantModel.fromJson(json),
        );
        print('🟢 Fetched ${configResponse.data.length} plants');
        return configResponse.data;
      } else {
        throw Exception('Failed to load plants: ${response.statusCode}');
      }
    } catch (e) {
      print('🔴 Error fetching plants: $e');
      throw Exception('Error fetching plants: $e');
    }
  }

  // Get Departments
  Future<List<DepartmentModel>> getDepartments() async {
    try {
      print('🟡 Fetching departments');
      final response = await _authMiddleware.get(ApiEndPoints.getDepartments);
      
      print('🔵 Departments Response Status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final configResponse = ConfigResponse.fromJson(
          json.decode(response.body),
          (json) => DepartmentModel.fromJson(json),
        );
        print('🟢 Fetched ${configResponse.data.length} departments');
        return configResponse.data;
      } else {
        throw Exception('Failed to load departments: ${response.statusCode}');
      }
    } catch (e) {
      print('🔴 Error fetching departments: $e');
      throw Exception('Error fetching departments: $e');
    }
  }

  // Get Cost Centres
  Future<List<CostCentreModel>> getCostCentres() async {
    try {
      print('🟡 Fetching cost centres');
      final response = await _authMiddleware.get(ApiEndPoints.getCostCentres);
      
      print('🔵 Cost Centres Response Status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final configResponse = ConfigResponse.fromJson(
          json.decode(response.body),
          (json) => CostCentreModel.fromJson(json),
        );
        print('🟢 Fetched ${configResponse.data.length} cost centres');
        return configResponse.data;
      } else {
        throw Exception('Failed to load cost centres: ${response.statusCode}');
      }
    } catch (e) {
      print('🔴 Error fetching cost centres: $e');
      throw Exception('Error fetching cost centres: $e');
    }
  }

  // Get Asset Types
  Future<List<AssetTypeModel>> getAssetTypes() async {
    try {
      print('🟡 Fetching asset types');
      final response = await _authMiddleware.get(ApiEndPoints.getAssetTypes);
      
      print('🔵 Asset Types Response Status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final configResponse = ConfigResponse.fromJson(
          json.decode(response.body),
          (json) => AssetTypeModel.fromJson(json),
        );
        print('🟢 Fetched ${configResponse.data.length} asset types');
        return configResponse.data;
      } else {
        throw Exception('Failed to load asset types: ${response.statusCode}');
      }
    } catch (e) {
      print('🔴 Error fetching asset types: $e');
      throw Exception('Error fetching asset types: $e');
    }
  }

  // Get Conditions
  Future<List<ConditionModel>> getConditions() async {
    try {
      print('🟡 Fetching conditions');
      final response = await _authMiddleware.get(ApiEndPoints.getConditions);
      
      print('🔵 Conditions Response Status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final configResponse = ConfigResponse.fromJson(
          json.decode(response.body),
          (json) => ConditionModel.fromJson(json),
        );
        print('🟢 Fetched ${configResponse.data.length} conditions');
        return configResponse.data;
      } else {
        throw Exception('Failed to load conditions: ${response.statusCode}');
      }
    } catch (e) {
      print('🔴 Error fetching conditions: $e');
      throw Exception('Error fetching conditions: $e');
    }
  }

  // Create new asset
  Future<AssetResponseModel> createAsset(AssetRequestModel request) async {
    try {
      print('🟡 Creating new asset: ${request.assetDescription}');
      print('🟡 Request data: ${request.toJson()}');
      
      final response = await _authMiddleware.post(
        ApiEndPoints.AddAssets,
        body: request.toJson(),
      );

      print('🔵 Create Asset Response Status: ${response.statusCode}');
      print('🔵 Create Asset Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        
        if (data is List && data.isNotEmpty) {
          return AssetResponseModel.fromJson(data.first);
        } else if (data is Map<String, dynamic>) {
          return AssetResponseModel.fromJson(data);
        } else {
          throw Exception('Unexpected response format from create asset API');
        }
      } else {
        final errorBody = response.body;
        print('🔴 Create Asset Failed: ${response.statusCode} - $errorBody');
        throw Exception('Failed to create asset: ${response.statusCode} - $errorBody');
      }
    } catch (e) {
      print('🔴 Error creating asset: $e');
      throw Exception('Error creating asset: $e');
    }
  }

  // Update existing asset
  Future<AssetResponseModel> updateAsset(AssetRequestModel request) async {
    try {
      print('🟡 Updating asset: ${request.assetDescription}');
      print('🟡 Request data: ${request.toJson()}');
      
      final response = await _authMiddleware.put(
        ApiEndPoints.updateAsset,
        body: request.toJson(),
      );

      print('🔵 Update Asset Response Status: ${response.statusCode}');
      print('🔵 Update Asset Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data is List && data.isNotEmpty) {
          return AssetResponseModel.fromJson(data.first);
        } else if (data is Map<String, dynamic>) {
          return AssetResponseModel.fromJson(data);
        } else {
          throw Exception('Unexpected response format from update asset API');
        }
      } else {
        final errorBody = response.body;
        print('🔴 Update Asset Failed: ${response.statusCode} - $errorBody');
        throw Exception('Failed to update asset: ${response.statusCode} - $errorBody');
      }
    } catch (e) {
      print('🔴 Error updating asset: $e');
      throw Exception('Error updating asset: $e');
    }
  }

  // Audit asset
  Future<void> auditAsset(AuditAssetRequestModel request) async {
    try {
      print('🟡 Auditing asset');
      
      final response = await _authMiddleware.post(
        ApiEndPoints.updateAsset,
        body: request.toJson(),
      );

      print('🔵 Audit Asset Response Status: ${response.statusCode}');

      if (response.statusCode != 200 && response.statusCode != 201) {
        final errorBody = response.body;
        print('🔴 Audit Asset Failed: ${response.statusCode} - $errorBody');
        throw Exception('Failed to audit asset: ${response.statusCode} - $errorBody');
      }
      
      print('🟢 Audit completed successfully');
    } catch (e) {
      print('🔴 Error auditing asset: $e');
      throw Exception('Error auditing asset: $e');
    }
  }
  // Add this method to AssetService class

// Get Persons
Future<List<PersonModel>> getPersons() async {
  try {
    print('🟡 Fetching persons');
    final response = await _authMiddleware.get(ApiEndPoints.getPersons);
    
    print('🔵 Persons Response Status: ${response.statusCode}');
    
    if (response.statusCode == 200) {
      final configResponse = ConfigResponse.fromJson(
        json.decode(response.body),
        (json) => PersonModel.fromJson(json),
      );
      print('🟢 Fetched ${configResponse.data.length} persons');
      return configResponse.data;
    } else {
      throw Exception('Failed to load persons: ${response.statusCode}');
    }
  } catch (e) {
    print('🔴 Error fetching persons: $e');
    throw Exception('Error fetching persons: $e');
  }
}

  void dispose() {
    _client.close();
  }
}