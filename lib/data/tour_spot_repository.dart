import '../models/graph_node.dart';
import '../models/geo_coordinate.dart';
import 'tour_spot_model.dart';

/// Abstract base class for tour spot data repositories.
///
/// This abstraction enables the Repository Pattern, allowing seamless switching
/// between mock data (for demo/stability) and live Firebase data (for production).
///
/// ## Usage Example
/// ```dart
/// // In development/demo mode:
/// final repository = MockTourSpotRepository();
///
/// // In production (after Firebase implementation):
/// final repository = FirebaseTourSpotRepository();
///
/// // Both can be used interchangeably:
/// final spots = await repository.getAllSpots();
/// final graph = await repository.getGraphForPathfinding();
/// ```
///
/// ## Pattern Benefits for Thesis Defense
/// - **Separation of Concerns**: Data access logic is abstracted
/// - **Testability**: Easy to mock for unit testing
/// **Future-Proof**: Swap implementations without changing service layer
/// - **Scalability**: Add caching, offline support, or API versioning
abstract class TourSpotRepository {
  /// Retrieves all available tourist spots.
  ///
  /// Returns a list of all [TourSpot] instances in the database.
  /// In mock implementation, this returns hardcoded Cebu City spots.
  Future<List<TourSpot>> getAllSpots();

  /// Retrieves a specific tourist spot by ID.
  ///
  /// [spotId] The unique identifier of the tour spot.
  ///
  /// Returns the [TourSpot] if found, or null if no spot exists with that ID.
  Future<TourSpot?> getSpotById(String spotId);

  /// Retrieves tour spots filtered by category.
  ///
  /// [category] The [TourSpotCategory] to filter by.
  ///
  /// Returns a list of [TourSpot] instances matching the category.
  Future<List<TourSpot>> getSpotsByCategory(TourSpotCategory category);

  /// Retrieves tour spots within a certain radius of a coordinate.
  ///
  /// [center] The central coordinate to measure distance from.
  /// [radiusKm] The maximum distance in kilometers.
  ///
  /// Returns a list of [TourSpot] instances within the specified radius.
  Future<List<TourSpot>> getSpotsNearCoordinate(
    GeoCoordinate center,
    double radiusKm,
  );

  /// Builds a graph of interconnected nodes for pathfinding.
  ///
  /// This method converts tour spots into [GraphNode] instances and
  /// establishes connections between nearby spots based on distance.
  ///
  /// [maxConnectionDistanceKm] Maximum distance between connected spots.
  ///   Spots closer than this threshold will have bidirectional edges.
  ///
  /// Returns a [Map] of node IDs to [GraphNode] instances ready for A* algorithm.
  Future<Map<String, GraphNode>> getGraphForPathfinding({
    double maxConnectionDistanceKm = 10.0,
  });

  /// Searches for tour spots by name or description.
  ///
  /// [query] The search query string (case-insensitive).
  ///
  /// Returns a list of [TourSpot] instances matching the query.
  Future<List<TourSpot>> searchSpots(String query);

  /// Gets the total count of available tour spots.
  Future<int> getSpotCount();
}
