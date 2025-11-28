// Generic Config Response Model
class ConfigResponse<T> {
  final List<T> data;
  final int pageNumber;
  final int pageSize;
  final int totalRecords;
  final bool hasPreviousPage;
  final bool hasNextPage;

  ConfigResponse({
    required this.data,
    required this.pageNumber,
    required this.pageSize,
    required this.totalRecords,
    required this.hasPreviousPage,
    required this.hasNextPage,
  });

  factory ConfigResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJsonT,
  ) {
    return ConfigResponse<T>(
      data: (json['data'] as List).map((item) => fromJsonT(item)).toList(),
      pageNumber: json['pageNumber'] ?? 1,
      pageSize: json['pageSize'] ?? 0,
      totalRecords: json['totalRecords'] ?? 0,
      hasPreviousPage: json['hasPreviousPage'] ?? false,
      hasNextPage: json['hasNextPage'] ?? false,
    );
  }
}

// Plant Model
class PlantModel {
  final String id;
  final String name;
  final String code;
  final bool isActive;
  final String tenantId;

  PlantModel({
    required this.id,
    required this.name,
    required this.code,
    required this.isActive,
    required this.tenantId,
  });

  factory PlantModel.fromJson(Map<String, dynamic> json) {
    return PlantModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      code: json['code'] ?? '',
      isActive: json['isActive'] ?? true,
      tenantId: json['tenantId'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'code': code,
      'isActive': isActive,
      'tenantId': tenantId,
    };
  }
}

// Department Model
class DepartmentModel {
  final String id;
  final String name;
  final String code;
  final bool isActive;
  final String tenantId;

  DepartmentModel({
    required this.id,
    required this.name,
    required this.code,
    required this.isActive,
    required this.tenantId,
  });

  factory DepartmentModel.fromJson(Map<String, dynamic> json) {
    return DepartmentModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      code: json['code'] ?? '',
      isActive: json['isActive'] ?? true,
      tenantId: json['tenantId'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'code': code,
      'isActive': isActive,
      'tenantId': tenantId,
    };
  }
}

// Cost Centre Model
class CostCentreModel {
  final String id;
  final String name;
  final String code;
  final bool isActive;
  final String tenantId;

  CostCentreModel({
    required this.id,
    required this.name,
    required this.code,
    required this.isActive,
    required this.tenantId,
  });

  factory CostCentreModel.fromJson(Map<String, dynamic> json) {
    return CostCentreModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      code: json['code'] ?? '',
      isActive: json['isActive'] ?? true,
      tenantId: json['tenantId'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'code': code,
      'isActive': isActive,
      'tenantId': tenantId,
    };
  }
}

// Asset Type Model
class AssetTypeModel {
  final String id;
  final String name;
  final String code;
  final bool isActive;
  final String tenantId;

  AssetTypeModel({
    required this.id,
    required this.name,
    required this.code,
    required this.isActive,
    required this.tenantId,
  });

  factory AssetTypeModel.fromJson(Map<String, dynamic> json) {
    return AssetTypeModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      code: json['code'] ?? '',
      isActive: json['isActive'] ?? true,
      tenantId: json['tenantId'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'code': code,
      'isActive': isActive,
      'tenantId': tenantId,
    };
  }
}

// Condition Model
class ConditionModel {
  final String id;
  final String name;
  final String code;
  final bool isActive;
  final bool triggersInsuranceClaim;
  final String tenantId;

  ConditionModel({
    required this.id,
    required this.name,
    required this.code,
    required this.isActive,
    required this.triggersInsuranceClaim,
    required this.tenantId,
  });

  factory ConditionModel.fromJson(Map<String, dynamic> json) {
    return ConditionModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      code: json['code'] ?? '',
      isActive: json['isActive'] ?? true,
      triggersInsuranceClaim: json['triggersInsuranceClaim'] ?? false,
      tenantId: json['tenantId'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'code': code,
      'isActive': isActive,
      'triggersInsuranceClaim': triggersInsuranceClaim,
      'tenantId': tenantId,
    };
  }
}

class PersonModel {
  final String id;
  final String firstName;
  final String lastName;  // or surname
  final String middleName;
  final String displayName;
  final String fullName;
  final String staffEmail;
  final String personCode;
  final String unit;
  final String costCenter;
  final String? departmentId;
  final bool isActive;
  final String tenantId;

  PersonModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.middleName,
    required this.displayName,
    required this.fullName,
    required this.staffEmail,
    required this.personCode,
    required this.unit,
    required this.costCenter,
    this.departmentId,
    required this.isActive,
    required this.tenantId,
  });

  factory PersonModel.fromJson(Map<String, dynamic> json) {
    return PersonModel(
      id: json['id'] ?? '',
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',  // ✅ Map to lastName
      middleName: json['middleName'] ?? '',
      displayName: json['displayName'] ?? '',
      fullName: json['fullName'] ?? '',
      staffEmail: json['staffEmail'] ?? json['email'] ?? '',
      personCode: json['personCode'] ?? '',
      unit: json['unit'] ?? '',
      costCenter: json['costCenter'] ?? '',
      departmentId: json['departmentId'],
      isActive: json['isActive'] ?? false,
      tenantId: json['tenantId'] ?? '',
    );
  }
}