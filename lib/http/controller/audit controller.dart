// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:itrack/http/model/assetrequestmodel.dart';
import 'package:itrack/http/model/assetresponsemodel.dart';
import 'package:itrack/http/model/auditrequestmodel.dart';
import 'package:itrack/http/model/getcapturedropdownmodels.dart';
import 'package:itrack/http/model/locationmodel.dart';
import 'package:itrack/http/service/assetservice.dart';
import 'package:itrack/http/service/barcode_scanner_service.dart';
import 'package:itrack/http/service/companyservice.dart';
import 'package:itrack/views/widget/colors.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CaptureController extends GetxController {
  final AssetService _assetService;
  final CompanyService _companyService;

  CaptureController({
    AssetService? assetService,
    CompanyService? companyService,
  }) : _assetService = assetService ?? AssetService(),
       _companyService = companyService ?? CompanyService();

  // Text Controllers
  final barcodeController = TextEditingController();
  final barcodeHiddenController = TextEditingController();
  final serialNoController = TextEditingController();
  final assetDescController = TextEditingController();
  final assetClassCodeController = TextEditingController();
  final assetIdController = TextEditingController();
  final roomController = TextEditingController();
  final currentLocationController = TextEditingController();
  final emailController = TextEditingController();
  final unitController = TextEditingController();
  final costCenterController = TextEditingController();
  final commentController = TextEditingController();
  final purchasePriceController = TextEditingController();

  // Dropdown Values
  final RxString selectedAssetClass = ''.obs;
  final RxString selectedMainLocation = ''.obs;
  final RxString selectedCondition = ''.obs;
  final RxString selectedDepartment = ''.obs;
  final RxString selectedPerson = ''.obs;
  final RxString selectedPlantName = ''.obs;
  final RxString selectedPlantCode = ''.obs;
  final RxString selectedHeadDepartment = ''.obs;
  final RxString selectedSubLocation = ''.obs;
  final RxString selectedRoom = ''.obs;
  final RxBool showApproversField = false.obs;

  final RxList<String> selectedApprovers = <String>[].obs;
  final RxList<String> approversList = <String>[].obs;
  final TextEditingController conditionNotesController =
      TextEditingController();

  // IDs
  String? assetClassId;
  String? mainLocationId;
  String? subLocationId;
  String? roomDescId;
  String? conditionId;
  String? departmentId;
  String? personId;
  String? plantId;

  // Lists for dropdowns
  final RxList<String> assetClassList = <String>[].obs;
  final RxList<String> mainLocationList = <String>[].obs;
  final RxList<String> conditionList = <String>[].obs;
  final RxList<String> departmentList = <String>[].obs;
  final RxList<String> personList = <String>[].obs;
  final RxList<String> plantNameList = <String>[].obs;
  final RxList<String> plantCodeList = <String>[].obs;
  final RxList<String> subLocationList = <String>[].obs;
  final RxList<String> roomList = <String>[].obs;

  // Full object lists for ID mapping
  List<dynamic> assetTypeListFull = [];
  List<dynamic> locationListFull = [];
  List<dynamic> conditionListFull = [];
  List<dynamic> departmentListFull = [];
  List<dynamic> personListFull = [];
  List<dynamic> plantListFull = [];
  List<dynamic> subLocationListFull = [];
  List<dynamic> roomListFull = [];

  List<PlantModel> plantModels = [];
  List<DepartmentModel> departmentModels = [];
  List<CostCentreModel> costCentreModels = [];
  List<AssetTypeModel> assetTypeModels = [];
  List<ConditionModel> conditionModels = [];
  List<PersonModel> personModels = [];
  List<Location> locationModels = [];

  // State
  final RxBool isLoading = false.obs;
  final RxString saveType = 'insert'.obs;
  final RxBool isNewAsset = false.obs;

  // User data
  String tenantId = 'your-tenant-id';

  @override
  void onInit() {
    super.onInit();
    _initializeData();
    _setupBarcodeListener();
    _loadDropdownData();
    _loadSavedLocation(); // Load the saved company location
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      currentUserId = prefs.getString('user_id') ?? 'default-user-id';
      tenantId = prefs.getString('tenant_id') ?? 'default-tenant-id';
      print('🟢 Loaded user ID: $currentUserId');
      print('🟢 Loaded tenant ID: $tenantId');
    } catch (e) {
      print('🔴 Error loading user data: $e');
    }
  }

  void _initializeData() {
    // TODO: Get tenantId from user data
  }

  // Load saved location from SharedPreferences
  Future<void> _loadSavedLocation() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final locationName = prefs.getString('main_location_name');

      if (locationName != null && locationName.isNotEmpty) {
        currentLocationController.text = locationName;
        print('🟢 Loaded saved location: $locationName');
      } else {
        print('🟡 No saved location found');
      }
    } catch (e) {
      print('🔴 Error loading saved location: $e');
    }
  }

  void _setupBarcodeListener() {
    Timer? debounce;
    barcodeController.addListener(() {
      if (debounce?.isActive ?? false) debounce!.cancel();
      debounce = Timer(const Duration(seconds: 3), () {
        if (barcodeController.text.isNotEmpty) {
          getAssetDetails(barcodeController.text);
        }
      });
    });
  }

  Future<void> _loadDropdownData() async {
    try {
      isLoading.value = true;
      print('🟡 Loading dropdown data...');

      // Load all config data in parallel
      final results = await Future.wait([
        _assetService.getPlants(),
        _assetService.getDepartments(),
        _assetService.getCostCentres(),
        _assetService.getAssetTypes(),
        _assetService.getConditions(),
        _assetService.getPersons(),
        _companyService.getLocations(),
      ]);

      // Plants
      plantModels = results[0] as List<PlantModel>;
      plantNameList.value = plantModels.map((p) => p.name).toList();
      print('🟢 Loaded ${plantModels.length} plants');

      // Departments - Remove duplicates using toSet()
      departmentModels = results[1] as List<DepartmentModel>;
      departmentList.value = departmentModels
          .map((d) => d.name)
          .toSet() // Remove duplicates
          .toList();
      print(
        '🟢 Loaded ${departmentModels.length} departments (${departmentList.length} unique)',
      );

      // Cost Centres
      costCentreModels = results[2] as List<CostCentreModel>;
      print('🟢 Loaded ${costCentreModels.length} cost centres');

      // Asset Types
      assetTypeModels = results[3] as List<AssetTypeModel>;
      assetClassList.value = assetTypeModels.map((a) => a.name).toList();
      print('🟢 Loaded ${assetTypeModels.length} asset types');

      // Conditions
      conditionModels = results[4] as List<ConditionModel>;
      conditionList.value = conditionModels.map((c) => c.name).toList();
      print('🟢 Loaded ${conditionModels.length} conditions');

      // In _loadDropdownData
      personModels = results[5] as List<PersonModel>;
      personList.value = personModels
          .where((p) => p.displayName.isNotEmpty || p.fullName.isNotEmpty)
          .map((p) => p.displayName.isNotEmpty ? p.displayName : p.fullName)
          .toList();
      print(
        '🟢 Loaded ${personModels.length} persons (${personList.length} with names)',
      );

      // Locations
      locationModels = results[6] as List<Location>;
      mainLocationList.value = locationModels
          .where((l) => l.name != null && l.name!.isNotEmpty)
          .map((l) => l.name!)
          .toList();
      print('🟢 Loaded ${locationModels.length} locations');

      print('🟢 All dropdown data loaded successfully');
    } catch (e) {
      print('🔴 Error loading dropdown data: $e');
      Get.snackbar(
        'Error',
        'Failed to load form data: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> getAssetDetails(String barcode) async {
    try {
      isLoading.value = true;
      print('🟡 Searching for asset with barcode: $barcode');

      final asset = await _assetService.getAssetByBarcode(barcode);

      print(
        '🔵 Asset service returned: ${asset != null ? "Asset found" : "No asset"}',
      );

      if (asset != null) {
        print('🔵 Asset details: ${asset.assetDescription}');
      }

      if (asset == null ||
          asset.assetDescription == null ||
          asset.assetDescription!.isEmpty ||
          asset.assetDescription == 'null') {
        // New Asset
        isLoading.value = false;
        isNewAsset.value = true;
        saveType.value = 'insert';

        print('🟡 New asset detected for barcode: $barcode');
        await _showNewAssetDialog(barcode);
      } else {
        // Existing Asset
        isLoading.value = false;
        isNewAsset.value = false;
        saveType.value = 'update';
        _autoFillAssetData(asset);

        print('🟢 Existing asset found and populated');
        Get.snackbar(
          'Asset Found',
          'Existing asset loaded successfully',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      isLoading.value = false;
      print('🔴 Error in getAssetDetails: $e');
      Get.snackbar(
        'Error',
        'Failed to fetch asset: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Future<void> _showNewAssetDialog(String barcode) async {
    await Get.defaultDialog(
      title: 'New Asset Detected',
      middleText:
          'This barcode belongs to a new asset. Would you like to add it to the system?',
      textConfirm: 'Yes, Add Asset',
      textCancel: 'Cancel',
      confirmTextColor: Colors.white,
      onConfirm: () {
        barcodeHiddenController.text = barcode;
        Get.back();
        _clearFormForNewAsset();
      },
      onCancel: () {
        barcodeController.clear();
        barcodeHiddenController.clear();
        Get.back();
      },
    );
  }

  void _clearFormForNewAsset() {
    serialNoController.clear();
    assetDescController.clear();
    assetClassCodeController.clear();
    assetIdController.clear();
    roomController.clear();
    commentController.clear();
    emailController.clear();
    unitController.clear();
    costCenterController.clear();
    purchasePriceController.clear();

    selectedAssetClass.value = '';
    selectedMainLocation.value = '';
    selectedCondition.value = '';
    selectedDepartment.value = '';
    selectedPerson.value = '';
    selectedPlantName.value = '';
    selectedPlantCode.value = '';
    selectedHeadDepartment.value = ''; // ✅ Added back
    selectedRoom.value = '';

    assetClassId = null;
    mainLocationId = null;
    roomDescId = null;
    conditionId = null;
    departmentId = null;
    personId = null;
    plantId = null;
  }

  // void _clearForm() {
  //   barcodeController.clear();
  //   barcodeHiddenController.clear();
  //   serialNoController.clear();
  //   assetDescController.clear();
  //   assetClassCodeController.clear();
  //   assetIdController.clear();
  //   roomController.clear();
  //   commentController.clear();
  //   emailController.clear();
  //   unitController.clear();
  //   costCenterController.clear();
  //   purchasePriceController.clear();

  //   selectedAssetClass.value = '';
  //   selectedMainLocation.value = '';
  //   selectedCondition.value = '';
  //   selectedDepartment.value = '';
  //   selectedPerson.value = '';
  //   selectedPlantName.value = '';
  //   selectedPlantCode.value = '';
  //   selectedHeadDepartment.value = ''; // ✅ Added back
  //   selectedSubLocation.value = '';
  //   selectedRoom.value = '';

  //   assetClassId = null;
  //   mainLocationId = null;
  //   subLocationId = null;
  //   roomDescId = null;
  //   conditionId = null;
  //   departmentId = null;
  //   personId = null;
  //   plantId = null;

  //   saveType.value = 'insert';
  //   isNewAsset.value = false;

  //   // Reload the saved location after clearing
  //   _loadSavedLocation();
  // }

  

  void _autoFillAssetData(AssetResponseModel asset) {
    barcodeHiddenController.text = asset.barcode ?? '';
    serialNoController.text = asset.serialNumber ?? '';
    assetDescController.text = asset.assetDescription ?? '';
    assetClassCodeController.text = asset.assetCode ?? '';
    assetIdController.text = asset.id ?? '';
    commentController.text = asset.comments ?? '';

    if (asset.purchasePrice != null) {
      purchasePriceController.text = asset.purchasePrice.toString();
    }

    // Populate dropdowns
    if (asset.assetTypeName != null)
      selectedAssetClass.value = asset.assetTypeName!;
    if (asset.conditionName != null)
      selectedCondition.value = asset.conditionName!;
    if (asset.departmentName != null)
      selectedDepartment.value = asset.departmentName!;
    if (asset.personName != null && asset.personName!.isNotEmpty) {
      selectedPerson.value = asset.personName!;
      print('🟢 Person populated from API: ${asset.personName}');
    }
    if (asset.locationName != null && asset.locationName!.isNotEmpty) {
      selectedMainLocation.value = asset.locationName!;
      print('🟢 Location populated from API: ${asset.locationName}');
    }
    if (asset.subLocationName != null)
      selectedSubLocation.value = asset.subLocationName!;
    if (asset.roomName != null) selectedRoom.value = asset.roomName!;
    if (asset.plantName != null) selectedPlantName.value = asset.plantName!;
    if (asset.plantCode != null) selectedPlantCode.value = asset.plantCode!;

    roomController.text = asset.roomName ?? '';

    // ✅ Populate unit and cost center directly from API response
    if (asset.unit != null && asset.unit!.isNotEmpty) {
      unitController.text = asset.unit!;
      print('🟢 Unit populated from API: ${asset.unit}');
    }

    if (asset.costCenter != null && asset.costCenter!.isNotEmpty) {
      costCenterController.text = asset.costCenter!;
      print('🟢 Cost Center populated from API: ${asset.costCenter}');
    }

    // ✅ Populate head of department from API
    if (asset.headofDepartment != null && asset.headofDepartment!.isNotEmpty) {
      selectedHeadDepartment.value = asset.headofDepartment!;
      print(
        '🟢 Head of Department populated from API: ${asset.headofDepartment}',
      );
    } else {
      selectedHeadDepartment.value = '';
      print('🟡 Head of Department not available in API response');
    }

    // ✅ Get email from person details
    if (asset.personId != null && personModels.isNotEmpty) {
      try {
        final person = personModels.firstWhere(
          (item) => item.id == asset.personId,
        );

        // Populate email from person model
        if (person.staffEmail.isNotEmpty) {
          emailController.text = person.staffEmail;
          print('🟢 Email populated from person model: ${person.staffEmail}');
        }

        // Override unit and cost center if person has more current data
        if (person.unit.isNotEmpty &&
            (asset.unit == null || asset.unit!.isEmpty)) {
          unitController.text = person.unit;
          print('🟢 Unit populated from person model: ${person.unit}');
        }

        if (person.costCenter.isNotEmpty &&
            (asset.costCenter == null || asset.costCenter!.isEmpty)) {
          costCenterController.text = person.costCenter;
          print(
            '🟢 Cost Center populated from person model: ${person.costCenter}',
          );
        }

        print('🟢 Additional person details loaded from person model');
      } catch (e) {
        print('🟡 Could not find person details in list: ${asset.personId}');

        // Fallback - if person not found in list, keep API values
        if (asset.email != null && asset.email!.isNotEmpty) {
          emailController.text = asset.email!;
          print('🟢 Email populated from API fallback: ${asset.email}');
        }
      }
    } else if (asset.email != null && asset.email!.isNotEmpty) {
      // If no person models loaded, use email from API if available
      emailController.text = asset.email!;
      print('🟢 Email populated from API: ${asset.email}');
    }

    // Store IDs
    assetClassId = asset.assetTypeId;
    conditionId = asset.conditionId;
    departmentId = asset.departmentId;
    personId = asset.personId;
    mainLocationId = asset.locationId;
    subLocationId = asset.subLocationId;
    roomDescId = asset.roomId;
    plantId = asset.plantId;

    print('🟢 Asset data populated successfully');
    print('📋 Asset Summary:');
    print('   Description: ${asset.assetDescription}');
    print('   Person: ${asset.personName}');
    print('   Department: ${asset.departmentName}');
    print('   Head of Dept: ${asset.headofDepartment ?? "Not available"}');
    print('   Unit: ${unitController.text}');
    print('   Cost Center: ${costCenterController.text}');
    print('   Email: ${emailController.text}');
    print('   Location: ${asset.locationName}');
    print('   Room: ${asset.roomName}');
    print('   Condition: ${asset.conditionName}');
  }

  void showPersonSearchDialog() {
    final searchController = TextEditingController();
    final RxList<PersonModel> filteredPersons = <PersonModel>[].obs;

    filteredPersons.value = personModels
        .where((p) => p.displayName.isNotEmpty || p.fullName.isNotEmpty)
        .toList();

    // Filter function
    void filterPersons(String query) {
      if (query.isEmpty) {
        filteredPersons.value = personModels
            .where((p) => p.displayName.isNotEmpty || p.fullName.isNotEmpty)
            .toList();
      } else {
        filteredPersons.value = personModels.where((p) {
          final name = p.displayName.isNotEmpty ? p.displayName : p.fullName;
          if (name.isEmpty) return false;

          final nameLower = name.toLowerCase();
          final emailLower = p.staffEmail.toLowerCase();
          final codeLower = p.personCode.toLowerCase();
          final queryLower = query.toLowerCase();
          return nameLower.contains(queryLower) ||
              emailLower.contains(queryLower) ||
              codeLower.contains(queryLower);
        }).toList();
      }
    }

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          width: Get.width * 0.9,
          height: Get.height * 0.7,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Title
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Select Person',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    onPressed: () => Get.back(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Search field
              TextField(
                controller: searchController,
                decoration: InputDecoration(
                  labelText: 'Search by name, email or code',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                onChanged: filterPersons,
              ),
              const SizedBox(height: 16),

              // Results count
              Obx(
                () => Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '${filteredPersons.length} persons found',
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // Person list
              Expanded(
                child: Obx(() {
                  if (filteredPersons.isEmpty) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.person_off, size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text(
                            'No persons found',
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: filteredPersons.length,
                    itemBuilder: (context, index) {
                      final person = filteredPersons[index];
                      final personName = person.displayName.isNotEmpty
                          ? person.displayName
                          : person.fullName;

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.green.shade100,
                          child: Text(
                            personName.substring(0, 1).toUpperCase(),
                            style: TextStyle(
                              color: Colors.green.shade800,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(
                          personName,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              person.staffEmail,
                              style: const TextStyle(fontSize: 12),
                            ),
                            Text(
                              person.personCode,
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                        onTap: () {
                          Get.back();
                          onPersonSelected(
                            personName,
                          ); // ✅ Fixed: pass personName
                        },
                      );
                    },
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void onPersonSelected(String value) {
    selectedPerson.value = value;

    // ✅ FIX: Find person by display name or full name, not just lastName
    PersonModel? person;
    try {
      person = personModels.firstWhere((item) {
        final displayName = item.displayName.isNotEmpty
            ? item.displayName
            : item.fullName;
        return displayName == value;
      });
    } catch (e) {
      print('🔴 Person not found: $value');
      person = null;
    }

    if (person != null && person.id.isNotEmpty) {
      personId = person.id;

      if (person.staffEmail.isNotEmpty) {
        emailController.text = person.staffEmail;
      }

      if (person.unit.isNotEmpty) {
        unitController.text = person.unit;
      }

      if (person.costCenter.isNotEmpty) {
        costCenterController.text = person.costCenter;
      }

      // ✅ FIX: Autofill department if it exists - with null safety
      if (person.departmentId != null && person.departmentId!.isNotEmpty) {
        try {
          final dept = departmentModels.firstWhere(
            (d) =>
                d.id == person!.departmentId, // ✅ Add null assertion operator
            orElse: () => DepartmentModel(
              id: '',
              name: '',
              code: '',
              isActive: false,
              tenantId: '',
            ),
          );
          if (dept.id.isNotEmpty && dept.name.isNotEmpty) {
            selectedDepartment.value = dept.name;
            departmentId = dept.id;
            print('🟢 Auto-filled department: ${dept.name}');
          }
        } catch (e) {
          print('🟡 Could not find department: ${person.departmentId}');
        }
      }

      print('🟢 Person selected: $value');
      print('   ID: ${person.id}');
      print('   Email: ${person.staffEmail}');
      print('   Unit: ${person.unit}');
      print('   Cost Center: ${person.costCenter}');
      print('   Department ID: ${person.departmentId ?? "None"}');
    } else {
      print('🔴 Failed to select person: $value');
    }
  }

  void showSearchDialog() {
    final searchController = TextEditingController();
    Get.defaultDialog(
      title: 'Search Asset',
      content: Padding(
        padding: const EdgeInsets.all(16.0),
        child: TextField(
          controller: searchController,
          decoration: const InputDecoration(
            labelText: 'Enter Asset ID or Barcode',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (value) {
            if (value.isNotEmpty) {
              Get.back();
              getAssetDetails(value);
            }
          },
        ),
      ),
      textConfirm: 'Search',
      textCancel: 'Cancel',
      confirmTextColor: Colors.white,
      onConfirm: () {
        if (searchController.text.isNotEmpty) {
          Get.back();
          getAssetDetails(searchController.text);
        }
      },
    );
  }
  // Add these to CaptureController class properties

  // Replace _loadDropdownData method

  // Update dropdown selection handlers
  void onAssetClassSelected(String value) {
    selectedAssetClass.value = value;
    final assetType = assetTypeModels.firstWhere(
      (item) => item.name == value,
      orElse: () => AssetTypeModel(
        id: '',
        name: '',
        code: '',
        isActive: false,
        tenantId: '',
      ),
    );
    if (assetType.id.isNotEmpty) {
      assetClassId = assetType.id;
      assetClassCodeController.text = assetType.code;
      print('🟢 Asset class selected: ${assetType.name} (${assetType.code})');
    }
  }

  void onPlantSelected(String value) {
    selectedPlantName.value = value;
    final plant = plantModels.firstWhere(
      (item) => item.name == value,
      orElse: () =>
          PlantModel(id: '', name: '', code: '', isActive: false, tenantId: ''),
    );
    if (plant.id.isNotEmpty) {
      plantId = plant.id;
      selectedPlantCode.value = plant.code;
      print('🟢 Plant selected: ${plant.name} - Code: ${plant.code}');
    }
  }

  void onDepartmentSelected(String value) {
    selectedDepartment.value = value;
    final dept = departmentModels.firstWhere(
      (item) => item.name == value,
      orElse: () => DepartmentModel(
        id: '',
        name: '',
        code: '',
        isActive: false,
        tenantId: '',
      ),
    );
    if (dept.id.isNotEmpty) {
      departmentId = dept.id;
      print('🟢 Department selected: ${dept.name}');
    }
  }

  void onConditionSelected(String value) {
    selectedCondition.value = value;
    final condition = conditionModels.firstWhere(
      (item) => item.name == value,
      orElse: () => ConditionModel(
        id: '',
        name: '',
        code: '',
        isActive: false,
        triggersInsuranceClaim: false,
        tenantId: '',
      ),
    );

    if (condition.id.isNotEmpty) {
      conditionId = condition.id;

      // ✅ Check if condition requires approvers
      final requiresApproval =
          value.toLowerCase() == 'decommission' ||
          value.toLowerCase() == 'stolen';
      showApproversField.value = requiresApproval;

      // Clear approvers if condition changed to one that doesn't require approval
      if (!requiresApproval) {
        selectedApprovers.clear();
        conditionNotesController.clear();
      }

      print('🟢 Condition selected: ${condition.name}');
      print('🔵 Requires approval: $requiresApproval');
    }
  }

  void _setDepartmentHead(String deptName) {
    try {
      final dept = departmentListFull.firstWhere(
        (item) => item['department_name'] == deptName,
      );
      if (dept != null && dept['department_head'] != null) {
        selectedHeadDepartment.value = dept['department_head'];
      }
    } catch (e) {
      // Department not found
    }
  }

  // Dropdown selection handlers

  void onMainLocationSelected(String value) {
    selectedMainLocation.value = value;

    // Find the location in the list
    final location = locationModels.firstWhere(
      (item) => item.name == value,
      orElse: () => Location(),
    );

    if (location.id != null && location.id!.isNotEmpty) {
      mainLocationId = location.id;

      // Autofill current location field with the selected location name
      currentLocationController.text = location.name ?? '';

      print('🟢 Location selected: ${location.name}');
      print('   ID: ${location.id}');
      print('   Code: ${location.code}');
      print('   Current Location autofilled: ${location.name}');
    }
  }

  //

  void onSubLocationSelected(String value) {
    selectedSubLocation.value = value;
    final subLoc = subLocationListFull.firstWhere(
      (item) => item['sub_location_name'] == value,
      orElse: () => null,
    );
    if (subLoc != null) {
      subLocationId = subLoc['id'];
    }
  }

  void onRoomSelected(String value) {
    selectedRoom.value = value;
    final room = roomListFull.firstWhere(
      (item) => item['room_name'] == value,
      orElse: () => null,
    );
    if (room != null) {
      roomDescId = room['id'];
    }
  }

  // Scanner methods
 Future<void> scanBarcode() async {
  try {
    final String? scannedCode = await BarcodeScannerService.scanBarcode(
      title: 'Scan Barcode',
      promptMessage: 'Align barcode within the frame',
    );

    if (scannedCode != null && scannedCode.isNotEmpty) {
      print('🟢 Barcode scanned: $scannedCode');
      
      // Set the barcode value
      barcodeController.text = scannedCode;
      
      // Automatically fetch asset details
      await getAssetDetails(scannedCode);
      
      Get.snackbar(
        'Barcode Scanned',
        'Code: $scannedCode',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
    } else {
      print('🟡 Barcode scanning cancelled');
    }
  } catch (e) {
    print('🔴 Error scanning barcode: $e');
    Get.snackbar(
      'Error',
      'Failed to scan barcode: $e',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.red,
      colorText: Colors.white,
    );
  }
}

// Update the scanSerialNumber method
Future<void> scanSerialNumber() async {
  try {
    final String? scannedCode = await BarcodeScannerService.scanBarcode(
      title: 'Scan Serial Number',
      promptMessage: 'Align serial number barcode within the frame',
    );

    if (scannedCode != null && scannedCode.isNotEmpty) {
      print('🟢 Serial number scanned: $scannedCode');
      
      // Set the serial number value
      serialNoController.text = scannedCode;
      
      Get.snackbar(
        'Serial Number Scanned',
        'Code: $scannedCode',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
    } else {
      print('🟡 Serial number scanning cancelled');
    }
  } catch (e) {
    print('🔴 Error scanning serial number: $e');
    Get.snackbar(
      'Error',
      'Failed to scan serial number: $e',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.red,
      colorText: Colors.white,
    );
  }
}

  void showApproversDialog() {
    final searchController = TextEditingController();
    final RxList<PersonModel> filteredApprovers = <PersonModel>[].obs;

    filteredApprovers.value = personModels
        .where((p) => p.displayName.isNotEmpty || p.fullName.isNotEmpty)
        .toList();

    void filterApprovers(String query) {
      if (query.isEmpty) {
        filteredApprovers.value = personModels
            .where((p) => p.displayName.isNotEmpty || p.fullName.isNotEmpty)
            .toList();
      } else {
        filteredApprovers.value = personModels.where((p) {
          final name = p.displayName.isNotEmpty ? p.displayName : p.fullName;
          if (name.isEmpty) return false;

          final nameLower = name.toLowerCase();
          final emailLower = p.staffEmail.toLowerCase();
          final queryLower = query.toLowerCase();
          return nameLower.contains(queryLower) ||
              emailLower.contains(queryLower);
        }).toList();
      }
    }

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          width: Get.width * 0.9,
          height: Get.height * 0.7,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Title with selected count
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Select Approvers',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Obx(
                        () => Text(
                          '${selectedApprovers.length} selected',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: () => Get.back(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Search field
              TextField(
                controller: searchController,
                decoration: InputDecoration(
                  labelText: 'Search by name or email',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                onChanged: filterApprovers,
              ),
              const SizedBox(height: 16),

              // Results count
              Obx(
                () => Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '${filteredApprovers.length} persons found',
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // Approvers list
              Expanded(
                child: Obx(() {
                  if (filteredApprovers.isEmpty) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.person_off, size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text(
                            'No persons found',
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: filteredApprovers.length,
                    itemBuilder: (context, index) {
                      final person = filteredApprovers[index];
                      final personName = person.displayName.isNotEmpty
                          ? person.displayName
                          : person.fullName;
                      final isSelected = selectedApprovers.contains(person.id);

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isSelected
                              ? Colors.green.shade700
                              : Colors.green.shade100,
                          child: isSelected
                              ? const Icon(Icons.check, color: Colors.white)
                              : Text(
                                  personName.substring(0, 1).toUpperCase(),
                                  style: TextStyle(
                                    color: Colors.green.shade800,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                        title: Text(
                          personName,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        subtitle: Text(
                          person.staffEmail,
                          style: const TextStyle(fontSize: 12),
                        ),
                        trailing: isSelected
                            ? const Icon(
                                Icons.check_circle,
                                color: Colors.green,
                              )
                            : null,
                        onTap: () {
                          if (isSelected) {
                            selectedApprovers.remove(person.id);
                          } else {
                            selectedApprovers.add(person.id);
                          }
                        },
                      );
                    },
                  );
                }),
              ),

              // Done button
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Get.back();
                    Get.snackbar(
                      'Approvers Selected',
                      '${selectedApprovers.length} approver(s) selected',
                      snackPosition: SnackPosition.BOTTOM,
                      backgroundColor: Colors.green,
                      colorText: Colors.white,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Done'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Save Asset
  // Add this property at the top of CaptureController
  String currentUserId = 'your-user-id'; // TODO: Get from auth service

  Future<void> saveAsset() async {
  if (barcodeHiddenController.text.isEmpty) {
    Get.snackbar(
      'Validation Error',
      'Barcode is required',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.orange,
      colorText: Colors.white,
    );
    return;
  }

  if (assetDescController.text.isEmpty) {
    Get.snackbar(
      'Validation Error',
      'Asset Description cannot be empty',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.orange,
      colorText: Colors.white,
    );
    return;
  }

  if (assetClassId == null) {
    Get.snackbar(
      'Validation Error',
      'Asset Type cannot be empty',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.orange,
      colorText: Colors.white,
    );
    return;
  }

  if (mainLocationId == null) {
    Get.snackbar(
      'Validation Error',
      'Location cannot be empty',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.orange,
      colorText: Colors.white,
    );
    return;
  }
  
  if (showApproversField.value && selectedApprovers.isEmpty) {
    Get.snackbar(
      'Validation Error',
      'Please select at least one approver for ${selectedCondition.value} condition',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.orange,
      colorText: Colors.white,
    );
    return;
  }

  try {
    isLoading.value = true;

    if (saveType.value == 'update') {
      // ✅ AUDIT MODE with approvers
      print('🔵 ========== AUDIT MODE ==========');

      final auditRequest = AuditAssetRequestModel(
        barcode: barcodeHiddenController.text,
        assetName: assetDescController.text,
        mainLocation: selectedMainLocation.value.isEmpty
            ? null
            : selectedMainLocation.value,
        newLocation: currentLocationController.text.isEmpty
            ? null
            : currentLocationController.text,
        subLocation: selectedSubLocation.value.isEmpty
            ? null
            : selectedSubLocation.value,
        department: selectedDepartment.value.isEmpty
            ? null
            : selectedDepartment.value,
        userId: currentUserId,
        conditionId: conditionId,
        roomDesc: roomController.text.isEmpty ? null : roomController.text,
        moreText: commentController.text.isEmpty
            ? null
            : commentController.text,
        person: selectedPerson.value.isEmpty ? null : selectedPerson.value,
        pfNo: null,
        subLocationId: subLocationId,
        subSubLocationId: null,
        condition: selectedCondition.value.isEmpty
            ? null
            : selectedCondition.value,
        tenantId: tenantId,
        conditionChangeApprovers:
            showApproversField.value && selectedApprovers.isNotEmpty
            ? selectedApprovers.toList()
            : null,
        conditionChangeNotes: conditionNotesController.text.isEmpty
            ? null
            : conditionNotesController.text,
      );

      print('🔵 Approvers: ${auditRequest.conditionChangeApprovers}');
      print('🔵 ========== AUDIT REQUEST JSON ==========');
      final jsonData = auditRequest.toJson();
      print(const JsonEncoder.withIndent('  ').convert(jsonData));
      print('🔵 ========================================');

      await _assetService.auditAsset(auditRequest);

      isLoading.value = false;

      // ✅ Show success dialog with checkmark
      await _showSuccessDialog(
        title: 'Audit Complete!',
        message: 'Asset audit for ${assetDescController.text} successfully completed',
      );
      
      _clearForm();
      
    } else {
      // ✅ CREATE MODE
      print('🔵 ========== CREATE MODE ==========');

      double? purchasePrice;
      if (purchasePriceController.text.isNotEmpty) {
        purchasePrice = double.tryParse(purchasePriceController.text);
      }

      final request = AssetRequestModel(
        assetDescription: assetDescController.text,
        serialNumber: serialNoController.text.isEmpty
            ? null
            : serialNoController.text,
        barcode: barcodeHiddenController.text,
        assetCode: assetIdController.text.isEmpty
            ? null
            : assetIdController.text,
        purchasePrice: purchasePrice,
        purchaseDate: DateTime.now(),
        assetTypeId: assetClassId!,
        conditionId: conditionId,
        departmentId: departmentId,
        locationId: mainLocationId!,
        roomId: roomDescId,
        plantId: plantId,
        personId: personId,
        person: selectedPerson.value.isEmpty ? null : selectedPerson.value,
        room: roomController.text.isEmpty ? null : roomController.text,
        comments: commentController.text.isEmpty
            ? null
            : commentController.text,
        unit: unitController.text.isEmpty ? null : unitController.text,
        costCenter: costCenterController.text.isEmpty
            ? null
            : costCenterController.text,
        tenantId: tenantId,
        triggerEmailNotification: true,
        status: 0,
        createDate: DateTime.now(),
        updateDate: null,
        createdBy: 'current_user',
      );

      print('🔵 ========== CREATE REQUEST JSON ==========');
      final jsonData = request.toJson();
      print(const JsonEncoder.withIndent('  ').convert(jsonData));
      print('🔵 ==========================================');

      final response = await _assetService.createAsset(request);

      isLoading.value = false;

      // ✅ Show success dialog with checkmark
      await _showSuccessDialog(
        title: 'Asset Created!',
        message: 'Asset ${assetDescController.text} successfully added to the system',
      );
      
      _clearForm();

      print('🟢 Asset saved successfully: ${response.id}');
    }
  } catch (e) {
    isLoading.value = false;
    print('🔴 ========== SAVE ASSET ERROR ==========');
    print('🔴 Error: $e');
    print('🔴 Stack trace: ${StackTrace.current}');
    print('🔴 ========================================');

    Get.snackbar(
      'Error',
      'Failed to save asset: $e',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.red,
      colorText: Colors.white,
      duration: const Duration(seconds: 5),
    );
  }
}

// ✅ Add this new method to show success dialog
Future<void> _showSuccessDialog({
  required String title,
  required String message,
}) async {
  await Get.dialog(
    Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ✅ Animated checkmark circle
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 600),
              builder: (context, value, child) {
                return Transform.scale(
                  scale: value,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 50,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            
            // Title
            Text(
              title,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            
            // Message
            Text(
              message,
              style: const TextStyle(
                fontSize: 15,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            
            // OK Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Get.back(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                child: const Text(
                  'OK',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
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

void _clearForm() {
  barcodeController.clear();
  barcodeHiddenController.clear();
  serialNoController.clear();
  assetDescController.clear();
  assetClassCodeController.clear();
  assetIdController.clear();
  roomController.clear();
  commentController.clear();
  emailController.clear();
  unitController.clear();
  costCenterController.clear();
  purchasePriceController.clear();
  
  // Clear approvers
  selectedApprovers.clear();
  showApproversField.value = false;
  conditionNotesController.clear();

  selectedAssetClass.value = '';
  selectedMainLocation.value = '';
  selectedCondition.value = '';
  selectedDepartment.value = '';
  selectedPerson.value = '';
  selectedPlantName.value = '';
  selectedPlantCode.value = '';
  selectedHeadDepartment.value = '';
  selectedSubLocation.value = '';
  selectedRoom.value = '';

  assetClassId = null;
  mainLocationId = null;
  subLocationId = null;
  roomDescId = null;
  conditionId = null;
  departmentId = null;
  personId = null;
  plantId = null;

  saveType.value = 'insert';
  isNewAsset.value = false;

  // Reload the saved location after clearing
  _loadSavedLocation();
}

  @override
  void onClose() {
    barcodeController.dispose();
    barcodeHiddenController.dispose();
    serialNoController.dispose();
    assetDescController.dispose();
    assetClassCodeController.dispose();
    assetIdController.dispose();
    roomController.dispose();
    currentLocationController.dispose();
    emailController.dispose();
    unitController.dispose();
    costCenterController.dispose();
    commentController.dispose();
    purchasePriceController.dispose();
    conditionNotesController.dispose();
    super.onClose();
  }
}
