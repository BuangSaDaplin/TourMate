import 'geo_coordinate.dart';

/// Represents a node in a graph for geospatial pathfinding.
///
/// Each [GraphNode] contains a unique identifier, geographic coordinates,
/// and a list of connected neighbors with associated edge weights.
/// This structure is designed for tourist spot navigation in TourMate.
///
/// Example usage:
/// ```dart
/// final nodeA = GraphNode(
///   id: 'spot_1',
///   coordinate: GeoCoordinate(14.5995, 120.9842), // Manila
/// );
///
/// nodeA.addNeighbor('spot_2', 500.0); // 500km to Cebu
/// final neighbors = nodeA.getNeighbors(); // Returns Map of neighborId -> distance
/// ```
class GraphNode {
  /// Unique identifier for this node (e.g., tour spot ID)
  final String id;

  /// Geographic coordinates of this node
  final GeoCoordinate coordinate;

  /// Map of neighbor node IDs to edge weights (distance in kilometers)
  ///
  /// Using a Map allows O(1) lookup of neighbor distances
  final Map<String, double> _neighbors;

  /// Creates a new [GraphNode] instance.
  ///
  /// [id] must be unique within the graph.
  /// [coordinate] represents the geographic position.
  GraphNode({required this.id, required this.coordinate}) : _neighbors = {};

  /// Creates a [GraphNode] from a map (e.g., Firestore document).
  ///
  /// Expected format:
  /// ```dart
  /// {
  ///   'id': 'spot_1',
  ///   'coordinate': {'latitude': 14.5995, 'longitude': 120.9842},
  ///   'neighbors': {'spot_2': 500.0, 'spot_3': 300.0}
  /// }
  /// ```
  factory GraphNode.fromMap(Map<String, dynamic> map) {
    final node = GraphNode(
      id: map['id'] as String,
      coordinate: GeoCoordinate.fromMap(
        map['coordinate'] as Map<String, dynamic>,
      ),
    );

    // Add neighbors if present
    final neighbors = map['neighbors'] as Map<String, dynamic>?;
    if (neighbors != null) {
      neighbors.forEach((neighborId, distance) {
        node._neighbors[neighborId] = (distance is double)
            ? distance
            : (distance is int)
                ? distance.toDouble()
                : double.tryParse(distance.toString()) ?? 0.0;
      });
    }

    return node;
  }

  /// Converts this node to a Map for storage.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'coordinate': coordinate.toMap(),
      'neighbors': _neighbors,
    };
  }

  /// Adds a neighbor connection to this node.
  ///
  /// [neighborId] The ID of the neighboring node.
  /// [distance] The edge weight (distance in kilometers) to the neighbor.
  void addNeighbor(String neighborId, double distance) {
    _neighbors[neighborId] = distance;
  }

  /// Removes a neighbor connection from this node.
  ///
  /// Returns true if the neighbor was removed, false if it didn't exist.
  bool removeNeighbor(String neighborId) {
    return _neighbors.remove(neighborId) != null;
  }

  /// Gets the distance to a specific neighbor.
  ///
  /// Returns the distance in kilometers, or null if not a neighbor.
  double? getDistanceToNeighbor(String neighborId) {
    return _neighbors[neighborId];
  }

  /// Returns an unmodifiable view of all neighbors.
  ///
  /// Returns a [Map<String, double>] where keys are neighbor IDs
  /// and values are the distances (edge weights) in kilometers.
  Map<String, double> getNeighbors() {
    return Map<String, double>.unmodifiable(_neighbors);
  }

  /// Returns true if this node has the specified neighbor.
  bool hasNeighbor(String neighborId) {
    return _neighbors.containsKey(neighborId);
  }

  /// Returns the number of neighbors this node has.
  int getNeighborCount() {
    return _neighbors.length;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GraphNode && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'GraphNode(id: $id, coordinate: $coordinate, neighbors: ${_neighbors.length})';
  }
}
