import '../models/geo_coordinate.dart';

/// Represents a tourist spot in Cebu City.
///
/// This model contains all information about a tourist attraction including
/// its geographic location, metadata, and connectivity to other spots.
///
/// Example usage:
/// ```dart
/// final spot = TourSpot(
///   id: 'basilica_del_nino',
///   name: 'Basilica del Santo Niño',
///   coordinate: GeoCoordinate(10.2931, 123.8858),
///   category: TourSpotCategory.religious,
/// );
/// ```
class TourSpot {
  /// Unique identifier for this tourist spot
  final String id;

  /// Display name of the tourist spot
  final String name;

  /// Brief description of the spot
  final String description;

  /// Geographic coordinates of the spot
  final GeoCoordinate coordinate;

  /// Category classification for filtering
  final TourSpotCategory category;

  /// URL to the spot's image (can be local asset or network URL)
  final String? imageUrl;

  /// Estimated visit duration in minutes
  final int estimatedDurationMinutes;

  /// Whether the spot is currently open for visitors
  final bool isOpen;

  /// Operating hours in 24-hour format (e.g., '08:00-17:00')
  final String? operatingHours;

  /// Entrance fee in PHP (null if free)
  final double? entranceFee;

  /// Creates a new [TourSpot] instance.
  const TourSpot({
    required this.id,
    required this.name,
    required this.description,
    required this.coordinate,
    required this.category,
    this.imageUrl,
    this.estimatedDurationMinutes = 60,
    this.isOpen = true,
    this.operatingHours,
    this.entranceFee,
  });

  /// Creates a [TourSpot] from a Firestore document map.
  factory TourSpot.fromMap(Map<String, dynamic> map) {
    return TourSpot(
      id: map['id'] as String,
      name: map['name'] as String,
      description: map['description'] as String,
      coordinate: GeoCoordinate.fromMap(
        map['coordinate'] as Map<String, dynamic>,
      ),
      category: TourSpotCategory.values.firstWhere(
        (e) => e.name == map['category'],
        orElse: () => TourSpotCategory.other,
      ),
      imageUrl: map['imageUrl'] as String?,
      estimatedDurationMinutes: map['estimatedDurationMinutes'] as int? ?? 60,
      isOpen: map['isOpen'] as bool? ?? true,
      operatingHours: map['operatingHours'] as String?,
      entranceFee: map['entranceFee'] as double?,
    );
  }

  /// Converts this [TourSpot] to a Firestore-compatible map.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'coordinate': coordinate.toMap(),
      'category': category.name,
      'imageUrl': imageUrl,
      'estimatedDurationMinutes': estimatedDurationMinutes,
      'isOpen': isOpen,
      'operatingHours': operatingHours,
      'entranceFee': entranceFee,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TourSpot && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'TourSpot(id: $id, name: $name, coordinate: $coordinate)';
  }
}

/// Categories for classifying tourist spots in Cebu City.
enum TourSpotCategory {
  /// Religious and historical churches, temples
  religious,

  /// Natural attractions like mountains, waterfalls, beaches
  natural,

  /// Museums, historical buildings, monuments
  historical,

  /// Modern entertainment venues, malls, theme parks
  entertainment,

  /// Beaches and coastal areas
  beach,

  /// Mountains and trekking destinations
  mountain,

  /// Local markets, food districts, restaurants
  food,

  /// Viewpoints and scenic spots
  viewpoint,

  /// Other attractions
  other,
}
