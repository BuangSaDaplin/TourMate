import '../models/geo_coordinate.dart';
import '../models/graph_node.dart';
import 'tour_spot_model.dart';

/// Static data provider for Cebu City tourist spots.
///
/// This class contains hardcoded data for demonstration purposes.
/// In a production app, this would be replaced with Firebase Firestore queries.
///
/// ## Data Source Notes
/// - Coordinates are based on actual locations in Cebu City and nearby areas
/// - Categories follow the TourSpotClassification taxonomy
/// - Distances are calculated using Haversine formula for accuracy
///
/// ## Available Spots
/// - Basilica del Santo Niño (Religious)
/// - Magellan's Cross (Historical)
/// - Fort San Pedro (Historical)
/// - Colon Street (Historical)
/// - Taoist Temple (Religious)
/// - Sirao Flower Garden (Natural)
/// - Tops Lookout (Viewpoint)
/// - Temple of Leah (Religious)
/// - Heritage of Cebu Monument (Historical)
/// - Cebu Metropolitan Cathedral (Religious)
class CebuGraphData {
  /// Private constructor to prevent instantiation
  CebuGraphData._();

  /// Complete list of Cebu City tourist spots with accurate coordinates.
  ///
  /// These spots are hand-curated and represent major attractions
  /// suitable for tour navigation demonstrations.
  static const List<TourSpot> allSpots = [
    // --- CEBU CITY DOWNTOWN ---
    TourSpot(
      id: 'basilica_del_nino',
      name: 'Basilica del Santo Niño',
      description:
          'Oldest Roman Catholic church in the Philippines, home to the revered image of the Santo Niño de Cebu.',
      coordinate: GeoCoordinate(latitude: 10.2931, longitude: 123.8858),
      category: TourSpotCategory.religious,
      imageUrl: 'assets/images/basilica.jpg',
      estimatedDurationMinutes: 45,
      isOpen: true,
      operatingHours: '05:00-21:00',
      entranceFee: 0,
    ),
    TourSpot(
      id: 'magellans_cross',
      name: "Magellan's Cross",
      description:
          'A Christian cross planted by Ferdinand Magellan upon arriving in Cebu in 1521.',
      coordinate: GeoCoordinate(latitude: 10.2970, longitude: 123.8859),
      category: TourSpotCategory.historical,
      imageUrl: 'assets/images/magellans_cross.jpg',
      estimatedDurationMinutes: 15,
      isOpen: true,
      operatingHours: '07:00-19:00',
      entranceFee: 0,
    ),
    TourSpot(
      id: 'fort_san_pedro',
      name: 'Fort San Pedro',
      description:
          'Triangular bastion fort built by Spanish explorers in 1565, now a museum showcasing Cebu\'s colonial history.',
      coordinate: GeoCoordinate(latitude: 10.2945, longitude: 123.8872),
      category: TourSpotCategory.historical,
      imageUrl: 'assets/images/fort_san_pedro.jpg',
      estimatedDurationMinutes: 60,
      isOpen: true,
      operatingHours: '08:00-17:00',
      entranceFee: 30,
    ),
    TourSpot(
      id: 'colon_street',
      name: 'Colon Street',
      description:
          'The oldest street in the Philippines, lined with historical buildings, markets, and local shops.',
      coordinate: GeoCoordinate(latitude: 10.2929, longitude: 123.8845),
      category: TourSpotCategory.historical,
      imageUrl: 'assets/images/colon_street.jpg',
      estimatedDurationMinutes: 30,
      isOpen: true,
      operatingHours: '00:00-24:00',
      entranceFee: 0,
    ),
    TourSpot(
      id: 'cebu_metropolitan_cathedral',
      name: 'Cebu Metropolitan Cathedral',
      description:
          'The seat of the Archdiocese of Cebu, featuring beautiful Gothic architecture.',
      coordinate: GeoCoordinate(latitude: 10.2949, longitude: 123.8858),
      category: TourSpotCategory.religious,
      imageUrl: 'assets/images/cathedral.jpg',
      estimatedDurationMinutes: 30,
      isOpen: true,
      operatingHours: '06:00-18:00',
      entranceFee: 0,
    ),
    TourSpot(
      id: 'heritage_monument',
      name: 'Heritage of Cebu Monument',
      description:
          'A tableau of sculptures depicting significant events in Cebuano history and culture.',
      coordinate: GeoCoordinate(latitude: 10.2928, longitude: 123.8852),
      category: TourSpotCategory.historical,
      imageUrl: 'assets/images/heritage_monument.jpg',
      estimatedDurationMinutes: 20,
      isOpen: true,
      operatingHours: '09:00-18:00',
      entranceFee: 0,
    ),

    // --- LA HILLS / MOUNTAIN AREA ---
    TourSpot(
      id: 'taoist_temple',
      name: 'Cebu Taoist Temple',
      description:
          'A Taoist temple built in 1972, featuring elaborate architecture and serene gardens.',
      coordinate: GeoCoordinate(latitude: 10.3366, longitude: 123.9108),
      category: TourSpotCategory.religious,
      imageUrl: 'assets/images/taoist_temple.jpg',
      estimatedDurationMinutes: 45,
      isOpen: true,
      operatingHours: '08:00-17:00',
      entranceFee: 0,
    ),
    TourSpot(
      id: 'sirao_flower_garden',
      name: 'Sirao Flower Garden',
      description:
          'A scenic flower farm known as the "Little Amsterdam of Cebu" with vibrant celosia flowers.',
      coordinate: GeoCoordinate(latitude: 10.3439, longitude: 123.9165),
      category: TourSpotCategory.natural,
      imageUrl: 'assets/images/sirao_garden.jpg',
      estimatedDurationMinutes: 45,
      isOpen: true,
      operatingHours: '06:00-18:00',
      entranceFee: 50,
    ),
    TourSpot(
      id: 'temple_of_leah',
      name: 'Temple of Leah',
      description:
          'A Roman-style temple built as a tribute to love, featuring grand architecture and panoramic views.',
      coordinate: GeoCoordinate(latitude: 10.3401, longitude: 123.9145),
      category: TourSpotCategory.religious,
      imageUrl: 'assets/images/temple_of_leah.jpg',
      estimatedDurationMinutes: 45,
      isOpen: true,
      operatingHours: '09:00-18:00',
      entranceFee: 50,
    ),
    TourSpot(
      id: 'tops_lookout',
      name: 'Tops Lookout',
      description:
          'A hilltop viewpoint offering breathtaking 360-degree views of Cebu City and the surrounding mountains.',
      coordinate: GeoCoordinate(latitude: 10.3445, longitude: 123.9189),
      category: TourSpotCategory.viewpoint,
      imageUrl: 'assets/images/tops_lookout.jpg',
      estimatedDurationMinutes: 30,
      isOpen: true,
      operatingHours: '24:00',
      entranceFee: 30,
    ),
    TourSpot(
      id: 'mountain_peak_viewpoint',
      name: 'Mountain Peak Viewpoint',
      description:
          'An elevated viewpoint in the La Hills area, popular for sunrise and sunset views.',
      coordinate: GeoCoordinate(latitude: 10.3389, longitude: 123.9123),
      category: TourSpotCategory.viewpoint,
      imageUrl: 'assets/images/mountain_peak.jpg',
      estimatedDurationMinutes: 25,
      isOpen: true,
      operatingHours: '05:00-19:00',
      entranceFee: 0,
    ),

    // --- SOUTH CEBU BEACHES ---
    TourSpot(
      id: 'badian_bridge',
      name: 'Badian Bridge',
      description:
          'Iconic bridge along the highway offering views of the turquoise waters of Badian.',
      coordinate: GeoCoordinate(latitude: 9.8650, longitude: 123.3950),
      category: TourSpotCategory.viewpoint,
      imageUrl: 'assets/images/badian_bridge.jpg',
      estimatedDurationMinutes: 15,
      isOpen: true,
      operatingHours: '00:00-24:00',
      entranceFee: 0,
    ),
    TourSpot(
      id: 'oslob_whale_shark',
      name: 'Oslob Whale Shark Watching',
      description:
          'Experience swimming with gentle whale sharks in their natural habitat.',
      coordinate: GeoCoordinate(latitude: 9.4415, longitude: 123.2435),
      category: TourSpotCategory.natural,
      imageUrl: 'assets/images/whale_shark.jpg',
      estimatedDurationMinutes: 120,
      isOpen: true,
      operatingHours: '06:00-11:00',
      entranceFee: 500,
    ),
    TourSpot(
      id: 'sumilon_bluewater',
      name: 'Sumilon Bluewater Beach',
      description:
          'Pristine white sand beach with crystal clear waters on Sumilon Island.',
      coordinate: GeoCoordinate(latitude: 9.4032, longitude: 123.2265),
      category: TourSpotCategory.beach,
      imageUrl: 'assets/images/sumilon.jpg',
      estimatedDurationMinutes: 180,
      isOpen: true,
      operatingHours: '06:00-18:00',
      entranceFee: 150,
    ),
  ];

  /// Pre-calculated graph nodes with neighbor connections.
  ///
  /// This map is optimized for pathfinding demonstrations, with
  /// connections established based on realistic travel distances.
  ///
  /// Connection Strategy:
  /// - Downtown spots are interconnected (walking/short drive distances)
  /// - La Hills spots are clustered together
  /// - South Cebu spots are connected via highway distances
  static Map<String, GraphNode> getGraphNodes() {
    final graph = <String, GraphNode>{};

    // Create nodes for each spot
    for (final spot in allSpots) {
      graph[spot.id] = GraphNode(
        id: spot.id,
        coordinate: spot.coordinate,
      );
    }

    // --- DOWNTOWN CEBU CONNECTIONS ---
    // All downtown spots are within walking distance (approx 0.5-2km apart)
    _connectBidirectional(graph, 'basilica_del_nino', 'magellans_cross', 0.5);
    _connectBidirectional(graph, 'basilica_del_nino', 'fort_san_pedro', 0.8);
    _connectBidirectional(graph, 'basilica_del_nino', 'colon_street', 0.4);
    _connectBidirectional(graph, 'basilica_del_nino', 'heritage_monument', 0.4);
    _connectBidirectional(
        graph, 'basilica_del_nino', 'cebu_metropolitan_cathedral', 0.3);
    _connectBidirectional(graph, 'magellans_cross', 'fort_san_pedro', 0.4);
    _connectBidirectional(graph, 'magellans_cross', 'colon_street', 0.4);
    _connectBidirectional(graph, 'fort_san_pedro', 'colon_street', 0.5);
    _connectBidirectional(graph, 'colon_street', 'heritage_monument', 0.2);
    _connectBidirectional(
        graph, 'heritage_monument', 'cebu_metropolitan_cathedral', 0.3);

    // --- LA HILLS CONNECTIONS ---
    // Close proximity (1-3km range)
    _connectBidirectional(graph, 'taoist_temple', 'sirao_flower_garden', 2.5);
    _connectBidirectional(graph, 'taoist_temple', 'temple_of_leah', 1.2);
    _connectBidirectional(
        graph, 'taoist_temple', 'mountain_peak_viewpoint', 1.5);
    _connectBidirectional(graph, 'sirao_flower_garden', 'temple_of_leah', 1.5);
    _connectBidirectional(graph, 'sirao_flower_garden', 'tops_lookout', 1.8);
    _connectBidirectional(graph, 'temple_of_leah', 'tops_lookout', 1.2);
    _connectBidirectional(
        graph, 'temple_of_leah', 'mountain_peak_viewpoint', 0.8);
    _connectBidirectional(
        graph, 'mountain_peak_viewpoint', 'tops_lookout', 1.0);

    // --- DOWNTOWN TO LA HILLS ---
    // Connection via main roads (8-12km)
    _connectBidirectional(graph, 'basilica_del_nino', 'taoist_temple', 8.5);
    _connectBidirectional(graph, 'fort_san_pedro', 'taoist_temple', 9.0);
    _connectBidirectional(
        graph, 'basilica_del_nino', 'mountain_peak_viewpoint', 10.5);

    // --- SOUTH CEBU CONNECTIONS ---
    // Highway distances between southern attractions
    _connectBidirectional(graph, 'badian_bridge', 'oslob_whale_shark', 45.0);
    _connectBidirectional(
        graph, 'oslob_whale_shark', 'sumilon_bluewater', 15.0);

    // --- CROSS-REGION CONNECTIONS ---
    // For long-distance pathfinding demonstrations
    _connectBidirectional(graph, 'basilica_del_nino', 'badian_bridge', 85.0);
    _connectBidirectional(
        graph, 'basilica_del_nino', 'oslob_whale_shark', 120.0);

    return graph;
  }

  /// Helper method to create bidirectional connections between nodes.
  static void _connectBidirectional(
    Map<String, GraphNode> graph,
    String nodeA,
    String nodeB,
    double distanceKm,
  ) {
    graph[nodeA]?.addNeighbor(nodeB, distanceKm);
    graph[nodeB]?.addNeighbor(nodeA, distanceKm);
  }

  /// Gets spots by category for filtering.
  static List<TourSpot> getSpotsByCategory(TourSpotCategory category) {
    return allSpots.where((spot) => spot.category == category).toList();
  }

  /// Gets a spot by ID.
  static TourSpot? getSpotById(String id) {
    try {
      return allSpots.firstWhere((spot) => spot.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Searches spots by name or description.
  static List<TourSpot> searchSpots(String query) {
    final lowercaseQuery = query.toLowerCase();
    return allSpots
        .where(
          (spot) =>
              spot.name.toLowerCase().contains(lowercaseQuery) ||
              spot.description.toLowerCase().contains(lowercaseQuery),
        )
        .toList();
  }

  /// Gets spots near a coordinate within specified radius.
  static List<TourSpot> getSpotsNearCoordinate(
    GeoCoordinate center,
    double radiusKm,
  ) {
    return allSpots
        .where((spot) => spot.coordinate.distanceTo(center) <= radiusKm)
        .toList();
  }
}
