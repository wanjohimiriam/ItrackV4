import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:itrack/http/controller/listcontroller.dart';
import 'package:itrack/http/model/auditlistmodel.dart';
import 'package:itrack/views/widget/colors.dart';

class ListofTodaysAudit extends StatelessWidget {
  const ListofTodaysAudit({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(AuditListController());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Asset Audit Mismatches'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterDialog(context, controller),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => controller.refreshAuditList(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          _buildSearchBar(controller),
          
          // Statistics Cards
          _buildStatisticsCards(controller),
          
          // Audit List
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }

              if (controller.errorMessage.value.isNotEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.red,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        controller.errorMessage.value,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () => controller.fetchAuditList(),
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                      ),
                    ],
                  ),
                );
              }

              final filteredList = controller.filteredAuditList;

              if (filteredList.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.check_circle_outline,
                        size: 64,
                        color: Colors.green[300],
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'No audit mismatches found',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        controller.searchQuery.value.isNotEmpty ||
                                controller.selectedLocation.value != 'All' ||
                                controller.selectedDepartment.value != 'All'
                            ? 'Try adjusting your filters'
                            : 'All assets are properly audited',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: controller.refreshAuditList,
                child: ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: filteredList.length,
                  itemBuilder: (context, index) {
                    final audit = filteredList[index];
                    return _buildAuditCard(context, audit);
                  },
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(AuditListController controller) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: TextField(
        onChanged: controller.setSearchQuery,
        decoration: InputDecoration(
          hintText: 'Search by asset name, barcode, or person...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: Obx(() => controller.searchQuery.value.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () => controller.setSearchQuery(''),
                )
              : const SizedBox.shrink()),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          filled: true,
          fillColor: Colors.grey[100],
        ),
      ),
    );
  }

  Widget _buildStatisticsCards(AuditListController controller) {
    return Obx(() {
      final stats = controller.auditStatistics;
      return SizedBox(
        height: 100,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          children: [
            _buildStatCard(
              'Total',
              stats['total'].toString(),
              Icons.list_alt,
              Colors.blue,
            ),
            _buildStatCard(
              'Condition',
              stats['conditionMismatch'].toString(),
              Icons.warning_amber,
              Colors.orange,
            ),
            _buildStatCard(
              'Person',
              stats['personMismatch'].toString(),
              Icons.person_off,
              Colors.purple,
            ),
            _buildStatCard(
              'Room',
              stats['roomMismatch'].toString(),
              Icons.room_outlined,
              Colors.green,
            ),
          ],
        ),
      );
    });
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Container(
        width: 115,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[600],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAuditCard(BuildContext context, AssetAuditMismatch audit) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showAuditDetails(context, audit),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Asset Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.deepPurple.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.inventory_2,
                      color: Colors.deepPurple,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          audit.assetName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          audit.barcode,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${audit.mismatchCount} Issues',
                      style: const TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Location and Department
              Row(
                children: [
                  _buildInfoChip(
                    Icons.location_on,
                    audit.mainLocation,
                    Colors.blue,
                  ),
                  const SizedBox(width: 8),
                  _buildInfoChip(
                    Icons.business,
                    audit.department,
                    Colors.green,
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Person and Date
              Row(
                children: [
                  _buildInfoChip(
                    Icons.person,
                    audit.person,
                    Colors.purple,
                  ),
                  const SizedBox(width: 8),
                  _buildInfoChip(
                    Icons.calendar_today,
                    DateFormat('dd/MM/yyyy').format(audit.createDate),
                    Colors.orange,
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Mismatch Summary
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.red.withOpacity(0.2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Mismatches:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 6),
                    ...audit.mismatchDetails.take(2).map(
                          (detail) => Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Row(
                              children: [
                                Icon(
                                  detail.getMismatchIcon(),
                                  size: 16,
                                  color: detail.getSeverityColor(),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    '${detail.field}: ${detail.actual ?? "N/A"}',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    if (audit.mismatchDetails.length > 2)
                      Text(
                        '+ ${audit.mismatchDetails.length - 2} more',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[600],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label, Color color) {
    return Flexible(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: color.withOpacity(0.8),
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFilterDialog(BuildContext context, AuditListController controller) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Audits'),
        content: Obx(() => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: controller.selectedLocation.value,
                  decoration: const InputDecoration(
                    labelText: 'Location',
                    border: OutlineInputBorder(),
                  ),
                  items: controller.uniqueLocations
                      .map((location) => DropdownMenuItem(
                            value: location,
                            child: Text(location),
                          ))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      controller.setLocationFilter(value);
                    }
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: controller.selectedDepartment.value,
                  decoration: const InputDecoration(
                    labelText: 'Department',
                    border: OutlineInputBorder(),
                  ),
                  items: controller.uniqueDepartments
                      .map((dept) => DropdownMenuItem(
                            value: dept,
                            child: Text(dept),
                          ))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      controller.setDepartmentFilter(value);
                    }
                  },
                ),
              ],
            )),
        actions: [
          TextButton(
            onPressed: () {
              controller.clearFilters();
              Navigator.pop(context);
            },
            child: const Text('Clear'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }

  void _showAuditDetails(BuildContext context, AssetAuditMismatch audit) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle bar
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                
                // Asset Details
                Text(
                  audit.assetName,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  audit.barcode,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                    fontFamily: 'monospace',
                  ),
                ),
                const SizedBox(height: 20),
                
                // Current vs Expected Section
                _buildComparisonSection(
                  'Location',
                  audit.assetCurrentLocation,
                  audit.mainLocation,
                ),
                _buildComparisonSection(
                  'Department',
                  audit.assetCurrentDepartment,
                  audit.department,
                ),
                _buildComparisonSection(
                  'Condition',
                  audit.assetCurrentCondition,
                  audit.condition,
                ),
                _buildComparisonSection(
                  'Assigned Person',
                  audit.person,
                  audit.assetCurrentPerson ?? 'None',
                ),
                
                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 10),
                
                // Mismatch Details
                const Text(
                  'Mismatch Details',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                
                ...audit.mismatchDetails.map(
                  (detail) => _buildMismatchDetailCard(detail),
                ),
                
                const SizedBox(height: 20),
                
                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          // Get controller instance
                          final ctrl = Get.find<AuditListController>();
                          
                          // Show confirmation dialog
                          final confirmed = await Get.dialog<bool>(
                            AlertDialog(
                              title: const Text('Resolve Audit'),
                              content: const Text(
                                'Are you sure you want to resolve this audit mismatch?',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Get.back(result: false),
                                  child: const Text('Cancel'),
                                ),
                                ElevatedButton(
                                  onPressed: () => Get.back(result: true),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    foregroundColor: Colors.white,
                                  ),
                                  child: const Text('Resolve'),
                                ),
                              ],
                            ),
                          );

                          if (confirmed == true) {
                            Navigator.pop(context);
                            await ctrl.resolveAudit(audit.id);
                          }
                        },
                        icon: const Icon(Icons.check_circle),
                        label: const Text('Resolve'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _showUpdateDialog(context, audit);
                        },
                        icon: const Icon(Icons.edit),
                        label: const Text('Update'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildComparisonSection(
    String label,
    String current,
    String expected,
  ) {
    final hasMatch = current.toLowerCase() == expected.toLowerCase();
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: hasMatch
                        ? Colors.green.withOpacity(0.1)
                        : Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: hasMatch
                          ? Colors.green.withOpacity(0.3)
                          : Colors.red.withOpacity(0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Scanned',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        current,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Icon(
                  hasMatch ? Icons.check_circle : Icons.arrow_forward,
                  color: hasMatch ? Colors.green : Colors.grey,
                ),
              ),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.blue.withOpacity(0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Expected',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        expected,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMismatchDetailCard(MismatchDetail detail) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: detail.getSeverityColor().withOpacity(0.3),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            Icon(
              detail.getMismatchIcon(),
              color: detail.getSeverityColor(),
              size: 28,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        detail.field,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: detail.getSeverityColor().withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          detail.severity,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: detail.getSeverityColor(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  if (detail.expected != null)
                    Text(
                      'Expected: ${detail.expected}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  if (detail.actual != null)
                    Text(
                      'Actual: ${detail.actual}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showUpdateDialog(
    BuildContext context,
    AssetAuditMismatch audit,
  ) {
    final controller = Get.find<AuditListController>();
    final conditionController = TextEditingController(text: audit.condition);
    final locationController = TextEditingController(text: audit.mainLocation);
    final departmentController = TextEditingController(text: audit.department);
    final personController = TextEditingController(text: audit.person);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Audit'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: conditionController,
                decoration: const InputDecoration(
                  labelText: 'Condition',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: locationController,
                decoration: const InputDecoration(
                  labelText: 'Location',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: departmentController,
                decoration: const InputDecoration(
                  labelText: 'Department',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: personController,
                decoration: const InputDecoration(
                  labelText: 'Assigned Person',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final updates = {
                'condition': conditionController.text,
                'mainLocation': locationController.text,
                'department': departmentController.text,
                'person': personController.text,
              };

              Navigator.pop(context);
              await controller.updateAudit(audit.id, updates);
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );

    // Cleanup controllers are automatically disposed by dialog
  }
}