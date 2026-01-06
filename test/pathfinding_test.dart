import 'package:flutter_test/flutter_test.dart';
import 'package:tourmate_app/models/geo_coordinate.dart';
import 'package:tourmate_app/models/graph_node.dart';
import 'package:tourmate_app/services/pathfinding_service.dart';

void main() {
  group('GeoCoordinate Tests', () {
    test('should create coordinate with valid values', () {
      final coord = GeoCoordinate(latitude: 14.5995, longitude: 120.9842);
      expect(coord.latitude, equals(14.5995));
      expect(coord.longitude, equals(120.9842));
    });

    test('should calculate Haversine distance correctly', () {
      final manila = GeoCoordinate(latitude: 14.5995, longitude: 120.9842);
      final cebu = GeoCoordinate(latitude: 10.3157, longitude: 123.8854);

      final distance = manila.distanceTo(cebu);

      // Manila to Cebu is approximately 570km
      expect(distance, greaterThan(500));
      expect(distance, lessThan(650));
    });

    test('should return 0 distance for same coordinate', () {
      final coord = GeoCoordinate(latitude: 14.5995, longitude: 120.9842);
      final distance = coord.distanceTo(coord);
      expect(distance, equals(0.0));
    });

    test('should create from map correctly', () {
      final map = {
        'latitude': 14.5995,
        'longitude': 120.9842,
      };
      final coord = GeoCoordinate.fromMap(map);
      expect(coord.latitude, equals(14.5995));
      expect(coord.longitude, equals(120.9842));
    });

    test('should convert to map correctly', () {
      final coord = GeoCoordinate(latitude: 14.5995, longitude: 120.9842);
      final map = coord.toMap();
      expect(map['latitude'], equals(14.5995));
      expect(map['longitude'], equals(120.9842));
    });

    test('should implement equality correctly', () {
      final coord1 = GeoCoordinate(latitude: 14.5995, longitude: 120.9842);
      final coord2 = GeoCoordinate(latitude: 14.5995, longitude: 120.9842);
      final coord3 = GeoCoordinate(latitude: 10.3157, longitude: 123.8854);

      expect(coord1, equals(coord2));
      expect(coord1, isNot(equals(coord3)));
    });

    test('should have correct hashCode', () {
      final coord1 = GeoCoordinate(latitude: 14.5995, longitude: 120.9842);
      final coord2 = GeoCoordinate(latitude: 14.5995, longitude: 120.9842);

      expect(coord1.hashCode, equals(coord2.hashCode));
    });
  });

  group('GraphNode Tests', () {
    test('should create node with id and coordinate', () {
      final coord = GeoCoordinate(latitude: 14.5995, longitude: 120.9842);
      final node = GraphNode(id: 'manila', coordinate: coord);

      expect(node.id, equals('manila'));
      expect(node.coordinate, equals(coord));
    });

    test('should add and retrieve neighbors', () {
      final nodeA = GraphNode(
        id: 'manila',
        coordinate: GeoCoordinate(latitude: 14.5995, longitude: 120.9842),
      );
      final nodeB = GraphNode(
        id: 'cebu',
        coordinate: GeoCoordinate(latitude: 10.3157, longitude: 123.8854),
      );

      final distance = nodeA.coordinate.distanceTo(nodeB.coordinate);
      nodeA.addNeighbor('cebu', distance);

      expect(nodeA.hasNeighbor('cebu'), isTrue);
      expect(nodeA.getNeighborCount(), equals(1));
      expect(nodeA.getDistanceToNeighbor('cebu'), equals(distance));
    });

    test('should remove neighbors correctly', () {
      final node = GraphNode(
        id: 'manila',
        coordinate: GeoCoordinate(latitude: 14.5995, longitude: 120.9842),
      );

      node.addNeighbor('cebu', 570.0);
      expect(node.hasNeighbor('cebu'), isTrue);

      final removed = node.removeNeighbor('cebu');
      expect(removed, isTrue);
      expect(node.hasNeighbor('cebu'), isFalse);
    });

    test('should return unmodifiable neighbors map', () {
      final node = GraphNode(
        id: 'manila',
        coordinate: GeoCoordinate(latitude: 14.5995, longitude: 120.9842),
      );

      node.addNeighbor('cebu', 570.0);
      node.addNeighbor('davao', 1450.0);

      final neighbors = node.getNeighbors();
      expect(() => neighbors['cebu'] = 100.0, throwsUnsupportedError);
    });

    test('should create from map correctly', () {
      final map = {
        'id': 'manila',
        'coordinate': {
          'latitude': 14.5995,
          'longitude': 120.9842,
        },
        'neighbors': {
          'cebu': 570.0,
          'davao': 1450.0,
        },
      };

      final node = GraphNode.fromMap(map);
      expect(node.id, equals('manila'));
      expect(node.hasNeighbor('cebu'), isTrue);
      expect(node.hasNeighbor('davao'), isTrue);
    });

    test('should convert to map correctly', () {
      final node = GraphNode(
        id: 'manila',
        coordinate: GeoCoordinate(latitude: 14.5995, longitude: 120.9842),
      );
      node.addNeighbor('cebu', 570.0);

      final map = node.toMap();
      expect(map['id'], equals('manila'));
      expect(map['neighbors']['cebu'], equals(570.0));
    });

    test('should implement equality by id', () {
      final node1 = GraphNode(
        id: 'manila',
        coordinate: GeoCoordinate(latitude: 14.5995, longitude: 120.9842),
      );
      final node2 = GraphNode(
        id: 'manila',
        coordinate: GeoCoordinate(latitude: 14.5995, longitude: 120.9842),
      );
      final node3 = GraphNode(
        id: 'cebu',
        coordinate: GeoCoordinate(latitude: 10.3157, longitude: 123.8854),
      );

      expect(node1, equals(node2));
      expect(node1, isNot(equals(node3)));
    });
  });

  group('PathfindingService Tests', () {
    late PathfindingService service;

    setUp(() {
      service = PathfindingService();
    });

    test('should find direct path between two connected nodes', () {
      final graph = _createLinearGraph();
      final result = service.findPath(
        startNodeId: 'A',
        goalNodeId: 'B',
        graph: graph,
      );

      expect(result.found, isTrue);
      expect(result.path, equals(['A', 'B']));
      expect(result.totalDistance, greaterThan(0));
    });

    test('should find shortest path through multiple nodes', () {
      final graph = _createGraphWithMultiplePaths();
      final result = service.findPath(
        startNodeId: 'A',
        goalNodeId: 'D',
        graph: graph,
      );

      expect(result.found, isTrue);
      expect(result.path, equals(['A', 'B', 'D'])); // Shorter path
      expect(result.path.length, equals(3));
    });

    test('should return not found for disconnected nodes', () {
      final graph = _createDisconnectedGraph();
      final result = service.findPath(
        startNodeId: 'A',
        goalNodeId: 'E',
        graph: graph,
      );

      expect(result.found, isFalse);
      expect(result.path, isEmpty);
    });

    test('should return trivial path for same start and goal', () {
      final graph = _createLinearGraph();
      final result = service.findPath(
        startNodeId: 'A',
        goalNodeId: 'A',
        graph: graph,
      );

      expect(result.found, isTrue);
      expect(result.path, equals(['A']));
      expect(result.totalDistance, equals(0.0));
    });

    test('should return not found for non-existent start node', () {
      final graph = _createLinearGraph();
      final result = service.findPath(
        startNodeId: 'X',
        goalNodeId: 'B',
        graph: graph,
      );

      expect(result.found, isFalse);
    });

    test('should return not found for non-existent goal node', () {
      final graph = _createLinearGraph();
      final result = service.findPath(
        startNodeId: 'A',
        goalNodeId: 'Y',
        graph: graph,
      );

      expect(result.found, isFalse);
    });

    test('should return coordinates for path', () {
      final graph = _createLinearGraph();
      final result = service.findPath(
        startNodeId: 'A',
        goalNodeId: 'B',
        graph: graph,
      );

      expect(result.found, isTrue);
      expect(result.coordinates.length, equals(result.path.length));
    });

    test('pathExists should return true for connected nodes', () {
      final graph = _createLinearGraph();
      final exists = service.pathExists(
        startNodeId: 'A',
        goalNodeId: 'B',
        graph: graph,
      );

      expect(exists, isTrue);
    });

    test('pathExists should return false for disconnected nodes', () {
      final graph = _createDisconnectedGraph();
      final exists = service.pathExists(
        startNodeId: 'A',
        goalNodeId: 'E',
        graph: graph,
      );

      expect(exists, isFalse);
    });

    test('should handle large graphs efficiently', () {
      final graph = _createGridGraph(10);
      final result = service.findPath(
        startNodeId: 'node_0_0',
        goalNodeId: 'node_9_9',
        graph: graph,
      );

      // Should complete without timing out
      expect(result.found, isTrue);
      expect(result.path.length, greaterThan(0));
    });

    test('calculateDistanceBetweenNodes should use Haversine', () {
      final nodeA = GraphNode(
        id: 'manila',
        coordinate: GeoCoordinate(latitude: 14.5995, longitude: 120.9842),
      );
      final nodeB = GraphNode(
        id: 'cebu',
        coordinate: GeoCoordinate(latitude: 10.3157, longitude: 123.8854),
      );

      final distance = service.calculateDistanceBetweenNodes(nodeA, nodeB);

      expect(distance, greaterThan(500));
      expect(distance, lessThan(650));
    });
  });

  group('PathResult Tests', () {
    test('should create success result correctly', () {
      final result = PathResult.success(
        path: ['A', 'B', 'C'],
        totalDistance: 100.0,
        coordinates: [
          GeoCoordinate(latitude: 14.5995, longitude: 120.9842),
          GeoCoordinate(latitude: 10.3157, longitude: 123.8854),
          GeoCoordinate(latitude: 7.0731, longitude: 125.6128),
        ],
      );

      expect(result.found, isTrue);
      expect(result.hasPath, isTrue);
      expect(result.pathLength, equals(3));
      expect(result.totalDistance, equals(100.0));
    });

    test('should create not found result correctly', () {
      final result = PathResult.notFound();

      expect(result.found, isFalse);
      expect(result.hasPath, isFalse);
      expect(result.pathLength, equals(0));
    });
  });
}

// Helper functions to create test graphs

Map<String, GraphNode> _createLinearGraph() {
  final graph = <String, GraphNode>{};

  // Node A (Manila)
  final nodeA = GraphNode(
    id: 'A',
    coordinate: GeoCoordinate(latitude: 14.5995, longitude: 120.9842),
  );
  // Node B (Cebu)
  final nodeB = GraphNode(
    id: 'B',
    coordinate: GeoCoordinate(latitude: 10.3157, longitude: 123.8854),
  );

  // Calculate distance using Haversine
  final distanceAB = nodeA.coordinate.distanceTo(nodeB.coordinate);
  nodeA.addNeighbor('B', distanceAB);
  nodeB.addNeighbor('A', distanceAB);

  graph['A'] = nodeA;
  graph['B'] = nodeB;

  return graph;
}

Map<String, GraphNode> _createGraphWithMultiplePaths() {
  final graph = <String, GraphNode>{};

  // A -> B (100km) -> D (100km) = 200km total
  // A -> C (50km) -> D (200km) = 250km total

  final nodeA = GraphNode(
    id: 'A',
    coordinate: GeoCoordinate(latitude: 0, longitude: 0),
  );
  final nodeB = GraphNode(
    id: 'B',
    coordinate: GeoCoordinate(latitude: 1, longitude: 1),
  );
  final nodeC = GraphNode(
    id: 'C',
    coordinate: GeoCoordinate(latitude: 0.5, longitude: 0.5),
  );
  final nodeD = GraphNode(
    id: 'D',
    coordinate: GeoCoordinate(latitude: 2, longitude: 2),
  );

  nodeA.addNeighbor('B', 100);
  nodeA.addNeighbor('C', 50);
  nodeB.addNeighbor('A', 100);
  nodeB.addNeighbor('D', 100);
  nodeC.addNeighbor('A', 50);
  nodeC.addNeighbor('D', 200);
  nodeD.addNeighbor('B', 100);
  nodeD.addNeighbor('C', 200);

  graph['A'] = nodeA;
  graph['B'] = nodeB;
  graph['C'] = nodeC;
  graph['D'] = nodeD;

  return graph;
}

Map<String, GraphNode> _createDisconnectedGraph() {
  final graph = <String, GraphNode>{};

  // Component 1: A - B - C
  final nodeA =
      GraphNode(id: 'A', coordinate: GeoCoordinate(latitude: 0, longitude: 0));
  final nodeB =
      GraphNode(id: 'B', coordinate: GeoCoordinate(latitude: 1, longitude: 1));
  final nodeC =
      GraphNode(id: 'C', coordinate: GeoCoordinate(latitude: 2, longitude: 2));

  nodeA.addNeighbor('B', 100);
  nodeB.addNeighbor('A', 100);
  nodeB.addNeighbor('C', 100);
  nodeC.addNeighbor('B', 100);

  // Component 2: D - E (disconnected from component 1)
  final nodeD = GraphNode(
      id: 'D', coordinate: GeoCoordinate(latitude: 10, longitude: 10));
  final nodeE = GraphNode(
      id: 'E', coordinate: GeoCoordinate(latitude: 11, longitude: 11));

  nodeD.addNeighbor('E', 100);
  nodeE.addNeighbor('D', 100);

  graph['A'] = nodeA;
  graph['B'] = nodeB;
  graph['C'] = nodeC;
  graph['D'] = nodeD;
  graph['E'] = nodeE;

  return graph;
}

Map<String, GraphNode> _createGridGraph(int size) {
  final graph = <String, GraphNode>{};

  for (int row = 0; row < size; row++) {
    for (int col = 0; col < size; col++) {
      final id = 'node_${row}_$col';
      final lat = row * 0.1;
      final lng = col * 0.1;

      final node = GraphNode(
        id: id,
        coordinate: GeoCoordinate(latitude: lat, longitude: lng),
      );

      // Connect to right neighbor
      if (col < size - 1) {
        node.addNeighbor('node_${row}_${col + 1}', 10);
      }
      // Connect to bottom neighbor
      if (row < size - 1) {
        node.addNeighbor('node_${row + 1}_$col', 10);
      }

      graph[id] = node;
    }
  }

  // Add reverse connections
  for (int row = 0; row < size; row++) {
    for (int col = 0; col < size; col++) {
      final node = graph['node_${row}_$col']!;
      if (col > 0) {
        node.addNeighbor('node_${row}_${col - 1}', 10);
      }
      if (row > 0) {
        node.addNeighbor('node_${row - 1}_$col', 10);
      }
    }
  }

  return graph;
}
