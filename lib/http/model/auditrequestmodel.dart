class AuditAssetRequestModel {
  final String barcode;
  final String? mainLocation;
  final String? newLocation;
  final String? subLocation;
  final String? department;
  final String? userId;
  final String? conditionId;
  final String? roomDesc;
  final String? moreText;
  final String? person;
  final String? pfNo;
  final String? subLocationId;
  final String? subSubLocationId;
  final String? condition;
  final String? assetName;
  final String tenantId;

  AuditAssetRequestModel({
    required this.barcode,
    this.mainLocation,
    this.newLocation,
    this.subLocation,
    this.department,
    this.userId,
    this.conditionId,
    this.roomDesc,
    this.moreText,
    this.person,
    this.pfNo,
    this.subLocationId,
    this.subSubLocationId,
    this.condition,
    this.assetName,
    required this.tenantId,
  });

  Map<String, dynamic> toJson() {
    return {
      'barcode': barcode,
      if (mainLocation != null) 'mainLocation': mainLocation,
      if (newLocation != null) 'newLocation': newLocation,
      if (subLocation != null) 'subLocation': subLocation,
      if (department != null) 'department': department,
      if (userId != null) 'userId': userId,
      if (conditionId != null) 'conditionId': conditionId,
      if (roomDesc != null) 'roomDesc': roomDesc,
      if (moreText != null) 'moreText': moreText,
      if (person != null) 'person': person,
      if (pfNo != null) 'pfNo': pfNo,
      if (subLocationId != null) 'subLocationId': subLocationId,
      if (subSubLocationId != null) 'subSubLocationId': subSubLocationId,
      if (condition != null) 'condition': condition,
      if (assetName != null) 'assetName': assetName,
      'tenantId': tenantId,
    };
  }
}