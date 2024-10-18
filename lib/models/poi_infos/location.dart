class Location {
  final String? address;
  final String? postalCode;
  final String? city;
  final double? latitude;
  final double? longitude;

  Location({
    this.address,
    this.postalCode,
    this.city,
    this.latitude,
    this.longitude,
  });

  // Convertit un JSON en modèle Location
  factory Location.fromJson(Map<String, dynamic> json) {
    return Location(
      address: json['address'] as String?,
      postalCode: json['postalCode'] as String?,
      city: json['city'] as String?,
      latitude: json['latitude'] != null ? (json['latitude'] as num).toDouble() : null,
      longitude: json['longitude'] != null ? (json['longitude'] as num).toDouble() : null,
    );
  }

  // Convertit un modèle Location en JSON
  Map<String, dynamic> toJson() {
    return {
      'address': address,
      'postalCode': postalCode,
      'city': city,
      'latitude': latitude,
      'longitude': longitude,
    };
  }
}
