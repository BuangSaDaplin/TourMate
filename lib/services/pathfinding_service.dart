import 'dart:collection';
import '../models/graph_node.dart';
import '../models/geo_coordinate.dart';

/// Result class containing the pathfinding outcome.
///
/// Provides detailed information about the found path including:
/// - The sequence of node IDs from start to goal
/// - Total distance traveled
/// - Whether a path was found
/// - List of coordinates for visualization
class PathResult {
  /// Whether a path was successfully found
  final bool found;

  /// List of node IDs in order from start to goal
  final List<String> path;

  /// Total distance of the path in kilometers
  final double totalDistance;

  /// List of coordinates for path visualization/mapping
  final List<GeoCoordinate> coordinates;

  /// Creates a successful path result.
  PathResult.success({
    required this.path,
    required this.totalDistance,
    required this.coordinates,
  }) : found = true;

  /// Creates a failed path result (no path found).
  PathResult.notFound()
    : found = false,
      path = const [],
      totalDistance = 0.0,
      coordinates = const [];

  /// Returns true if a path was found.
  bool get hasPath => found;

  /// Returns the number of nodes in the path.
  int get pathLength => path.length;

  @override
  String toString() {
    if (found) {
      return 'PathResult(found: true, nodes: ${path.length}, distance: ${totalDistance.toStringAsFixed(2)}km)';
    }
    return 'PathResult(found: false)';
  }
}

/// A* Pathfinding Service for geospatial navigation.
///
/// This service implements the A* (A-Star) search algorithm optimized for
/// geographic coordinates. It uses the Haversine formula for calculating
/// heuristic distances, making it suitable for tourist spot navigation.
///
/// ## Algorithm Overview
/// A* finds the shortest path by maintaining a priority queue (open set) of
/// nodes to explore, ordered by their f-score (g-score + h-score):
/// - **g-score**: Cost from start to current node (actual distance)
/// - **h-score**: Estimated cost from current to goal (Haversine distance)
/// - **f-score**: g-score + h-score (total estimated cost)
///
/// ## Usage Example
/// ```dart
/// final service = PathfindingService();
/// final result = service.findPath(
///   startNodeId: 'manila',
///   goalNodeId: 'cebu',
///   graph: graphNodes,
/// );
///
/// if (result.found) {
///   print('Path: ${result.path}');
///   print('Distance: ${result.totalDistance}km');
/// }
/// ```
class PathfindingService {
  /// Default maximum iterations to prevent infinite loops
  static const int defaultMaxIterations = 10000;

  /// Creates a new [PathfindingService] instance.
  const PathfindingService();

  /// Finds the shortest path between two nodes using A* algorithm.
  ///
  /// [startNodeId] The ID of the starting node.
  /// [goalNodeId] The ID of the goal/target node.
  /// [graph] Map of node IDs to GraphNode instances.
  /// [maxIterations] Maximum iterations to prevent infinite loops (default: 10000).
  ///
  /// Returns a [PathResult] containing the path and distance information.
  PathResult findPath({
    required String startNodeId,
    required String goalNodeId,
    required Map<String, GraphNode> graph,
    int maxIterations = defaultMaxIterations,
  }) {
    // Validate inputs
    if (startNodeId == goalNodeId) {
      return _createTrivialResult(startNodeId, graph);
    }

    if (!graph.containsKey(startNodeId)) {
      return PathResult.notFound();
    }

    if (!graph.containsKey(goalNodeId)) {
      return PathResult.notFound();
    }

    // Initialize A* data structures
    // gScore: Cost from start to current node (Map<nodeId, cost>)
    final gScore = <String, double>{};

    // fScore: Estimated total cost (gScore + hScore) - used as priority
    final fScore = SplayTreeMap<String, double>();

    // cameFrom: For path reconstruction
    final cameFrom = <String, String>{};

    // Closed set: Nodes already evaluated
    final closedSet = <String>{};

    // Open set: Priority queue of nodes to explore (using fScore as priority)
    final openSet = SplayTreeMap<String, double>();

    // Initialize start node
    gScore[startNodeId] = 0.0;
    final startNode = graph[startNodeId]!;
    final goalNode = graph[goalNodeId]!;
    final hStart = _calculateHeuristic(
      startNode.coordinate,
      goalNode.coordinate,
    );
    fScore[startNodeId] = hStart;
    openSet[startNodeId] = hStart;

    int iterations = 0;

    while (openSet.isNotEmpty) {
      // Prevent infinite loops
      iterations++;
      if (iterations > maxIterations) {
        return PathResult.notFound();
      }

      // Get node with lowest fScore
      final currentId = openSet.keys.first;
      openSet.remove(currentId);

      // Check if we reached the goal
      if (currentId == goalNodeId) {
        return _reconstructPath(currentId, cameFrom, gScore, graph);
      }

      // Skip if already evaluated
      if (closedSet.contains(currentId)) {
        continue;
      }
      closedSet.add(currentId);

      final currentNode = graph[currentId]!;

      // Explore neighbors
      for (final neighborEntry in currentNode.getNeighbors().entries) {
        final neighborId = neighborEntry.key;
        final edgeWeight = neighborEntry.value;

        // Skip if already fully evaluated
        if (closedSet.contains(neighborId)) {
          continue;
        }

        // Calculate tentative gScore
        final tentativeGScore = gScore[currentId]! + edgeWeight;

        // Check if this is a better path to neighbor
        final neighborGScore = gScore[neighborId];
        if (neighborGScore == null || tentativeGScore < neighborGScore) {
          // This path to neighbor is better than any previous one
          cameFrom[neighborId] = currentId;
          gScore[neighborId] = tentativeGScore;

          // Calculate fScore (gScore + heuristic)
          final neighborNode = graph[neighborId]!;
          final f =
              tentativeGScore +
              _calculateHeuristic(neighborNode.coordinate, goalNode.coordinate);

          // Update or add to open set
          gScore[neighborId] = tentativeGScore;
          fScore[neighborId] = f;
          openSet[neighborId] = f;
        }
      }
    }

    // No path found
    return PathResult.notFound();
  }

  /// Calculates the Haversine heuristic distance between two coordinates.
  ///
  /// This is the h-score in A*, representing the estimated cost from
  /// the current node to the goal node. Using the Haversine formula
  /// ensures accuracy for geographic coordinates.
  double _calculateHeuristic(GeoCoordinate from, GeoCoordinate to) {
    return from.distanceTo(to);
  }

  /// Reconstructs the path from cameFrom map.
  ///
  /// [currentId] The goal node ID.
  /// [cameFrom] Map tracking the path reconstruction.
  /// [gScore] Map of node IDs to their g-scores (actual costs from start).
  /// [graph] The graph containing all nodes.
  PathResult _reconstructPath(
    String currentId,
    Map<String, String> cameFrom,
    Map<String, double> gScore,
    Map<String, GraphNode> graph,
  ) {
    final path = <String>[];
    final coordinates = <GeoCoordinate>[];
    var totalDistance = 0.0;

    // Reconstruct path by backtracking
    var current = currentId;
    while (cameFrom.containsKey(current)) {
      path.insert(0, current);
      final node = graph[current]!;
      coordinates.insert(0, node.coordinate);
      current = cameFrom[current]!;
    }

    // Add start node
    path.insert(0, current);
    final startNode = graph[current]!;
    coordinates.insert(0, startNode.coordinate);

    // Calculate total distance from gScore
    totalDistance = gScore[currentId] ?? 0.0;

    return PathResult.success(
      path: path,
      totalDistance: totalDistance,
      coordinates: coordinates,
    );
  }

  /// Creates a result for trivial case where start equals goal.
  PathResult _createTrivialResult(String nodeId, Map<String, GraphNode> graph) {
    final node = graph[nodeId]!;
    return PathResult.success(
      path: [nodeId],
      totalDistance: 0.0,
      coordinates: [node.coordinate],
    );
  }

  /// Calculates the distance between two nodes directly.
  ///
  /// [nodeA] First node.
  /// [nodeB] Second node.
  ///
  /// Returns the distance in kilometers using Haversine formula.
  double calculateDistanceBetweenNodes(GraphNode nodeA, GraphNode nodeB) {
    return nodeA.coordinate.distanceTo(nodeB.coordinate);
  }

  /// Finds multiple path alternatives sorted by distance.
  ///
  /// Useful for providing users with route options.
  ///
  /// [startNodeId] Starting node ID.
  /// [goalNodeId] Goal node ID.
  /// [graph] Graph containing all nodes.
  /// [maxAlternatives] Maximum number of alternatives to return (default: 3).
  List<PathResult> findPathAlternatives({
    required String startNodeId,
    required String goalNodeId,
    required Map<String, GraphNode> graph,
    int maxAlternatives = 3,
  }) {
    // For now, return the best path
    // Future enhancement: implement A* with different heuristics
    final bestPath = findPath(
      startNodeId: startNodeId,
      goalNodeId: goalNodeId,
      graph: graph,
    );

    if (bestPath.found) {
      return [bestPath];
    }
    return [];
  }

  /// Validates if a path exists between two nodes.
  ///
  /// More efficient than finding the full path when only
  /// connectivity needs to be checked.
  ///
  /// [startNodeId] Starting node ID.
  /// [goalNodeId] Goal node ID.
  /// [graph] Graph containing all nodes.
  bool pathExists({
    required String startNodeId,
    required String goalNodeId,
    required Map<String, GraphNode> graph,
  }) {
    final result = findPath(
      startNodeId: startNodeId,
      goalNodeId: goalNodeId,
      graph: graph,
    );
    return result.found;
  }
}
