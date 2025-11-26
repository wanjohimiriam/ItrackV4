class Location {
  String? id;
  String? name;
  String? code;
  String? isActive;
  String? tenantId;
  String? assets;
  String? subLocations;

  Location({
    this.id,
   this.name,
    this.code,
    this.isActive,
    this.tenantId,
    this.assets,
    this.subLocations,  
  });

  factory Location.fromJson(Map<String, dynamic> json) {
    return Location(
      id: json['id']?.toString(),
      name: json['name'],
      code: json['code'],
      isActive: json['isActive']?.toString(),
      tenantId: json['tenantId']?.toString(),    
      assets: json['assets']?.toString(),
      subLocations: json['subLocations']?.toString(),

    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'code': code,     
      'isActive': isActive,
      'tenantId': tenantId,
      'assets': assets,
      'subLocations': subLocations,
    };
  }
}

class LocationResponse {
  final List<Location> data;
  final int pageNumber;
  final int pageSize;
  final int totalRecords;
  final bool hasPreviousPage;
  final bool hasNextPage;

  LocationResponse({
    required this.data,
    required this.pageNumber,
    required this.pageSize,
    required this.totalRecords,
    required this.hasPreviousPage,
    required this.hasNextPage,
  });

  factory LocationResponse.fromJson(Map<String, dynamic> json) {
    return LocationResponse(
      data: (json['data'] as List<dynamic>)
          .map((item) => Location.fromJson(item as Map<String, dynamic>))
          .toList(),
      pageNumber: json['pageNumber'] as int? ?? 1,
      pageSize: json['pageSize'] as int? ?? 0,
      totalRecords: json['totalRecords'] as int? ?? 0,
      hasPreviousPage: json['hasPreviousPage'] as bool? ?? false,
      hasNextPage: json['hasNextPage'] as bool? ?? false,
    );
  }
}