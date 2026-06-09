class EcoPlace {
  final String id;
  final String placeName;
  final String placeType;
  final String address;
  final double lat;
  final double lng;
  final String reason;

  EcoPlace({
    required this.id,
    required this.placeName,
    required this.placeType,
    required this.address,
    required this.lat,
    required this.lng,
    required this.reason,
  });

  factory EcoPlace.fromJson(Map<String, dynamic> json) {
    return EcoPlace(
      id: json['id']?.toString() ?? '',
      placeName: json['placeName']?.toString() ?? '',
      placeType: json['placeType']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
      reason: json['reason']?.toString() ?? '',
    );
  }
}