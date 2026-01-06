import 'dart:math' as math;

/// Represents a geographic coordinate with latitude and longitude.
///
/// This class provides essential geographic calculations including the Haversine
/// formula for calculating great-circle distances between two points on Earth's surface.
///
/// Example usage:
/// ```dart
/// final manila = GeoCoordinate(14.5995, 120.9842);
/// final cebu = GeoCoordinate(10.3157, 123.8854);
/// final distance = manila.distanceTo(cebu); // Returns distance in kilometers
/// ```
class GeoCoordinate {
  /// Latitude coordinate in degrees (-90 to 90)
  final double latitude;

  /// Longitude coordinate in degrees (-180 to 180)
  final double longitude;

  /// Earth's radius in kilometers (default: 6371 km)
  static const double earthRadiusKm = 6371.0;

  /// Creates a new [GeoCoordinate] instance.
  ///
  /// [latitude] must be between -90 and 90 degrees.
  /// [longitude] must be between -180 and 180 degrees.
  const GeoCoordinate({required this.latitude, required this.longitude});

  /// Creates a [GeoCoordinate] from a map (e.g., Firestore document).
  ///
  /// Expects keys 'latitude' and 'longitude' with double values.
  factory GeoCoordinate.fromMap(Map<String, dynamic> map) {
    return GeoCoordinate(
      latitude: (map['latitude'] as num).toDouble(),
      longitude: (map['longitude'] as num).toDouble(),
    );
  }

  /// Converts this coordinate to a Map for storage.
  Map<String, dynamic> toMap() {
    return {'latitude': latitude, 'longitude': longitude};
  }

  /// Calculates the Haversine distance to another coordinate.
  ///
  /// The Haversine formula provides great-circle distance between two points
  /// on a sphere, which is accurate for geographic coordinates on Earth.
  ///
  /// Returns the distance in kilometers.
  ///
  /// [other] The target coordinate to measure distance to.
  double distanceTo(GeoCoordinate other) {
    return _calculateHaversineDistance(this, other);
  }

  /// Calculates the Haversine distance between two coordinates.
  ///
  /// This is the core implementation of the Haversine formula.
  /// Uses the haversine formula to calculate great-circle distance:
  /// a = sin²(Δφ/2) + cos(φ₁)·cos(φ₂)·sin²(Δλ/2)
  /// c = 2·atan2(√a, √(1-a))
  /// d = R·c
  ///
  /// where φ is latitude, λ is longitude, R is Earth's radius.
  static double _calculateHaversineDistance(
    GeoCoordinate from,
    GeoCoordinate to,
  ) {
    // Convert degrees to radians
    final lat1 = _degreesToRadians(from.latitude);
    final lat2 = _degreesToRadians(to.latitude);
    final lon1 = _degreesToRadians(from.longitude);
    final lon2 = _degreesToRadians(to.longitude);

    // Differences
    final dLat = lat2 - lat1;
    final dLon = lon2 - lon1;

    // Haversine formula
    final a =
        math.pow(math.sin(dLat / 2), 2) +
        math.cos(lat1) * math.cos(lat2) * math.pow(math.sin(dLon / 2), 2);

    // Calculate c (angular distance in radians)
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    // Distance in kilometers
    return earthRadiusKm * c;
  }

  /// Converts degrees to radians.
  static double _degreesToRadians(double degrees) {
    return degrees * (math.pi / 180.0);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GeoCoordinate &&
        other.latitude == latitude &&
        other.longitude == longitude;
  }

  @override
  int get hashCode => Object.hash(latitude, longitude);

  @override
  String toString() {
    return 'GeoCoordinate(latitude: $latitude, longitude: $longitude)';
  }
}
