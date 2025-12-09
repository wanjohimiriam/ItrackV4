// Create a new file: auditrequestmodel.dart or update existing one
class AuditAssetRequestModel {
  final String barcode;
  final String? mainLocation;
  final String? newLocation;
  final String? subLocation;
  final String? department;
  final String userId;
  final String? conditionId;
  final String? roomDesc;
  final String? moreText;
  final String? person;
  final String? pfNo;
  final String? subLocationId;
  final String? subSubLocationId;
  final String? condition;
  final String? assetName;
  final String? tenantId;
  final List<String>? conditionChangeApprovers;
  final String? conditionChangeNotes;

  AuditAssetRequestModel({
    required this.barcode,
    this.mainLocation,
    this.newLocation,
    this.subLocation,
    this.department,
    required this.userId,
    this.conditionId,
    this.roomDesc,
    this.moreText,
    this.person,
    this.pfNo,
    this.subLocationId,
    this.subSubLocationId,
    this.condition,
    this.assetName,
    this.tenantId,
    this.conditionChangeApprovers,
    this.conditionChangeNotes,
  });

  Map<String, dynamic> toJson() {
    return {
      'barcode': barcode,
      'mainLocation': mainLocation,
      'newLocation': newLocation,
      'subLocation': subLocation,
      'department': department,
      'userId': userId,
      'conditionId': conditionId,
      'roomDesc': roomDesc,
      'moreText': moreText,
      'person': person,
      'pfNo': pfNo,
      'subLocationId': subLocationId,
      'subSubLocationId': subSubLocationId,
      'condition': condition,
      'assetName': assetName,
      'tenantId': tenantId ?? '',
      'conditionChangeApprovers': conditionChangeApprovers,
      'conditionChangeNotes': conditionChangeNotes,
    };
  }
}