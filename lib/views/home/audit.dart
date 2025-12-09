import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:itrack/http/controller/audit%20controller.dart';
import 'package:itrack/views/widget/colors.dart';

class CaptureScreen extends StatelessWidget {
  const CaptureScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<CaptureController>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            // Navigate back to home (which will show dashboard tab)
            Get.offAllNamed('/home');
          },
        ),
        title: const Text(
          'Asset Audit & Capture',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Obx(
        () => Stack(
          children: [
            SingleChildScrollView(
              child: Column(
                children: [
                  _buildHeaderCard(controller),
                  _buildAssetDetailsCard(controller),
                  _buildLocationCard(controller),
                  _buildUserDetailsCard(controller),
                  _buildAdditionalInfoCard(controller),
                  _buildSaveButton(controller),
                  const SizedBox(height: 20),
                ],
              ),
            ),
            if (controller.isLoading.value)
              Container(
                color: Colors.black54,
                child: const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCard(CaptureController controller) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppStyles.radiusMedium),
        boxShadow: AppStyles.elevatedShadow,
      ),
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(AppStyles.radiusSmall),
            ),
            child: const Icon(
              Icons.qr_code_scanner,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Asset Management',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Obx(
                  () => Text(
                    controller.isNewAsset.value
                        ? 'Adding New Asset'
                        : 'Updating Existing Asset',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAssetDetailsCard(CaptureController controller) {
    return _buildCard(
      'Asset Details',
      Icons.inventory_2,
      [
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: controller.scanBarcode,
                child: AbsorbPointer(
                  child: _buildTextField(
                    controller: controller.barcodeController,
                    label: 'Scan Barcode',
                    prefixIcon: Icons.qr_code_scanner,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: controller.showSearchDialog,
              icon: const Icon(Icons.search, size: 20),
              label: const Text('Search'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 18,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppStyles.radiusSmall),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildTextField(
          controller: controller.barcodeHiddenController,
          label: 'Barcode',
          prefixIcon: Icons.tag,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                controller: controller.serialNoController,
                label: 'Serial Number',
                prefixIcon: Icons.numbers,
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: controller.scanSerialNumber,
              icon: const Icon(Icons.qr_code_scanner, size: 20),
              label: const Text('Scan'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 18,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppStyles.radiusSmall),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildTextField(
          controller: controller.assetDescController,
          label: 'Asset Description *',
          prefixIcon: Icons.description,
        ),
        const SizedBox(height: 12),
        Obx(
          () => _buildDropdown(
            label: 'Asset Class *',
            value: controller.selectedAssetClass.value.isEmpty
                ? null
                : controller.selectedAssetClass.value,
            items: controller.assetClassList,
            onChanged: controller.onAssetClassSelected,
            prefixIcon: Icons.category,
          ),
        ),
        const SizedBox(height: 12),
        _buildTextField(
          controller: controller.assetClassCodeController,
          label: 'Asset Class Code',
          prefixIcon: Icons.code,
          enabled: false,
        ),
        const SizedBox(height: 12),
        _buildTextField(
          controller: controller.assetIdController,
          label: 'Asset Number',
          prefixIcon: Icons.pin,
        ),
      ],
    );
  }

  Widget _buildLocationCard(CaptureController controller) {
    return _buildCard(
      'Location Information',
      Icons.location_on,
      [
        Obx(
          () => _buildDropdown(
            label: 'Main Location *',
            value: controller.selectedMainLocation.value.isEmpty
                ? null
                : controller.selectedMainLocation.value,
            items: controller.mainLocationList,
            onChanged: controller.onMainLocationSelected,
            prefixIcon: Icons.business,
          ),
        ),
        const SizedBox(height: 12),
        _buildTextField(
          controller: controller.roomController,
          label: 'Room Description',
          prefixIcon: Icons.meeting_room,
        ),
        const SizedBox(height: 12),
        _buildTextField(
          controller: controller.currentLocationController,
          label: 'Current Location',
          prefixIcon: Icons.place,
          enabled: false,
        ),
        const SizedBox(height: 12),
        Obx(
          () => _buildDropdown(
            label: 'Plant Name',
            value: controller.selectedPlantName.value.isEmpty
                ? null
                : controller.selectedPlantName.value,
            items: controller.plantNameList,
            onChanged: controller.onPlantSelected,
            prefixIcon: Icons.factory,
          ),
        ),
        const SizedBox(height: 12),
        Obx(
          () => _buildTextField(
            controller: TextEditingController(
              text: controller.selectedPlantCode.value,
            ),
            label: 'Plant Code',
            prefixIcon: Icons.qr_code,
            enabled: false,
          ),
        ),
      ],
    );
  }

 Widget _buildUserDetailsCard(CaptureController controller) {
  return _buildCard(
    'User Details',
    Icons.people,
    [
      // Person search field
      InkWell(
        onTap: controller.showPersonSearchDialog,
        borderRadius: BorderRadius.circular(AppStyles.radiusSmall),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(AppStyles.radiusSmall),
          ),
          child: Row(
            children: [
              const Icon(Icons.person, color: AppColors.primary, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Obx(() => Text(
                  controller.selectedPerson.value.isEmpty
                      ? 'Select Person'
                      : controller.selectedPerson.value,
                  style: TextStyle(
                    fontSize: 14,
                    color: controller.selectedPerson.value.isEmpty
                        ? AppColors.textSecondary
                        : AppColors.textPrimary,
                  ),
                )),
              ),
              const Icon(Icons.search, color: AppColors.textSecondary, size: 20),
            ],
          ),
        ),
      ),
      const SizedBox(height: 12),
      Obx(
        () => _buildDropdown(
          label: 'Department',
          value: controller.selectedDepartment.value.isEmpty
              ? null
              : controller.selectedDepartment.value,
          items: controller.departmentList,
          onChanged: controller.onDepartmentSelected,
          prefixIcon: Icons.corporate_fare,
        ),
      ),
      const SizedBox(height: 12),
      _buildTextField(
        controller: controller.emailController,
        label: 'Email',
        prefixIcon: Icons.email,
        enabled: false,
      ),
      const SizedBox(height: 12),
      // ✅ Head of Department field - displays value from API
      Obx(
        () => _buildTextField(
          controller: TextEditingController(
            text: controller.selectedHeadDepartment.value,
          ),
          label: 'Department Head',
          prefixIcon: Icons.badge,
          enabled: false,
        ),
      ),
      const SizedBox(height: 12),
      _buildTextField(
        controller: controller.unitController,
        label: 'Unit',
        prefixIcon: Icons.business_center,
        enabled: false,
      ),
      const SizedBox(height: 12),
      _buildTextField(
        controller: controller.costCenterController,
        label: 'Cost Center',
        prefixIcon: Icons.account_balance,
        enabled: false,
      ),
    ],
  );
}
  

  Widget _buildAdditionalInfoCard(CaptureController controller) {
  return _buildCard(
    'Additional Information',
    Icons.info_outline,
    [
      Obx(
        () => _buildConditionDropdown(
          controller: controller,
          label: 'Condition',
          value: controller.selectedCondition.value.isEmpty
              ? null
              : controller.selectedCondition.value,
          items: controller.conditionList,
          onChanged: controller.onConditionSelected,
          prefixIcon: Icons.health_and_safety,
        ),
      ),
      
      // ✅ NEW: Conditional Approvers Section
      Obx(() {
        if (!controller.showApproversField.value) {
          return const SizedBox.shrink();
        }
        
        return Column(
          children: [
            const SizedBox(height: 16),
            
            // Warning banner
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                border: Border.all(color: Colors.orange.shade200),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber, color: Colors.orange.shade700),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'This condition change requires approval',
                      style: TextStyle(
                        color: Colors.orange.shade900,
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Approvers selection button
            InkWell(
              onTap: controller.showApproversDialog,
              borderRadius: BorderRadius.circular(AppStyles.radiusSmall),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: controller.selectedApprovers.isEmpty 
                        ? Colors.orange.shade300 
                        : AppColors.border,
                    width: controller.selectedApprovers.isEmpty ? 2 : 1,
                  ),
                  borderRadius: BorderRadius.circular(AppStyles.radiusSmall),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.approval,
                      color: controller.selectedApprovers.isEmpty 
                          ? Colors.orange 
                          : AppColors.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Obx(() => Text(
                        controller.selectedApprovers.isEmpty
                            ? 'Select Approvers *'
                            : '${controller.selectedApprovers.length} Approver(s) Selected',
                        style: TextStyle(
                          fontSize: 14,
                          color: controller.selectedApprovers.isEmpty
                              ? Colors.orange.shade700
                              : AppColors.textPrimary,
                          fontWeight: controller.selectedApprovers.isEmpty 
                              ? FontWeight.w500 
                              : FontWeight.normal,
                        ),
                      )),
                    ),
                    const Icon(Icons.arrow_forward_ios, 
                        color: AppColors.textSecondary, size: 16),
                  ],
                ),
              ),
            ),
            
            // ✅ NEW: Display selected approvers as chips
            Obx(() {
              if (controller.selectedApprovers.isEmpty) {
                return const SizedBox.shrink();
              }
              
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),
                  const Text(
                    'Selected Approvers:',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: controller.selectedApprovers.map((approverId) {
                      // Find the person details for this approver
                      final person = controller.personModels.firstWhere(
                        (p) => p.id == approverId,
                        orElse: () => controller.personModels.first,
                      );
                      
                      final personName = person.displayName.isNotEmpty 
                          ? person.displayName 
                          : person.fullName;
                      
                      return Chip(
                        avatar: CircleAvatar(
                          backgroundColor: AppColors.primary,
                          child: Text(
                            personName.substring(0, 1).toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        label: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              personName,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            if (person.staffEmail.isNotEmpty)
                              Text(
                                person.staffEmail,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                          ],
                        ),
                        deleteIcon: const Icon(
                          Icons.cancel,
                          size: 18,
                        ),
                        onDeleted: () {
                          controller.selectedApprovers.remove(approverId);
                        },
                        backgroundColor: Colors.green.shade50,
                        deleteIconColor: Colors.red.shade400,
                        side: BorderSide(
                          color: Colors.green.shade200,
                          width: 1,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 8,
                        ),
                      );
                    }).toList(),
                  ),
                ],
              );
            }),
            
            const SizedBox(height: 12),
            
            // Condition change notes
            _buildTextField(
              controller: controller.conditionNotesController,
              label: 'Condition Change Notes',
              prefixIcon: Icons.note,
              maxLines: 3,
            ),
          ],
        );
      }),
      
      const SizedBox(height: 12),
      _buildTextField(
        controller: controller.commentController,
        label: 'Comments',
        prefixIcon: Icons.comment,
        maxLines: 3,
      ),
      const SizedBox(height: 12),
      _buildTextField(
        controller: controller.purchasePriceController,
        label: 'Purchase Price',
        prefixIcon: Icons.attach_money,
      ),
    ],
  );
}

  Widget _buildSaveButton(CaptureController controller) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton.icon(
          onPressed: controller.saveAsset,
          icon: const Icon(Icons.save, size: 22),
          label: Obx(
            () => Text(
              controller.saveType.value == 'update'
                  ? 'Update Asset'
                  : 'Save New Asset',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppStyles.radiusMedium),
            ),
            elevation: 4,
          ),
        ),
      ),
    );
  }

  Widget _buildCard(String title, IconData icon, List<Widget> children) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppStyles.radiusMedium),
        boxShadow: AppStyles.cardShadow,
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppStyles.radiusSmall),
                ),
                child: Icon(icon, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    IconData? prefixIcon,
    bool enabled = true,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      enabled: enabled,
      maxLines: maxLines,
      style: TextStyle(
        color: enabled ? AppColors.textPrimary : AppColors.textSecondary,
        fontSize: 14,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: enabled ? AppColors.textSecondary : AppColors.textSecondary,
          fontSize: 14,
        ),
        prefixIcon: prefixIcon != null
            ? Icon(
                prefixIcon,
                color: enabled ? AppColors.primary : AppColors.textSecondary,
                size: 20,
              )
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppStyles.radiusSmall),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppStyles.radiusSmall),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppStyles.radiusSmall),
          borderSide: const BorderSide(color: AppColors.borderFocused, width: 2),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppStyles.radiusSmall),
          borderSide: BorderSide(color: AppColors.border.withOpacity(0.5)),
        ),
        filled: !enabled,
        fillColor: enabled ? null : AppColors.background,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String? value,
    required RxList<String> items,
    required Function(String) onChanged,
    IconData? prefixIcon,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 14,
        ),
        prefixIcon: prefixIcon != null
            ? Icon(prefixIcon, color: AppColors.primary, size: 20)
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppStyles.radiusSmall),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppStyles.radiusSmall),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppStyles.radiusSmall),
          borderSide: const BorderSide(color: AppColors.borderFocused, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
      icon: const Icon(Icons.arrow_drop_down, color: AppColors.primary),
      items: items
          .map(
            (item) => DropdownMenuItem(
              value: item,
              child: Text(
                item,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          )
          .toList(),
      onChanged: (val) {
        if (val != null) onChanged(val);
      },
    );
  }
  
  Widget _buildConditionDropdown({
    required CaptureController controller,
    required String label,
    required String? value,
    required RxList<String> items,
    required Function(String) onChanged,
    IconData? prefixIcon,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 14,
        ),
        prefixIcon: prefixIcon != null
            ? Icon(prefixIcon, color: AppColors.primary, size: 20)
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppStyles.radiusSmall),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppStyles.radiusSmall),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppStyles.radiusSmall),
          borderSide: const BorderSide(color: AppColors.borderFocused, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
      icon: const Icon(Icons.arrow_drop_down, color: AppColors.primary),
      items: items
          .map(
            (item) {
              final needsWorkflow = controller.conditionNeedsWorkflow(item);
              return DropdownMenuItem(
                value: item,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        item,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (needsWorkflow) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade100,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.orange.shade300),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.approval, size: 12, color: Colors.orange.shade700),
                            const SizedBox(width: 4),
                            Text(
                              'Workflow',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: Colors.orange.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
          )
          .toList(),
      onChanged: (val) {
        if (val != null) onChanged(val);
      },
    );
  }
}