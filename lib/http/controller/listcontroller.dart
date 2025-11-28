import 'package:get/get.dart';
import 'package:itrack/http/model/auditlistmodel.dart';
import 'dart:developer' as developer;

import 'package:itrack/http/service/listservice.dart';

class AuditListController extends GetxController {
  final AuditListService _auditService = AuditListService.instance;

  // Observable list of audits
  final RxList<AssetAuditMismatch> auditList = <AssetAuditMismatch>[].obs;
  
  // Loading state
  final RxBool isLoading = false.obs;
  
  // Error message
  final RxString errorMessage = ''.obs;
  
  // Filter options
  final RxString selectedLocation = 'All'.obs;
  final RxString selectedDepartment = 'All'.obs;
  final RxString searchQuery = ''.obs;

  @override
  void onInit() {
    super.onInit();
    developer.log('🚀 AuditListController initialized', name: 'AuditController');
    fetchAuditList();
  }

  @override
  void onClose() {
    developer.log('❌ AuditListController disposed', name: 'AuditController');
    super.onClose();
  }

  // Fetch audit list from API using service
  Future<void> fetchAuditList() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';
      
      developer.log('📡 Starting audit list fetch...', name: 'AuditController');

      final audits = await _auditService.fetchAuditList();
      
      auditList.value = audits;
      
      developer.log('✨ Loaded ${auditList.length} audit records', name: 'AuditController');
      
      // Log first item for debugging
      if (auditList.isNotEmpty) {
        final first = auditList.first;
        developer.log(
          '📋 First audit: ${first.assetName} (${first.barcode}) - ${first.mismatchCount} mismatches',
          name: 'AuditController'
        );
      } else {
        developer.log('⚠️ No audit records found', name: 'AuditController');
      }
      
      // Log statistics
      final stats = auditStatistics;
      developer.log(
        '📈 Statistics - Total: ${stats['total']}, Condition: ${stats['conditionMismatch']}, Person: ${stats['personMismatch']}, Room: ${stats['roomMismatch']}',
        name: 'AuditController'
      );
    } on AuditServiceException catch (e) {
      final error = e.message;
      errorMessage.value = error;
      developer.log('❌ Service Error: $error', name: 'AuditController');
      
      // Show user-friendly error
      Get.snackbar(
        'Error',
        error,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 4),
      );
    } catch (e, stackTrace) {
      final error = 'Unexpected error: ${e.toString()}';
      errorMessage.value = error;
      developer.log(
        '❌ Unexpected Error: $e',
        name: 'AuditController',
        error: e,
        stackTrace: stackTrace
      );
      
      Get.snackbar(
        'Error',
        'An unexpected error occurred. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 4),
      );
    } finally {
      isLoading.value = false;
      developer.log('🏁 Loading completed. IsLoading: ${isLoading.value}', name: 'AuditController');
    }
  }

  // Refresh the list
  Future<void> refreshAuditList() async {
    developer.log('🔄 Refreshing audit list', name: 'AuditController');
    await fetchAuditList();
  }

  // Resolve an audit
  Future<void> resolveAudit(String auditId, {String? notes}) async {
    try {
      developer.log('📝 Resolving audit: $auditId', name: 'AuditController');
      
      final success = await _auditService.resolveAudit(auditId, notes: notes);
      
      if (success) {
        // Remove from list or refresh
        auditList.removeWhere((audit) => audit.id == auditId);
        
        developer.log('✅ Audit resolved successfully', name: 'AuditController');
        
        Get.snackbar(
          'Success',
          'Audit resolved successfully',
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 2),
        );
      }
    } catch (e) {
      developer.log('❌ Failed to resolve audit: $e', name: 'AuditController');
      
      Get.snackbar(
        'Error',
        'Failed to resolve audit',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
      );
    }
  }

  // Update an audit
  Future<void> updateAudit(String auditId, Map<String, dynamic> updates) async {
    try {
      developer.log('📝 Updating audit: $auditId', name: 'AuditController');
      
      final success = await _auditService.updateAudit(auditId, updates);
      
      if (success) {
        // Refresh the list to get updated data
        await fetchAuditList();
        
        developer.log('✅ Audit updated successfully', name: 'AuditController');
        
        Get.snackbar(
          'Success',
          'Audit updated successfully',
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 2),
        );
      }
    } catch (e) {
      developer.log('❌ Failed to update audit: $e', name: 'AuditController');
      
      Get.snackbar(
        'Error',
        'Failed to update audit',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
      );
    }
  }

  // Get filtered list based on search and filters
  List<AssetAuditMismatch> get filteredAuditList {
    var filtered = auditList.toList();
    
    developer.log(
      '🔍 Filtering - Location: ${selectedLocation.value}, Department: ${selectedDepartment.value}, Search: "${searchQuery.value}"',
      name: 'AuditController'
    );

    // Apply location filter
    if (selectedLocation.value != 'All') {
      final beforeCount = filtered.length;
      filtered = filtered
          .where((audit) => audit.mainLocation == selectedLocation.value)
          .toList();
      developer.log('📍 Location filter applied: $beforeCount → ${filtered.length}', name: 'AuditController');
    }

    // Apply department filter
    if (selectedDepartment.value != 'All') {
      final beforeCount = filtered.length;
      filtered = filtered
          .where((audit) => audit.department == selectedDepartment.value)
          .toList();
      developer.log('🏢 Department filter applied: $beforeCount → ${filtered.length}', name: 'AuditController');
    }

    // Apply search query
    if (searchQuery.value.isNotEmpty) {
      final beforeCount = filtered.length;
      filtered = filtered.where((audit) {
        final query = searchQuery.value.toLowerCase();
        return audit.assetName.toLowerCase().contains(query) ||
            audit.barcode.toLowerCase().contains(query) ||
            audit.person.toLowerCase().contains(query);
      }).toList();
      developer.log('🔎 Search filter applied: $beforeCount → ${filtered.length}', name: 'AuditController');
    }

    developer.log('✅ Final filtered count: ${filtered.length}', name: 'AuditController');
    return filtered;
  }

  // Get unique locations for filter
  List<String> get uniqueLocations {
    final locations = auditList.map((audit) => audit.mainLocation).toSet().toList();
    locations.sort();
    developer.log('📍 Unique locations: ${locations.length} - $locations', name: 'AuditController');
    return ['All', ...locations];
  }

  // Get unique departments for filter
  List<String> get uniqueDepartments {
    final departments = auditList.map((audit) => audit.department).toSet().toList();
    departments.sort();
    developer.log('🏢 Unique departments: ${departments.length} - $departments', name: 'AuditController');
    return ['All', ...departments];
  }

  // Get audit statistics
  Map<String, int> get auditStatistics {
    return {
      'total': auditList.length,
      'conditionMismatch': auditList.where((audit) => 
        audit.mismatchDetails.any((d) => d.type == 'CONDITION_MISMATCH')
      ).length,
      'personMismatch': auditList.where((audit) => 
        audit.mismatchDetails.any((d) => d.type == 'PERSON_MISMATCH')
      ).length,
      'roomMismatch': auditList.where((audit) => 
        audit.mismatchDetails.any((d) => d.type == 'ROOM_MISMATCH')
      ).length,
      'critical': auditList.where((audit) => audit.hasCriticalMismatches).length,
    };
  }

  // Set location filter
  void setLocationFilter(String location) {
    developer.log('📍 Setting location filter: $location', name: 'AuditController');
    selectedLocation.value = location;
  }

  // Set department filter
  void setDepartmentFilter(String department) {
    developer.log('🏢 Setting department filter: $department', name: 'AuditController');
    selectedDepartment.value = department;
  }

  // Set search query
  void setSearchQuery(String query) {
    developer.log('🔎 Setting search query: "$query"', name: 'AuditController');
    searchQuery.value = query;
  }

  // Clear all filters
  void clearFilters() {
    developer.log('🧹 Clearing all filters', name: 'AuditController');
    selectedLocation.value = 'All';
    selectedDepartment.value = 'All';
    searchQuery.value = '';
  }
}