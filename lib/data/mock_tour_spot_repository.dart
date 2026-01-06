import 'dart:async';
import '../models/graph_node.dart';
import '../models/geo_coordinate.dart';
import 'tour_spot_model.dart';
import 'tour_spot_repository.dart';
import 'cebu_graph_data.dart';

/// Mock implementation of [TourSpotRepository] using hardcoded Cebu City data.
///
/// This implementation is designed for:
/// - **Demo stability**: No network calls or database dependencies
/// - **Fast iteration**: Instant data retrieval
/// **Thesis defense**: Predictable, reproducible results
///
/// In production, replace this with [FirebaseTourSpotRepository] which
/// implements the same interface but queries Firestore instead.
///
/// ## Architecture Note
/// Using an abstract base class allows seamless swapping between
/// mock and real data sources without modifying service logic.
///
/// See [TourSpotRepository] for the interface contract.
class MockTourSpotRepository implements TourSpotRepository {
  /// Internal cache of spots for fast retrieval
  final List<TourSpot> _spots;

  /// Internal cache of pre-built graph nodes
  Map<String, GraphNode>? _graphCache;

  /// Creates a new [MockTourSpotRepository] with default Cebu data.
  MockTourSpotRepository() : _spots = List.unmodifiable(CebuGraphData.allSpots);

  /// Creates a [MockTourSpotRepository] with custom spot data.
  ///
  /// Useful for testing with specific scenarios.
  MockTourSpotRepository.withCustomSpots(List<TourSpot> spots)
      : _spots = List.unmodifiable(spots);

  @override
  Future<List<TourSpot>> getAllSpots() async {
    // Simulate async operation (in case we add caching/API later)
    await Future<void>.delayed(const Duration(milliseconds: 10));
    return _spots;
  }

  @override
  Future<TourSpot?> getSpotById(String spotId) async {
    await Future<void>.delayed(const Duration(milliseconds: 5));
    try {
      return _spots.firstWhere((spot) => spot.id == spotId);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<List<TourSpot>> getSpotsByCategory(TourSpotCategory category) async {
    await Future<void>.delayed(const Duration(milliseconds: 5));
    return _spots.where((spot) => spot.category == category).toList();
  }

  @override
  Future<List<TourSpot>> getSpotsNearCoordinate(
    GeoCoordinate center,
    double radiusKm,
  ) async {
    await Future<void>.delayed(const Duration(milliseconds: 5));
    return CebuGraphData.getSpotsNearCoordinate(center, radiusKm);
  }

  @override
  Future<Map<String, GraphNode>> getGraphForPathfinding({
    double maxConnectionDistanceKm = 10.0,
  }) async {
    // Use cached graph if available and distance threshold matches
    // For now, always return the pre-built Cebu graph
    await Future<void>.delayed(const Duration(milliseconds: 10));
    return CebuGraphData.getGraphNodes();
  }

  @override
  Future<List<TourSpot>> searchSpots(String query) async {
    await Future<void>.delayed(const Duration(milliseconds: 5));
    return CebuGraphData.searchSpots(query);
  }

  @override
  Future<int> getSpotCount() async {
    await Future<void>.delayed(const Duration(milliseconds: 5));
    return _spots.length;
  }

  /// Gets the pre-computed graph nodes synchronously.
  ///
  /// Use this method when you need immediate access to the graph
  /// without awaiting async operations.
  Map<String, GraphNode> getGraphNodesSync() {
    return CebuGraphData.getGraphNodes();
  }
}
