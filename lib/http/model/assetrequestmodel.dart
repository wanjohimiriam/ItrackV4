class AssetRequestModel {
  final String? id;
  final String assetDescription;
  final String? serialNumber;
  final String barcode;
  final String? assetCode;
  final double? purchasePrice;
  final DateTime? purchaseDate;
  final String assetTypeId;
  final String? conditionId;
  final String? costCentreId;
  final String? departmentId;
  final String locationId;
  final String? roomId;
  final String? subLocationId;
  final String? plantId;
  final String? personId;
  final String? person;
  final String? room;
  final String? comments;
  final String? entity;
  final String? unit;
  final String? costCenter;
  final String? usefulLife;
  final String? supplier;
  final String? lpoNo;
  final String? netBookVal;
  final String? accDep;
  final String? invoiceNo;
  final String? tenantId;
  final String createdBy;
  final bool triggerEmailNotification;
  final int status;
  final DateTime? createDate;
  final DateTime? updateDate;
  final List<String>? conditionChangeApprovers;
  final String? conditionChangeNotes;
  final bool? shouldCreateWorkflow;

  AssetRequestModel({
    this.id,
    required this.assetDescription,
    this.serialNumber,
    required this.barcode,
    this.assetCode,
    this.purchasePrice,
    this.purchaseDate,
    required this.assetTypeId,
    this.conditionId,
    this.costCentreId,
    this.departmentId,
    required this.locationId,
    this.roomId,
    this.subLocationId,
    this.plantId,
    this.personId,
    this.person,
    this.room,
    this.comments,
    this.entity,
    this.unit,
    this.costCenter,
    this.usefulLife,
    this.supplier,
    this.lpoNo,
    this.netBookVal,
    this.accDep,
    this.invoiceNo,
    this.tenantId,
    required this.createdBy,
    this.triggerEmailNotification = true,
    this.status = 0,
    this.createDate,
    this.updateDate,
    this.conditionChangeApprovers,
    this.conditionChangeNotes,
    this.shouldCreateWorkflow,
  });

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'assetDescription': assetDescription,
      if (serialNumber != null) 'serialNumber': serialNumber,
      'barcode': barcode,
      if (assetCode != null) 'assetCode': assetCode,
      if (purchasePrice != null) 'purchasePrice': purchasePrice,
      if (purchaseDate != null) 'purchaseDate': purchaseDate?.toIso8601String(),
      'assetTypeId': assetTypeId,
      if (conditionId != null) 'conditionId': conditionId,
      if (costCentreId != null) 'costCentreId': costCentreId,
      if (departmentId != null) 'departmentId': departmentId,
      'locationId': locationId,
      if (roomId != null) 'roomId': roomId,
      if (subLocationId != null) 'subLocationId': subLocationId,
      if (plantId != null) 'plantId': plantId,
      if (personId != null) 'personId': personId,
      if (person != null) 'person': person,
      if (room != null) 'room': room,
      if (comments != null) 'comments': comments,
      if (entity != null) 'entity': entity,
      if (unit != null) 'unit': unit,
      if (costCenter != null) 'costCenter': costCenter,
      if (usefulLife != null) 'usefulLife': usefulLife,
      if (supplier != null) 'supplier': supplier,
      if (lpoNo != null) 'lpoNo': lpoNo,
      if (netBookVal != null) 'netBookVal': netBookVal,
      if (accDep != null) 'accDep': accDep,
      if (invoiceNo != null) 'invoiceNo': invoiceNo,
      'tenantId': tenantId ?? '',
      'createdBy': createdBy,
      'triggerEmailNotification': triggerEmailNotification,
      'status': status,
      if (createDate != null) 'createDate': createDate?.toIso8601String(),
      if (updateDate != null) 'updateDate': updateDate?.toIso8601String(),
      if (conditionChangeApprovers != null) 
        'conditionChangeApprovers': conditionChangeApprovers,
      if (conditionChangeNotes != null) 'conditionChangeNotes': conditionChangeNotes,
      if (shouldCreateWorkflow != null) 'shouldCreateWorkflow': shouldCreateWorkflow,
    };
  }
}