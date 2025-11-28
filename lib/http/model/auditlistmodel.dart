import 'package:flutter/material.dart';

class AssetAuditMismatch {
  final String id;
  final String barcode;
  final String assetName;
  final DateTime createDate;
  final String mainLocation;
  final String department;
  final String condition;
  final String person;
  final String assetCurrentLocation;
  final String assetCurrentDepartment;
  final String assetCurrentCondition;
  final String? assetCurrentPerson;
  final List<MismatchDetail> mismatchDetails;

  AssetAuditMismatch({
    required this.id,
    required this.barcode,
    required this.assetName,
    required this.createDate,
    required this.mainLocation,
    required this.department,
    required this.condition,
    required this.person,
    required this.assetCurrentLocation,
    required this.assetCurrentDepartment,
    required this.assetCurrentCondition,
    this.assetCurrentPerson,
    required this.mismatchDetails,
  });

  factory AssetAuditMismatch.fromJson(Map<String, dynamic> json) {
    return AssetAuditMismatch(
      id: json['id'] ?? '',
      barcode: json['barcode'] ?? '',
      assetName: json['assetName'] ?? '',
      createDate: DateTime.parse(json['createDate']),
      mainLocation: json['mainLocation'] ?? '',
      department: json['department'] ?? '',
      condition: json['condition'] ?? '',
      person: json['person'] ?? '',
      assetCurrentLocation: json['assetCurrentLocation'] ?? '',
      assetCurrentDepartment: json['assetCurrentDepartment'] ?? '',
      assetCurrentCondition: json['assetCurrentCondition'] ?? '',
      assetCurrentPerson: json['assetCurrentPerson'],
      mismatchDetails: (json['mismatchDetails'] as List<dynamic>?)
              ?.map((e) => MismatchDetail.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'barcode': barcode,
      'assetName': assetName,
      'createDate': createDate.toIso8601String(),
      'mainLocation': mainLocation,
      'department': department,
      'condition': condition,
      'person': person,
      'assetCurrentLocation': assetCurrentLocation,
      'assetCurrentDepartment': assetCurrentDepartment,
      'assetCurrentCondition': assetCurrentCondition,
      'assetCurrentPerson': assetCurrentPerson,
      'mismatchDetails': mismatchDetails.map((e) => e.toJson()).toList(),
    };
  }

  // Helper method to get mismatch count
  int get mismatchCount => mismatchDetails.length;

  // Helper method to check if there are critical mismatches
  bool get hasCriticalMismatches => mismatchDetails.any(
        (detail) => detail.severity == 'CRITICAL',
      );
}

class MismatchDetail {
  final String field;
  final String? expected;
  final String? actual;
  final String type;
  final String severity;

  MismatchDetail({
    required this.field,
    this.expected,
    this.actual,
    required this.type,
    required this.severity,
  });

  factory MismatchDetail.fromJson(Map<String, dynamic> json) {
    return MismatchDetail(
      field: json['field'] ?? '',
      expected: json['expected'],
      actual: json['actual'],
      type: json['type'] ?? '',
      severity: json['severity'] ?? 'WARNING',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'field': field,
      'expected': expected,
      'actual': actual,
      'type': type,
      'severity': severity,
    };
  }

  // Helper method to get color based on severity
  Color getSeverityColor() {
    switch (severity.toUpperCase()) {
      case 'CRITICAL':
        return Colors.red;
      case 'WARNING':
        return Colors.orange;
      case 'INFO':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  // Helper method to get icon based on mismatch type
  IconData getMismatchIcon() {
    switch (type) {
      case 'CONDITION_MISMATCH':
        return Icons.warning_amber_rounded;
      case 'PERSON_MISMATCH':
        return Icons.person_off;
      case 'ROOM_MISMATCH':
        return Icons.room_outlined;
      case 'LOCATION_MISMATCH':
        return Icons.location_off;
      default:
        return Icons.error_outline;
    }
  }
}