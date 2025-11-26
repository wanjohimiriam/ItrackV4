class LocationAuditCountModel {
  final String? locationName;
  final String? locationCode;
  final int auditCount;
  final String? locationId;
  final int? foundCount;
  final int? notFoundCount;

  LocationAuditCountModel({
    this.locationName,
    this.locationCode,
    required this.auditCount,
    this.locationId,
    this.foundCount,
    this.notFoundCount,
  });

  factory LocationAuditCountModel.fromJson(Map<String, dynamic> json) {
    return LocationAuditCountModel(
      locationName: json['locationName'],
      locationCode: json['locationCode'],
      auditCount: json['auditCount'] ?? 0,
      locationId: json['locationId'],
      foundCount: json['foundCount'],
      notFoundCount: json['notFoundCount'],
    );
  }
}

class LocationCountModel {
  final String? locationName;
  final String? locationCode;
  final int locCount;
  final String? locationId;

  LocationCountModel({
    this.locationName,
    this.locationCode,
    required this.locCount,
    this.locationId,
  });

  factory LocationCountModel.fromJson(Map<String, dynamic> json) {
    return LocationCountModel(
      locationName: json['locationName'],
      locationCode: json['locationCode'],
      locCount: json['locCount'] ?? 0,
      locationId: json['locationId'],
    );
  }
}