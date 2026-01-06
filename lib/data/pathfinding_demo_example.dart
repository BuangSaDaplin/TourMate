import '../models/graph_node.dart';
import '../services/pathfinding_service.dart';
import 'mock_tour_spot_repository.dart';
import 'tour_spot_model.dart';
import 'tour_spot_repository.dart';
import 'cebu_graph_data.dart';

/// Example demonstrating how to use TourMate's pathfinding system.
///
/// This file shows the complete workflow from data retrieval to pathfinding:
/// 1. Load tourist spots from the repository
/// 2. Build a graph for pathfinding
/// 3. Calculate optimal routes between destinations
///
/// Run this file directly to see a demonstration of the A* algorithm
/// finding paths between Cebu City tourist spots.
Future<void> main() async {
  print('=' * 60);
  print('TourMate Pathfinding Demo');
  print('=' * 60);

  // Step 1: Initialize the repository (uses hardcoded Cebu data)
  final repository = MockTourSpotRepository();

  // Step 2: Get all available tourist spots
  final spots = await repository.getAllSpots();
  print('\n📍 Available Tourist Spots (${spots.length}):');
  print('-' * 40);
  for (final spot in spots) {
    print('  • ${spot.name} (${spot.category.name})');
  }

  // Step 3: Get the graph for pathfinding
  final graph = await repository.getGraphForPathfinding();
  print('\n🗺️ Graph Nodes Loaded: ${graph.length}');

  // Step 4: Initialize the A* pathfinding service
  final pathfindingService = PathfindingService();

  // Step 5: Demonstrate pathfinding between popular destinations
  print('\n🚶 Pathfinding Demonstrations:');
  print('-' * 40);

  // Demo 1: Downtown heritage walk
  await _demonstratePath(
    pathfindingService,
    graph,
    'magellans_cross',
    'fort_san_pedro',
    'Heritage Walk: Magellan\'s Cross → Fort San Pedro',
  );

  // Demo 2: La Hills scenic route
  await _demonstratePath(
    pathfindingService,
    graph,
    'taoist_temple',
    'tops_lookout',
    'La Hills Scenic: Taoist Temple → Tops Lookout',
  );

  // Demo 3: Cross-region journey
  await _demonstratePath(
    pathfindingService,
    graph,
    'basilica_del_nino',
    'oslob_whale_shark',
    'Cross-Region: Basilica → Oslob Whale Sharks',
  );

  // Demo 4: Multi-stop tour (using path nodes)
  await _demonstrateMultiStopTour(
    pathfindingService,
    graph,
    ['magellans_cross', 'heritage_monument', 'basilica_del_nino'],
    'Multi-Stop Heritage Tour',
  );

  // Step 6: Show spot filtering
  print('\n📂 Spot Categories:');
  print('-' * 40);
  for (final category in TourSpotCategory.values) {
    final categorySpots = await repository.getSpotsByCategory(category);
    if (categorySpots.isNotEmpty) {
      print('  ${category.name}: ${categorySpots.length} spots');
    }
  }

  print('\n✅ Demo Complete!');
  print('=' * 60);
}

/// Demonstrates finding a path between two locations.
Future<void> _demonstratePath(
  PathfindingService service,
  Map<String, GraphNode> graph,
  String startId,
  String goalId,
  String description,
) async {
  final repository = MockTourSpotRepository();
  final startSpot = await repository.getSpotById(startId);
  final goalSpot = await repository.getSpotById(goalId);

  print('\n$description');
  print('  From: ${startSpot?.name ?? startId}');
  print('  To: ${goalSpot?.name ?? goalId}');

  final result = service.findPath(
    startNodeId: startId,
    goalNodeId: goalId,
    graph: graph,
  );

  if (result.found) {
    print('  ✅ Path Found!');
    print('     Distance: ${result.totalDistance.toStringAsFixed(2)} km');
    print('     Stops: ${result.path.length}');
    print('     Route: ${result.path.join(' → ')}');
  } else {
    print('  ❌ No path found');
  }
}

/// Demonstrates a multi-stop tour by finding paths between sequential stops.
Future<void> _demonstrateMultiStopTour(
  PathfindingService service,
  Map<String, GraphNode> graph,
  List<String> stopIds,
  String tourName,
) async {
  print('\n$tourName');
  final repository = MockTourSpotRepository();

  double totalDistance = 0;
  List<String> fullRoute = [];
  List<String> routeDescription = [];

  for (int i = 0; i < stopIds.length - 1; i++) {
    final startId = stopIds[i];
    final goalId = stopIds[i + 1];

    final result = service.findPath(
      startNodeId: startId,
      goalNodeId: goalId,
      graph: graph,
    );

    if (result.found) {
      totalDistance += result.totalDistance;

      // Get spot names for description
      final startSpot = await repository.getSpotById(startId);
      final goalSpot = await repository.getSpotById(goalId);
      routeDescription.add(
          '${startSpot?.name ?? startId} → ${goalSpot?.name ?? goalId} (${result.totalDistance.toStringAsFixed(1)}km)');

      // Add intermediate nodes (excluding first node of each segment to avoid duplicates)
      if (i == 0) {
        fullRoute.addAll(result.path);
      } else {
        fullRoute.addAll(result.path.sublist(1));
      }
    }
  }

  print('  Total Distance: ${totalDistance.toStringAsFixed(2)} km');
  print('  Route: ${fullRoute.join(' → ')}');
  print('  Segments:');
  for (final segment in routeDescription) {
    print('    • $segment');
  }
}

/// Utility class for building custom tour routes.
///
/// Example usage:
/// ```dart
/// final tourBuilder = TourRouteBuilder(repository);
/// await tourBuilder.addStop('basilica_del_nino');
/// await tourBuilder.addStop('magellans_cross');
/// final route = await tourBuilder.build();
/// ```
class TourRouteBuilder {
  final TourSpotRepository _repository;
  final List<String> _stops = [];

  TourRouteBuilder(this._repository);

  /// Adds a stop to the tour route.
  ///
  /// [spotId] The ID of the tourist spot to add.
  ///
  /// Returns this builder for method chaining.
  TourRouteBuilder addStop(String spotId) {
    _stops.add(spotId);
    return this;
  }

  /// Adds multiple stops to the tour route.
  TourRouteBuilder addStops(List<String> spotIds) {
    _stops.addAll(spotIds);
    return this;
  }

  /// Builds the complete tour route using A* pathfinding.
  ///
  /// Returns a [TourRoute] containing the optimized route,
  /// total distance, and sequence of spots.
  Future<TourRoute> build() async {
    if (_stops.length < 2) {
      return TourRoute(
        stops: _stops,
        path: _stops,
        totalDistance: 0,
        segments: [],
      );
    }

    final graph = await _repository.getGraphForPathfinding();
    final service = PathfindingService();

    double totalDistance = 0;
    List<String> fullPath = [];
    List<RouteSegment> segments = [];

    for (int i = 0; i < _stops.length - 1; i++) {
      final result = service.findPath(
        startNodeId: _stops[i],
        goalNodeId: _stops[i + 1],
        graph: graph,
      );

      if (result.found) {
        totalDistance += result.totalDistance;

        if (i == 0) {
          fullPath.addAll(result.path);
        } else {
          fullPath.addAll(result.path.sublist(1));
        }

        segments.add(RouteSegment(
          from: _stops[i],
          to: _stops[i + 1],
          distance: result.totalDistance,
          path: result.path,
        ));
      }
    }

    return TourRoute(
      stops: List.unmodifiable(_stops),
      path: fullPath,
      totalDistance: totalDistance,
      segments: segments,
    );
  }
}

/// Represents a complete tour route with pathfinding results.
class TourRoute {
  /// Original list of stops requested.
  final List<String> stops;

  /// Complete path including intermediate nodes.
  final List<String> path;

  /// Total distance of the entire route.
  final double totalDistance;

  /// Individual segments between consecutive stops.
  final List<RouteSegment> segments;

  TourRoute({
    required this.stops,
    required this.path,
    required this.totalDistance,
    required this.segments,
  });

  @override
  String toString() {
    return 'TourRoute(stops: ${stops.length}, distance: ${totalDistance.toStringAsFixed(2)}km)';
  }
}

/// Represents a single segment of a tour route.
class RouteSegment {
  final String from;
  final String to;
  final double distance;
  final List<String> path;

  RouteSegment({
    required this.from,
    required this.to,
    required this.distance,
    required this.path,
  });
}
