import 'dart:math';
import 'package:tourmate_app/models/itinerary_model.dart';
import 'package:tourmate_app/data/tour_spot_model.dart';
import 'package:tourmate_app/models/geo_coordinate.dart';
import 'package:tourmate_app/services/pathfinding_service.dart';
import 'package:tourmate_app/data/cebu_graph_data.dart';

class UserContext {
  final GeoCoordinate? currentLocation;
  final DateTime startTime;
  final DateTime endTime;
  final double? budget;
  final List<String> interests;
  final String pace; // 'relaxed', 'moderate', 'packed'

  UserContext({
    this.currentLocation,
    required this.startTime,
    required this.endTime,
    this.budget,
    this.interests = const [],
    this.pace = 'moderate',
  });
}

class ItineraryEvent {
  final TourSpot spot;
  final DateTime arrivalTime;
  final DateTime departureTime;
  final Duration travelTimeToNext;
  final double travelDistanceToNext;

  ItineraryEvent({
    required this.spot,
    required this.arrivalTime,
    required this.departureTime,
    this.travelTimeToNext = Duration.zero,
    this.travelDistanceToNext = 0.0,
  });
}

class ItineraryGeneratorService {
  // 1. User Context Initialization
  UserContext initializeUserContext({
    GeoCoordinate? currentLocation,
    required DateTime startTime,
    required DateTime endTime,
    double? budget,
    List<String> interests = const [],
    String pace = 'moderate',
  }) {
    // Use default location (Cebu City center) if not provided
    final location = currentLocation ??
        GeoCoordinate(latitude: 10.3157, longitude: 123.8854);

    return UserContext(
      currentLocation: location,
      startTime: startTime,
      endTime: endTime,
      budget: budget,
      interests: interests,
      pace: pace,
    );
  }

  // 2. Temporal Modeling and Time Management
  Duration estimateTravelTime(double distanceKm, {bool isUrban = true}) {
    // Average urban speed: 20-30 km/h, rural: 40-60 km/h
    final averageSpeed = isUrban ? 25.0 : 50.0;
    final timeHours = distanceKm / averageSpeed;

    // Add traffic factor for urban areas (1.2x time)
    final adjustedTime = isUrban ? timeHours * 1.2 : timeHours;

    return Duration(minutes: (adjustedTime * 60).round());
  }

  bool isLocationOpen(TourSpot spot, DateTime time) {
    if (spot.operatingHours == null)
      return true; // Assume open if no hours specified

    // Parse operating hours (format: '08:00-17:00')
    final hoursRange = spot.operatingHours!.split('-');
    if (hoursRange.length != 2) return true;

    final openTime = _timeToMinutes(hoursRange[0]);
    final closeTime = _timeToMinutes(hoursRange[1]);

    final currentMinutes = time.hour * 60 + time.minute;

    return currentMinutes >= openTime && currentMinutes <= closeTime;
  }

  int _timeToMinutes(String time) {
    final parts = time.split(':');
    if (parts.length != 2) return 0;
    final hour = int.tryParse(parts[0]) ?? 0;
    final minute = int.tryParse(parts[1]) ?? 0;
    return hour * 60 + minute;
  }

  // 3. Optimization Engine (Route Intelligence Layer)
  List<TourSpot> performSpatialClustering(List<TourSpot> spots) {
    // Group nearby spots (within 2km) for efficient routing
    final clusters = <List<TourSpot>>[];

    for (final spot in spots) {
      bool addedToCluster = false;

      for (final cluster in clusters) {
        final clusterCenter = cluster.first;
        final distance = spot.coordinate.distanceTo(clusterCenter.coordinate);

        if (distance <= 2.0) {
          // 2km radius
          cluster.add(spot);
          addedToCluster = true;
          break;
        }
      }

      if (!addedToCluster) {
        clusters.add([spot]);
      }
    }

    // Sort clusters by category priority (religious/historical first, then others)
    clusters.sort((a, b) {
      final aPriority = _getCategoryPriority(a.first.category);
      final bPriority = _getCategoryPriority(b.first.category);
      return aPriority.compareTo(bPriority);
    });

    return clusters.expand((cluster) => cluster).toList();
  }

  int _getCategoryPriority(TourSpotCategory category) {
    switch (category) {
      case TourSpotCategory.religious:
      case TourSpotCategory.historical:
        return 1;
      case TourSpotCategory.natural:
      case TourSpotCategory.viewpoint:
        return 2;
      default:
        return 3;
    }
  }

  List<TourSpot> applyDirectionalLogic(
      List<TourSpot> spots, DateTime startTime) {
    final hour = startTime.hour;

    if (hour < 12) {
      // Morning: Prioritize city center locations first
      final cityCenter = GeoCoordinate(latitude: 10.3157, longitude: 123.8854);
      return spots
        ..sort((a, b) {
          final distA = a.coordinate.distanceTo(cityCenter);
          final distB = b.coordinate.distanceTo(cityCenter);
          return distA.compareTo(distB);
        });
    } else {
      // Afternoon: Mix city and outskirts
      return spots;
    }
  }

  List<TourSpot> optimizeRoute(
      List<TourSpot> spots, GeoCoordinate startLocation) {
    if (spots.isEmpty) return spots;

    // Get the graph data for pathfinding
    final graph = CebuGraphData.getGraphNodes();
    final pathfindingService = PathfindingService();

    // Find optimal starting point closest to user location using graph distances
    TourSpot bestStart = spots.first;
    double minDistance = double.infinity;

    for (final spot in spots) {
      // Try to find path from start location to spot using graph
      if (graph.containsKey(spot.id)) {
        final pathResult = pathfindingService.findPath(
          startNodeId: spot.id,
          goalNodeId: spot.id, // Same node for distance from start
          graph: graph,
        );
        if (pathResult.found) {
          // For distance from start location, use straight-line as approximation
          final distance = startLocation.distanceTo(spot.coordinate);
          if (distance < minDistance) {
            minDistance = distance;
            bestStart = spot;
          }
        }
      } else {
        // Fallback to straight-line distance if spot not in graph
        final distance = startLocation.distanceTo(spot.coordinate);
        if (distance < minDistance) {
          minDistance = distance;
          bestStart = spot;
        }
      }
    }

    // Use graph-based pathfinding for TSP approximation
    final optimizedRoute = <TourSpot>[bestStart];
    final remainingSpots = spots.where((s) => s != bestStart).toList();

    while (remainingSpots.isNotEmpty) {
      final lastSpot = optimizedRoute.last;
      TourSpot nextSpot = remainingSpots.first;
      double minDist = double.infinity;

      // Find the remaining spot with shortest path from current spot
      for (final spot in remainingSpots) {
        double distance = 0.0;

        // Try to use graph-based pathfinding
        if (graph.containsKey(lastSpot.id) && graph.containsKey(spot.id)) {
          final pathResult = pathfindingService.findPath(
            startNodeId: lastSpot.id,
            goalNodeId: spot.id,
            graph: graph,
          );
          if (pathResult.found) {
            distance = pathResult.totalDistance;
          } else {
            // Fallback to straight-line if no path found
            distance = lastSpot.coordinate.distanceTo(spot.coordinate);
          }
        } else {
          // Fallback to straight-line distance if spots not in graph
          distance = lastSpot.coordinate.distanceTo(spot.coordinate);
        }

        if (distance < minDist) {
          minDist = distance;
          nextSpot = spot;
        }
      }

      optimizedRoute.add(nextSpot);
      remainingSpots.remove(nextSpot);
    }

    return optimizedRoute;
  }

  // 4. User Preference Modeling
  List<TourSpot> filterByBudget(List<TourSpot> spots, double budget) {
    return spots.where((spot) {
      final cost = spot.entranceFee ?? 0;
      return cost <= budget;
    }).toList();
  }

  List<TourSpot> filterByInterests(
      List<TourSpot> spots, List<String> interests) {
    if (interests.isEmpty) return spots;

    return spots.where((spot) {
      final categoryMatch = interests.any((interest) =>
          interest.toLowerCase().contains(spot.category.name.toLowerCase()) ||
          spot.category.name.toLowerCase().contains(interest.toLowerCase()));

      final highlightsMatch = spot.highlights?.any((highlight) => interests.any(
              (interest) =>
                  highlight.toLowerCase().contains(interest.toLowerCase()) ||
                  interest.toLowerCase().contains(highlight.toLowerCase()))) ??
          false;

      return categoryMatch || highlightsMatch;
    }).toList();
  }

  int getVisitDurationMinutes(TourSpot spot, String pace) {
    final baseDuration = spot.estimatedDurationMinutes;

    switch (pace) {
      case 'relaxed':
        return (baseDuration * 1.5).round(); // 50% more time
      case 'packed':
        return (baseDuration * 0.7).round(); // 30% less time
      default: // moderate
        return baseDuration;
    }
  }

  // 5. System Integration and Implementation
  Future<ItineraryModel> generateItinerary({
    required List<TourSpot> availableSpots,
    required UserContext context,
    required String userId,
    String? title,
    String? description,
  }) async {
    // Apply user preferences
    var filteredSpots =
        filterByBudget(availableSpots, context.budget ?? double.infinity);
    filteredSpots = filterByInterests(filteredSpots, context.interests);

    // Apply spatial clustering and directional logic
    filteredSpots = performSpatialClustering(filteredSpots);
    filteredSpots = applyDirectionalLogic(filteredSpots, context.startTime);

    // Optimize route
    final startLocation = context.currentLocation ??
        GeoCoordinate(latitude: 10.3157, longitude: 123.8854);
    filteredSpots = optimizeRoute(filteredSpots, startLocation);

    // Generate itinerary events
    final events = <ItineraryEvent>[];
    DateTime currentTime = context.startTime
        .add(Duration(minutes: 10)); // Start after meet guide (10 mins)

    for (int i = 0; i < filteredSpots.length; i++) {
      final spot = filteredSpots[i];

      // Check if location is open at this time
      if (!isLocationOpen(spot, currentTime)) {
        continue; // Skip if closed
      }

      // For attractions, set end time to allow exploration (arrival + base duration)
      final visitDuration =
          Duration(minutes: getVisitDurationMinutes(spot, context.pace));
      final departureTime = currentTime.add(visitDuration);

      // Check if we exceed end time - be less strict to allow more spots
      if (departureTime.isAfter(context.endTime)) {
        continue; // Skip this spot but try the next ones
      }

      Duration travelTimeToNext = Duration.zero;
      double travelDistanceToNext = 0.0;

      if (i < filteredSpots.length - 1) {
        final nextSpot = filteredSpots[i + 1];

        // Use graph-based distance if available, fallback to straight-line
        final graph = CebuGraphData.getGraphNodes();
        final pathfindingService = PathfindingService();

        if (graph.containsKey(spot.id) && graph.containsKey(nextSpot.id)) {
          final pathResult = pathfindingService.findPath(
            startNodeId: spot.id,
            goalNodeId: nextSpot.id,
            graph: graph,
          );
          if (pathResult.found) {
            travelDistanceToNext = pathResult.totalDistance;
          } else {
            travelDistanceToNext =
                spot.coordinate.distanceTo(nextSpot.coordinate);
          }
        } else {
          travelDistanceToNext =
              spot.coordinate.distanceTo(nextSpot.coordinate);
        }

        final estimatedTravelTime = estimateTravelTime(travelDistanceToNext);
        travelTimeToNext = estimatedTravelTime > Duration.zero
            ? estimatedTravelTime
            : Duration(minutes: 5); // Minimum 5 minutes for travel
      }

      events.add(ItineraryEvent(
        spot: spot,
        arrivalTime: currentTime,
        departureTime: departureTime,
        travelTimeToNext: travelTimeToNext,
        travelDistanceToNext: travelDistanceToNext,
      ));

      // Move to next spot with travel time
      currentTime = departureTime.add(travelTimeToNext);
    }

    // Create a combined list for transportation and attractions
    final List<ItineraryItemModel> items = [];
    int orderCounter = 0;

    // Add tour start - meet with guide activity as first item (always 10 minutes)
    final meetGuideEndTime = context.startTime.add(Duration(minutes: 10));
    items.add(ItineraryItemModel(
      id: 'meet_guide',
      title: 'Tour Start - Meet with Guide',
      description:
          'Meet your tour guide at the starting location to begin the tour',
      type: ActivityType.attraction,
      startTime: context.startTime,
      endTime: meetGuideEndTime,
      order: orderCounter++,
    ));

    // Calculate travel from meeting point to first spot
    final userStartLocation = context.currentLocation ??
        GeoCoordinate(latitude: 10.3157, longitude: 123.8854);
    DateTime itemCurrentTime =
        meetGuideEndTime; // Track current time cumulatively for items
    if (events.isNotEmpty) {
      final firstSpot = events.first.spot;
      final distanceToFirst =
          userStartLocation.distanceTo(firstSpot.coordinate);
      final travelTimeToFirst = estimateTravelTime(distanceToFirst);

      if (travelTimeToFirst > Duration.zero) {
        final travelEndTime = meetGuideEndTime.add(travelTimeToFirst);
        itemCurrentTime = travelEndTime; // Update current time
        final etaFormatted =
            '${travelEndTime.hour.toString().padLeft(2, '0')}:${travelEndTime.minute.toString().padLeft(2, '0')}';
        items.add(ItineraryItemModel(
          id: 'trans_0',
          title: 'Travel to ${firstSpot.name}',
          description:
              'Commute via car/walking (${distanceToFirst.toStringAsFixed(1)} km, ETA: $etaFormatted)',
          type: ActivityType.transportation,
          startTime: meetGuideEndTime,
          endTime: travelEndTime,
          order: orderCounter++,
        ));
      }
    }

    for (int i = 0; i < events.length; i++) {
      final event = events[i];

      // Use cumulative current time for arrival
      final actualArrivalTime = itemCurrentTime;
      final visitDuration = event.departureTime.difference(event.arrivalTime);
      final actualDepartureTime = actualArrivalTime.add(visitDuration);

      // Attraction visit item
      items.add(ItineraryItemModel(
        id: 'spot_$i',
        title: event.spot.name,
        description: event.spot.description,
        type: ActivityType.attraction,
        startTime: actualArrivalTime,
        endTime: actualDepartureTime,
        location: event.spot.name,
        cost: event.spot.entranceFee,
        order: orderCounter++,
        metadata: {
          'travelTimeToNext': event.travelTimeToNext.inMinutes,
          'travelDistanceToNext': event.travelDistanceToNext,
          'spotId': event.spot.id,
        },
      ));

      // Transportation item to next spot (if not the last spot)
      if (i < events.length - 1) {
        final nextEvent = events[i + 1];
        final travelTime = event.travelTimeToNext > Duration.zero
            ? event.travelTimeToNext
            : Duration(minutes: 5); // Minimum 5 minutes for travel
        final travelStartTime = actualDepartureTime;
        final travelEndTime = travelStartTime.add(travelTime);
        itemCurrentTime =
            travelEndTime; // Update current time for next activity
        final etaFormatted =
            '${travelEndTime.hour.toString().padLeft(2, '0')}:${travelEndTime.minute.toString().padLeft(2, '0')}';
        items.add(ItineraryItemModel(
          id: 'trans_${i + 1}',
          title: 'Travel to ${nextEvent.spot.name}',
          description:
              'Commute via car/walking (${event.travelDistanceToNext.toStringAsFixed(1)} km, ETA: $etaFormatted)',
          type: ActivityType.transportation,
          startTime: travelStartTime,
          endTime: travelEndTime,
          order: orderCounter++,
        ));
      } else {
        // Update current time for the last activity
        itemCurrentTime = actualDepartureTime;
      }
    }

    // Add tour end activity as last item
    final lastItemEndTime =
        items.isNotEmpty ? items.last.endTime : context.startTime;
    final tourEndStartTime = lastItemEndTime.isBefore(context.endTime)
        ? lastItemEndTime
        : context.endTime.subtract(Duration(minutes: 15));
    final tourEndEndTime = tourEndStartTime.add(Duration(minutes: 15));
    items.add(ItineraryItemModel(
      id: 'tour_end',
      title: 'Tour End',
      description: 'End of the tour - thank you for joining!',
      type: ActivityType.attraction,
      startTime: tourEndStartTime,
      endTime: tourEndEndTime,
      order: orderCounter++,
    ));

    // Create itinerary model
    final itineraryId =
        'auto_itinerary_${DateTime.now().millisecondsSinceEpoch}';
    final itinerary = ItineraryModel(
      id: itineraryId,
      userId: userId,
      title: title ??
          'Auto-Generated Itinerary - ${context.startTime.toLocal().toString().split(' ')[0]}',
      description: description ??
          'Intelligent itinerary optimized for your preferences and schedule',
      startDate: context.startTime,
      endDate: context.endTime,
      status: ItineraryStatus.draft,
      items: items,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      settings: {
        'generated': true,
        'preferences': {
          'budget': context.budget,
          'interests': context.interests,
          'pace': context.pace,
        },
        'optimization': {
          'spatialClustering': true,
          'directionalLogic': true,
          'routeOptimization': true,
        },
      },
    );

    return itinerary;
  }
}
