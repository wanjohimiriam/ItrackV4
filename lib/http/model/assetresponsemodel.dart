class AssetResponseModel {
  String? id;
  String? assetDescription;
  String? serialNumber;
  String? barcode;
  String? assetCode;
  double? purchasePrice;
  String? purchaseDate;
  String? assetTypeId;
  String? conditionId;
  String? costCentreId;
  String? departmentId;
  String? locationId;
  String? roomId;
  String? subLocationId;
  String? plantId;
  String? personId;
  String? userId;
  
  // Display names from API
  String? assetTypeName;
  String? conditionName;
  String? costCentreName;
  String? departmentName;
  String? locationName;
  String? roomName;
  String? subLocationName;
  String? plantName;
  String? plantCode;
  String? personName;
  String? costCenter;
  String? unit;
  String? headofDepartment; // ✅ Added this field
  
  String? tenantId;
  bool? triggerEmailNotification;
  int? status;
  String? createDate;
  String? updateDate;
  
  // Additional fields
  String? email;
  String? locationCodeName;
  String? comments;
  String? currentLocationId;

  AssetResponseModel({
    this.id,
    this.assetDescription,
    this.serialNumber,
    this.barcode,
    this.assetCode,
    this.purchasePrice,
    this.purchaseDate,
    this.assetTypeId,
    this.conditionId,
    this.costCentreId,
    this.departmentId,
    this.locationId,
    this.roomId,
    this.subLocationId,
    this.plantId,
    this.personId,
    this.userId,
    this.assetTypeName,
    this.conditionName,
    this.costCentreName,
    this.departmentName,
    this.locationName,
    this.roomName,
    this.subLocationName,
    this.plantName,
    this.plantCode,
    this.personName,
    this.costCenter,
    this.unit,
    this.headofDepartment, // ✅ Added
    this.tenantId,
    this.triggerEmailNotification,
    this.status,
    this.createDate,
    this.updateDate,
    this.email,
    this.locationCodeName,
    this.comments,
    this.currentLocationId,
  });

  factory AssetResponseModel.fromJson(Map<String, dynamic> json) {
    return AssetResponseModel(
      id: json['id'],
      assetDescription: json['assetDescription'],
      serialNumber: json['serialNumber'],
      barcode: json['barcode'],
      assetCode: json['assetCode'],
      purchasePrice: json['purchasePrice']?.toDouble(),
      purchaseDate: json['purchaseDate'],
      assetTypeId: json['assetTypeId'],
      conditionId: json['conditionId'],
      costCentreId: json['costCentreId'],
      departmentId: json['departmentId'],
      locationId: json['locationId'],
      roomId: json['roomId'],
      subLocationId: json['subLocationId'],
      plantId: json['plantId'],
      personId: json['personId'],
      userId: json['userId'],
      assetTypeName: json['assetTypeName'],
      conditionName: json['conditionName'],
      costCentreName: json['costCentreName'],
      departmentName: json['departmentName'],
      locationName: json['locationName'],
      roomName: json['roomName'],
      subLocationName: json['subLocationName'],
      plantName: json['plantName'],
      plantCode: json['plantCode'],
      personName: json['personName'],
      costCenter: json['costCenter'],
      unit: json['unit'],
      headofDepartment: json['headofDepartment'], // ✅ Added
      tenantId: json['tenantId'],
      triggerEmailNotification: json['triggerEmailNotification'],
      status: json['status'],
      createDate: json['createDate'],
      updateDate: json['updateDate'],
      email: json['email'],
      locationCodeName: json['locationCodeName'],
      comments: json['comments'],
      currentLocationId: json['currentLocationId'],
    );
  }
}