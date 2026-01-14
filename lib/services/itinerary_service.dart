import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tourmate_app/models/itinerary_model.dart';
import 'package:tourmate_app/models/booking_model.dart';
import 'package:tourmate_app/models/tour_model.dart';

class ItineraryService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // CRUD Operations
  Future<void> createItinerary(ItineraryModel itinerary) async {
    final itineraryData = itinerary.toMap();
    itineraryData['createdAt'] = FieldValue.serverTimestamp();
    itineraryData['updatedAt'] = FieldValue.serverTimestamp();

    await _db.collection('itineraries').doc(itinerary.id).set(itineraryData);
  }

  Future<ItineraryModel?> getItinerary(String itineraryId) async {
    final doc = await _db.collection('itineraries').doc(itineraryId).get();
    if (doc.exists) {
      return ItineraryModel.fromMap(doc.data()!);
    }
    return null;
  }

  Future<List<ItineraryModel>> getUserItineraries(String userId) async {
    final snapshot = await _db
        .collection('itineraries')
        .where('userId', isEqualTo: userId)
        .orderBy('updatedAt', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => ItineraryModel.fromMap(doc.data()))
        .toList();
  }

  Future<void> updateItinerary(ItineraryModel itinerary) async {
    final updateData = itinerary.toMap();
    updateData['updatedAt'] = FieldValue.serverTimestamp();

    await _db.collection('itineraries').doc(itinerary.id).update(updateData);
  }

  Future<void> deleteItinerary(String itineraryId) async {
    await _db.collection('itineraries').doc(itineraryId).delete();
  }

  // --- ADD THIS NEW METHOD ---
  Future<ItineraryModel> getOrGenerateItinerary(
      BookingModel booking, TourModel tour) async {
    final itineraryId = 'itinerary_${booking.id}';

    // 1. Check if the itinerary already exists in the database
    final doc = await _db.collection('itineraries').doc(itineraryId).get();

    if (doc.exists && doc.data() != null) {
      // Return the EXISTING saved itinerary (with your edits)
      return ItineraryModel.fromMap(doc.data()!);
    }

    // 2. If it truly doesn't exist, ONLY THEN generate a new one
    return await generateItineraryFromBooking(booking, tour);
  }
  // ---------------------------

  // Auto-generate itinerary from booking
  Future<ItineraryModel> generateItineraryFromBooking(
      BookingModel booking, TourModel tour) async {
    final itineraryId = 'itinerary_${booking.id}';
    final now = DateTime.now();

    // Try to use the tour's itinerary data first, fallback to generated items
    final items = tour.itinerary.isNotEmpty
        ? _convertTourItineraryToItems(tour.itinerary, booking.tourStartDate)
        : await _generateItineraryItems(tour, booking);

    final itinerary = ItineraryModel(
      id: itineraryId,
      userId: booking.touristId,
      title:
          '${tour.title} - ${booking.tourStartDate.toLocal().toString().split(' ')[0]}',
      description: 'Itinerary for your ${tour.title} tour',
      startDate: booking.tourStartDate,
      endDate:
          booking.tourStartDate.add(tour.endTime.difference(tour.startTime)),
      status: ItineraryStatus.draft,
      items: items,
      createdAt: now,
      updatedAt: now,
      relatedBookingId: booking.id,
      relatedTourId: tour.id,
    );

    await createItinerary(itinerary);
    return itinerary;
  }

  // Convert tour's itinerary data to ItineraryItemModel list
  List<ItineraryItemModel> _convertTourItineraryToItems(
      List<Map<String, String>> tourItinerary, DateTime startDate) {
    final items = <ItineraryItemModel>[];

    for (int i = 0; i < tourItinerary.length; i++) {
      final item = tourItinerary[i];
      final title = item['title'] ?? item['activity'] ?? 'Activity ${i + 1}';
      final description = item['description'] ?? item['details'] ?? '';
      final time = item['time'] ?? item['startTime'] ?? '';
      final duration = item['duration'] ?? '60'; // Default 60 minutes

      // Parse time and create start/end times
      DateTime startTime = startDate;
      DateTime endTime = startDate;

      try {
        if (time.isNotEmpty) {
          // Try to parse time like "9:00 AM" or "14:00"
          final timeParts = time.split(':');
          if (timeParts.length >= 2) {
            int hour = int.tryParse(timeParts[0]) ?? 9;
            int minute = int.tryParse(timeParts[1].split(' ')[0]) ?? 0;

            // Handle AM/PM
            if (time.toUpperCase().contains('PM') && hour != 12) {
              hour += 12;
            } else if (time.toUpperCase().contains('AM') && hour == 12) {
              hour = 0;
            }

            startTime = DateTime(
                startDate.year, startDate.month, startDate.day, hour, minute);
            endTime =
                startTime.add(Duration(minutes: int.tryParse(duration) ?? 60));
          }
        }
      } catch (e) {
        // If parsing fails, use default times
        startTime = startDate.add(Duration(hours: i));
        endTime = startTime.add(const Duration(hours: 1));
      }

      // Determine activity type based on content
      ActivityType type = ActivityType.tour;
      final lowerTitle = title.toLowerCase();
      final lowerDesc = description.toLowerCase();

      if (lowerTitle.contains('lunch') ||
          lowerTitle.contains('dinner') ||
          lowerTitle.contains('breakfast') ||
          lowerTitle.contains('meal') ||
          lowerDesc.contains('eat') ||
          lowerDesc.contains('food')) {
        type = ActivityType.meal;
      } else if (lowerTitle.contains('transport') ||
          lowerTitle.contains('pickup') ||
          lowerTitle.contains('transfer') ||
          lowerDesc.contains('transport')) {
        type = ActivityType.transportation;
      } else if (lowerTitle.contains('hotel') ||
          lowerTitle.contains('accommodation') ||
          lowerDesc.contains('check-in') ||
          lowerDesc.contains('stay')) {
        type = ActivityType.accommodation;
      } else if (lowerTitle.contains('visit') ||
          lowerTitle.contains('sightseeing') ||
          lowerDesc.contains('explore') ||
          lowerDesc.contains('see')) {
        type = ActivityType.attraction;
      } else if (lowerTitle.contains('shopping') ||
          lowerDesc.contains('shop')) {
        type = ActivityType.shopping;
      } else if (lowerTitle.contains('rest') ||
          lowerTitle.contains('break') ||
          lowerDesc.contains('relax')) {
        type = ActivityType.rest;
      }

      items.add(ItineraryItemModel(
        id: 'item_${i}',
        title: title,
        description: description,
        type: type,
        startTime: startTime,
        endTime: endTime,
        location: item['location'] ?? item['place'] ?? '',
        order: i,
      ));
    }

    return items;
  }

  // Generate itinerary items based on tour details
  Future<List<ItineraryItemModel>> _generateItineraryItems(
      TourModel tour, BookingModel booking) async {
    final items = <ItineraryItemModel>[];
    final startTime = booking.tourStartDate;
    int order = 0;

    // Welcome/Meeting point
    items.add(ItineraryItemModel(
      id: 'item_${order++}',
      title: 'Meet Your Guide',
      description: 'Meet your tour guide at the designated meeting point',
      type: ActivityType.tour,
      startTime: startTime,
      endTime: startTime.add(const Duration(minutes: 15)),
      location: tour.meetingPoint,
      order: order - 1,
    ));

    // Generate activities based on tour category
    final categoryActivities = _getActivitiesForCategory(
        tour.category.isNotEmpty ? tour.category[0] : 'General', startTime);

    for (final activity in categoryActivities) {
      items.add(ItineraryItemModel(
        id: 'item_${order++}',
        title: activity['title']!,
        description: activity['description']!,
        type: activity['type']!,
        startTime: activity['startTime']!,
        endTime: activity['endTime']!,
        location: tour.meetingPoint,
        cost: activity['cost'],
        order: order - 1,
      ));
    }

    // Transportation back (if applicable)
    if (!tour.category.contains('Walking') &&
        !tour.category.contains('Hiking')) {
      final endTime = startTime.add(tour.endTime.difference(tour.startTime));
      items.add(ItineraryItemModel(
        id: 'item_${order++}',
        title: 'Return Transportation',
        description:
            'Transportation back to starting point or your accommodation',
        type: ActivityType.transportation,
        startTime: endTime.subtract(const Duration(minutes: 30)),
        endTime: endTime,
        location: tour.meetingPoint,
        order: order - 1,
      ));
    }

    return items;
  }

  List<Map<String, dynamic>> _getActivitiesForCategory(
      String category, DateTime startTime) {
    switch (category.toLowerCase()) {
      case 'food':
      case 'culinary':
        return [
          {
            'title': 'Local Market Visit',
            'description':
                'Explore the local market and learn about fresh ingredients',
            'type': ActivityType.attraction,
            'startTime': startTime.add(const Duration(minutes: 15)),
            'endTime': startTime.add(const Duration(hours: 1)),
            'cost': 0.0,
          },
          {
            'title': 'Cooking Demonstration',
            'description': 'Watch a local chef prepare traditional dishes',
            'type': ActivityType.tour,
            'startTime': startTime.add(const Duration(hours: 1, minutes: 15)),
            'endTime': startTime.add(const Duration(hours: 2, minutes: 15)),
            'cost': 25.0,
          },
          {
            'title': 'Traditional Lunch',
            'description':
                'Enjoy an authentic local meal with traditional dishes',
            'type': ActivityType.meal,
            'startTime': startTime.add(const Duration(hours: 2, minutes: 30)),
            'endTime': startTime.add(const Duration(hours: 3, minutes: 30)),
            'cost': 15.0,
          },
        ];

      case 'hiking':
      case 'adventure':
        return [
          {
            'title': 'Safety Briefing',
            'description': 'Important safety instructions and equipment check',
            'type': ActivityType.tour,
            'startTime': startTime.add(const Duration(minutes: 15)),
            'endTime': startTime.add(const Duration(minutes: 30)),
            'cost': 0.0,
          },
          {
            'title': 'Guided Hike',
            'description':
                'Scenic hike through beautiful trails with experienced guide',
            'type': ActivityType.tour,
            'startTime': startTime.add(const Duration(minutes: 30)),
            'endTime': startTime.add(const Duration(hours: 2, minutes: 30)),
            'cost': 0.0,
          },
          {
            'title': 'Summit Lunch',
            'description': 'Picnic lunch with stunning views',
            'type': ActivityType.meal,
            'startTime': startTime.add(const Duration(hours: 2, minutes: 45)),
            'endTime': startTime.add(const Duration(hours: 3, minutes: 45)),
            'cost': 12.0,
          },
        ];

      case 'heritage':
      case 'historical':
      case 'culture':
        return [
          {
            'title': 'Historical Site Visit',
            'description':
                'Explore significant historical landmarks and learn about local history',
            'type': ActivityType.attraction,
            'startTime': startTime.add(const Duration(minutes: 15)),
            'endTime': startTime.add(const Duration(hours: 1, minutes: 15)),
            'cost': 8.0,
          },
          {
            'title': 'Cultural Performance',
            'description':
                'Experience traditional music, dance, or cultural demonstrations',
            'type': ActivityType.tour,
            'startTime': startTime.add(const Duration(hours: 1, minutes: 30)),
            'endTime': startTime.add(const Duration(hours: 2, minutes: 30)),
            'cost': 15.0,
          },
          {
            'title': 'Heritage Lunch',
            'description':
                'Traditional meal at a heritage site or cultural restaurant',
            'type': ActivityType.meal,
            'startTime': startTime.add(const Duration(hours: 2, minutes: 45)),
            'endTime': startTime.add(const Duration(hours: 3, minutes: 45)),
            'cost': 18.0,
          },
        ];

      default:
        return [
          {
            'title': 'Guided Tour',
            'description': 'Comprehensive guided tour of the area',
            'type': ActivityType.tour,
            'startTime': startTime.add(const Duration(minutes: 15)),
            'endTime': startTime.add(const Duration(hours: 2, minutes: 15)),
            'cost': 0.0,
          },
          {
            'title': 'Local Experience',
            'description': 'Immerse yourself in local culture and activities',
            'type': ActivityType.attraction,
            'startTime': startTime.add(const Duration(hours: 2, minutes: 30)),
            'endTime': startTime.add(const Duration(hours: 3, minutes: 30)),
            'cost': 10.0,
          },
        ];
    }
  }

  // Add custom activity to itinerary
  Future<void> addActivityToItinerary(
      String itineraryId, ItineraryItemModel activity) async {
    final itineraryRef = _db.collection('itineraries').doc(itineraryId);
    final itineraryDoc = await itineraryRef.get();

    if (itineraryDoc.exists) {
      final itinerary = ItineraryModel.fromMap(itineraryDoc.data()!);
      final updatedItems = [...itinerary.items, activity];

      await itineraryRef.update({
        'items': updatedItems.map((item) => item.toMap()).toList(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  // Update activity in itinerary
  Future<void> updateActivityInItinerary(
      String itineraryId, ItineraryItemModel updatedActivity) async {
    final itineraryRef = _db.collection('itineraries').doc(itineraryId);
    final itineraryDoc = await itineraryRef.get();

    if (itineraryDoc.exists) {
      final itinerary = ItineraryModel.fromMap(itineraryDoc.data()!);
      final updatedItems = itinerary.items.map((item) {
        return item.id == updatedActivity.id ? updatedActivity : item;
      }).toList();

      await itineraryRef.update({
        'items': updatedItems.map((item) => item.toMap()).toList(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  // Remove activity from itinerary
  Future<void> removeActivityFromItinerary(
      String itineraryId, String activityId) async {
    final itineraryRef = _db.collection('itineraries').doc(itineraryId);
    final itineraryDoc = await itineraryRef.get();

    if (itineraryDoc.exists) {
      final itinerary = ItineraryModel.fromMap(itineraryDoc.data()!);
      final updatedItems =
          itinerary.items.where((item) => item.id != activityId).toList();

      await itineraryRef.update({
        'items': updatedItems.map((item) => item.toMap()).toList(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  // Reorder activities
  Future<void> reorderActivities(
      String itineraryId, List<ItineraryItemModel> reorderedItems) async {
    // Update order property for each item
    for (int i = 0; i < reorderedItems.length; i++) {
      reorderedItems[i] = ItineraryItemModel(
        id: reorderedItems[i].id,
        title: reorderedItems[i].title,
        description: reorderedItems[i].description,
        type: reorderedItems[i].type,
        startTime: reorderedItems[i].startTime,
        endTime: reorderedItems[i].endTime,
        location: reorderedItems[i].location,
        address: reorderedItems[i].address,
        cost: reorderedItems[i].cost,
        notes: reorderedItems[i].notes,
        imageUrl: reorderedItems[i].imageUrl,
        isCompleted: reorderedItems[i].isCompleted,
        order: i,
        metadata: reorderedItems[i].metadata,
      );
    }

    await _db.collection('itineraries').doc(itineraryId).update({
      'items': reorderedItems.map((item) => item.toMap()).toList(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Mark activity as completed
  Future<void> toggleActivityCompletion(
      String itineraryId, String activityId, bool isCompleted) async {
    final itineraryRef = _db.collection('itineraries').doc(itineraryId);
    final itineraryDoc = await itineraryRef.get();

    if (itineraryDoc.exists) {
      final itinerary = ItineraryModel.fromMap(itineraryDoc.data()!);
      final updatedItems = itinerary.items.map((item) {
        if (item.id == activityId) {
          return ItineraryItemModel(
            id: item.id,
            title: item.title,
            description: item.description,
            type: item.type,
            startTime: item.startTime,
            endTime: item.endTime,
            location: item.location,
            address: item.address,
            cost: item.cost,
            notes: item.notes,
            imageUrl: item.imageUrl,
            isCompleted: isCompleted,
            order: item.order,
            metadata: item.metadata,
          );
        }
        return item;
      }).toList();

      await itineraryRef.update({
        'items': updatedItems.map((item) => item.toMap()).toList(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  // Share itinerary
  Future<String> shareItinerary(String itineraryId) async {
    final itineraryRef = _db.collection('itineraries').doc(itineraryId);
    final itineraryDoc = await itineraryRef.get();

    if (itineraryDoc.exists) {
      final itinerary = ItineraryModel.fromMap(itineraryDoc.data()!);
      final shareCode = itinerary.generateShareCode();

      await itineraryRef.update({
        'isPublic': true,
        'shareCode': shareCode,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return shareCode;
    }

    throw Exception('Itinerary not found');
  }

  // Get shared itinerary by code
  Future<ItineraryModel?> getSharedItinerary(String shareCode) async {
    final snapshot = await _db
        .collection('itineraries')
        .where('shareCode', isEqualTo: shareCode)
        .where('isPublic', isEqualTo: true)
        .limit(1)
        .get();

    if (snapshot.docs.isNotEmpty) {
      return ItineraryModel.fromMap(snapshot.docs.first.data());
    }

    return null;
  }

  // Get activity suggestions based on location/category
  List<Map<String, dynamic>> getActivitySuggestions(
      String location, String category) {
    // This would typically fetch from a database of activities
    // For now, return mock suggestions
    return [
      {
        'title': 'Visit Local Market',
        'description': 'Explore fresh produce and local crafts',
        'type': ActivityType.shopping,
        'estimatedDuration': 90, // minutes
        'estimatedCost': 0.0,
      },
      {
        'title': 'Traditional Restaurant',
        'description': 'Authentic local cuisine experience',
        'type': ActivityType.meal,
        'estimatedDuration': 60,
        'estimatedCost': 15.0,
      },
      {
        'title': 'Photography Tour',
        'description': 'Capture the best spots in the area',
        'type': ActivityType.attraction,
        'estimatedDuration': 120,
        'estimatedCost': 20.0,
      },
    ];
  }
}
