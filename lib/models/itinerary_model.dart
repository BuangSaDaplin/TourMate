import 'package:flutter/material.dart';

enum ItineraryStatus {
  draft,      // Being created/edited
  published,  // Shared or finalized
  completed,  // Trip completed
  archived,   // No longer active
}

enum ActivityType {
  tour,           // Official tour activity
  transportation, // Travel between locations
  accommodation,  // Hotel/rest stay
  meal,          // Dining/breakfast/lunch/dinner
  attraction,    // Visit landmark/museum/etc
  shopping,      // Shopping activity
  rest,          // Free time/relaxation
  custom,        // User-defined activity
}

class ItineraryItemModel {
  final String id;
  final String title;
  final String description;
  final ActivityType type;
  final DateTime startTime;
  final DateTime endTime;
  final String? location;
  final String? address;
  final double? cost;
  final String? notes;
  final String? imageUrl;
  final bool isCompleted;
  final int order; // For sorting/reordering
  final Map<String, dynamic>? metadata; // Additional data like contact info, reservations, etc.

  ItineraryItemModel({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.startTime,
    required this.endTime,
    this.location,
    this.address,
    this.cost,
    this.notes,
    this.imageUrl,
    this.isCompleted = false,
    required this.order,
    this.metadata,
  });

  factory ItineraryItemModel.fromMap(Map<String, dynamic> data) {
    return ItineraryItemModel(
      id: data['id'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      type: ActivityType.values[data['type'] ?? 0],
      startTime: DateTime.parse(data['startTime']),
      endTime: DateTime.parse(data['endTime']),
      location: data['location'],
      address: data['address'],
      cost: data['cost']?.toDouble(),
      notes: data['notes'],
      imageUrl: data['imageUrl'],
      isCompleted: data['isCompleted'] ?? false,
      order: data['order'] ?? 0,
      metadata: data['metadata'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'type': type.index,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'location': location,
      'address': address,
      'cost': cost,
      'notes': notes,
      'imageUrl': imageUrl,
      'isCompleted': isCompleted,
      'order': order,
      'metadata': metadata,
    };
  }

  Duration get duration => endTime.difference(startTime);

  String get durationText {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }

  Color get typeColor {
    switch (type) {
      case ActivityType.tour:
        return const Color(0xFF2196F3); // Blue
      case ActivityType.transportation:
        return const Color(0xFF4CAF50); // Green
      case ActivityType.accommodation:
        return const Color(0xFFFF9800); // Orange
      case ActivityType.meal:
        return const Color(0xFFE91E63); // Pink
      case ActivityType.attraction:
        return const Color(0xFF9C27B0); // Purple
      case ActivityType.shopping:
        return const Color(0xFF795548); // Brown
      case ActivityType.rest:
        return const Color(0xFF607D8B); // Blue Grey
      case ActivityType.custom:
        return const Color(0xFF00BCD4); // Cyan
    }
  }

  IconData get typeIcon {
    switch (type) {
      case ActivityType.tour:
        return Icons.tour;
      case ActivityType.transportation:
        return Icons.directions_car;
      case ActivityType.accommodation:
        return Icons.hotel;
      case ActivityType.meal:
        return Icons.restaurant;
      case ActivityType.attraction:
        return Icons.camera_alt;
      case ActivityType.shopping:
        return Icons.shopping_bag;
      case ActivityType.rest:
        return Icons.beach_access;
      case ActivityType.custom:
        return Icons.star;
    }
  }

  String get typeDisplayName {
    switch (type) {
      case ActivityType.tour:
        return 'Tour';
      case ActivityType.transportation:
        return 'Transportation';
      case ActivityType.accommodation:
        return 'Accommodation';
      case ActivityType.meal:
        return 'Meal';
      case ActivityType.attraction:
        return 'Attraction';
      case ActivityType.shopping:
        return 'Shopping';
      case ActivityType.rest:
        return 'Rest';
      case ActivityType.custom:
        return 'Custom';
    }
  }
}

class ItineraryModel {
  final String id;
  final String userId; // Tourist who owns this itinerary
  final String title;
  final String description;
  final DateTime startDate;
  final DateTime endDate;
  final ItineraryStatus status;
  final List<ItineraryItemModel> items;
  final String? coverImageUrl;
  final bool isPublic; // Can be shared/viewed by others
  final String? shareCode; // Unique code for sharing
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? relatedBookingId; // If generated from a booking
  final String? relatedTourId; // If generated from a tour
  final Map<String, dynamic>? settings; // User preferences, notifications, etc.

  ItineraryModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.description,
    required this.startDate,
    required this.endDate,
    this.status = ItineraryStatus.draft,
    this.items = const [],
    this.coverImageUrl,
    this.isPublic = false,
    this.shareCode,
    required this.createdAt,
    required this.updatedAt,
    this.relatedBookingId,
    this.relatedTourId,
    this.settings,
  });

  factory ItineraryModel.fromMap(Map<String, dynamic> data) {
    return ItineraryModel(
      id: data['id'] ?? '',
      userId: data['userId'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      startDate: DateTime.parse(data['startDate']),
      endDate: DateTime.parse(data['endDate']),
      status: ItineraryStatus.values[data['status'] ?? 0],
      items: (data['items'] as List<dynamic>?)
          ?.map((item) => ItineraryItemModel.fromMap(item))
          .toList() ?? [],
      coverImageUrl: data['coverImageUrl'],
      isPublic: data['isPublic'] ?? false,
      shareCode: data['shareCode'],
      createdAt: DateTime.parse(data['createdAt']),
      updatedAt: DateTime.parse(data['updatedAt']),
      relatedBookingId: data['relatedBookingId'],
      relatedTourId: data['relatedTourId'],
      settings: data['settings'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'description': description,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'status': status.index,
      'items': items.map((item) => item.toMap()).toList(),
      'coverImageUrl': coverImageUrl,
      'isPublic': isPublic,
      'shareCode': shareCode,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'relatedBookingId': relatedBookingId,
      'relatedTourId': relatedTourId,
      'settings': settings,
    };
  }

  // Helper methods
  int get totalDays => endDate.difference(startDate).inDays + 1;

  double get totalCost => items.fold(0, (sum, item) => sum + (item.cost ?? 0));

  List<ItineraryItemModel> getItemsForDate(DateTime date) {
    return items.where((item) {
      final itemDate = DateTime(item.startTime.year, item.startTime.month, item.startTime.day);
      final targetDate = DateTime(date.year, date.month, date.day);
      return itemDate.isAtSameMomentAs(targetDate);
    }).toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
  }

  List<ItineraryItemModel> get completedItems => items.where((item) => item.isCompleted).toList();

  List<ItineraryItemModel> get pendingItems => items.where((item) => !item.isCompleted).toList();

  double get completionPercentage {
    if (items.isEmpty) return 0;
    return (completedItems.length / items.length) * 100;
  }

  bool get isUpcoming => startDate.isAfter(DateTime.now());
  bool get isOngoing => startDate.isBefore(DateTime.now()) && endDate.isAfter(DateTime.now());
  bool get isCompleted => endDate.isBefore(DateTime.now());

  // Generate share URL
  String get shareUrl => 'https://tourmate.app/itinerary/$shareCode';

  // Auto-generate share code if not exists
  String generateShareCode() {
    if (shareCode != null) return shareCode!;
    // Simple share code generation (in production, use more secure method)
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final code = '${id.substring(0, 8)}${timestamp.substring(timestamp.length - 4)}';
    return code.toUpperCase();
  }
}
