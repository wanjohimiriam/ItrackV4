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
  
  // Add these if they exist in your other endpoints
  String? personName;
  String? email;
  String? unit;
  String? costCenter;
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
    this.email,
    this.unit,
    this.costCenter,
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
      email: json['email'],
      unit: json['unit'],
      costCenter: json['costCenter'],
      locationCodeName: json['locationCodeName'],
      comments: json['comments'],
      currentLocationId: json['currentLocationId'],
    );
  }
}