class TourModel {
  final String id;
  final String title;
  final String description;
  final double price;
  final List<String> category;
  final int maxParticipants;
  final int currentParticipants;
  final DateTime startTime;
  final DateTime endTime;
  final String meetingPoint;
  final List<String> mediaURL;
  final String createdBy;
  final bool shared;
  final List<Map<String, String>> itinerary;
  final String status;
  final int duration;
  final List<String> languages;
  final List<String> specializations;
  final List<String> highlights;

  TourModel({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.category,
    required this.maxParticipants,
    required this.currentParticipants,
    required this.startTime,
    required this.endTime,
    required this.meetingPoint,
    required this.mediaURL,
    required this.createdBy,
    required this.shared,
    required this.itinerary,
    required this.status,
    required this.duration,
    required this.languages,
    required this.specializations,
    required this.highlights,
  });

  factory TourModel.fromMap(Map<String, dynamic> data) {
    return TourModel(
      id: data['id'],
      title: data['title'],
      description: data['description'],
      price: data['price'],
      category: List<String>.from(data['category'] ?? []),
      maxParticipants: data['maxParticipants'],
      currentParticipants: data['currentParticipants'],
      startTime: data['startTime'].toDate(),
      endTime: data['endTime'].toDate(),
      meetingPoint: data['meetingPoint'],
      mediaURL: List<String>.from(data['mediaURL'] ?? data['media'] ?? []),
      createdBy: data['createdBy'],
      shared: data['shared'],
      itinerary: List<Map<String, String>>.from(data['itinerary']),
      status: data['status'],
      duration: (data['duration'] is int)
          ? data['duration']
          : int.tryParse(data['duration']?.toString() ?? '0') ?? 0,
      languages: List<String>.from(data['languages'] ?? []),
      specializations: List<String>.from(data['specializations'] ?? []),
      highlights: List<String>.from(data['highlights'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'price': price,
      'category': category,
      'maxParticipants': maxParticipants,
      'currentParticipants': currentParticipants,
      'startTime': startTime,
      'endTime': endTime,
      'meetingPoint': meetingPoint,
      'mediaURL': mediaURL,
      'createdBy': createdBy,
      'shared': shared,
      'itinerary': itinerary,
      'status': status,
      'duration': duration,
      'languages': languages,
      'specializations': specializations,
      'highlights': highlights,
    };
  }

  TourModel copyWith({
    String? id,
    String? title,
    String? description,
    double? price,
    List<String>? category,
    int? maxParticipants,
    int? currentParticipants,
    DateTime? startTime,
    DateTime? endTime,
    String? meetingPoint,
    List<String>? mediaURL,
    String? createdBy,
    bool? shared,
    List<Map<String, String>>? itinerary,
    String? status,
    int? duration,
    List<String>? languages,
    List<String>? specializations,
    List<String>? highlights,
  }) {
    return TourModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      price: price ?? this.price,
      category: category ?? this.category,
      maxParticipants: maxParticipants ?? this.maxParticipants,
      currentParticipants: currentParticipants ?? this.currentParticipants,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      meetingPoint: meetingPoint ?? this.meetingPoint,
      mediaURL: mediaURL ?? this.mediaURL,
      createdBy: createdBy ?? this.createdBy,
      shared: shared ?? this.shared,
      itinerary: itinerary ?? this.itinerary,
      status: status ?? this.status,
      duration: duration ?? this.duration,
      languages: languages ?? this.languages,
      specializations: specializations ?? this.specializations,
      highlights: highlights ?? this.highlights,
    );
  }
}
