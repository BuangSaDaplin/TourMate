import 'package:flutter/material.dart';

enum BookingStatus {
  pending, // Initial booking, waiting for guide approval
  confirmed, // Guide accepted, payment pending
  paid, // Payment completed, booking active
  inProgress, // Tour is currently happening
  completed, // Tour completed successfully
  cancelled, // Cancelled by tourist or guide
  rejected, // Guide rejected the booking
  refunded, // Payment refunded
}

enum ReviewSubmissionStatus {
  submitted, // 0 = submitted
  moderated, // 1 = moderated
}

class BookingModel {
  final String tourTitle;
  final String id;
  final String tourId;
  final String touristId;
  final String? guideId; // Guide who owns the tour
  final String? itineraryId; // Reference to the itinerary for this booking
  final DateTime bookingDate;
  final DateTime tourStartDate;
  final int numberOfParticipants;
  final double totalPrice;
  final BookingStatus status;
  final String? specialRequests;
  final String? cancellationReason;
  final DateTime? cancelledAt;
  final DateTime? confirmedAt;
  final DateTime? paidAt;
  final DateTime? completedAt;
  final Map<String, dynamic>? paymentDetails;
  final List<String>? participantNames;
  final String? contactNumber;
  final String? emergencyContact;
  final int? duration;

  // Review fields
  final String? reviewContent;
  final double? rating;
  final DateTime? reviewCreatedAt;
  final String? reviewerId;
  final String? reviewerName;
  final DateTime? reviewModeratedAt;
  final String? reviewModerateReason;
  final ReviewSubmissionStatus? reviewStatus;

  BookingModel({
    required this.tourTitle,
    required this.id,
    required this.tourId,
    required this.touristId,
    this.guideId,
    this.itineraryId,
    required this.bookingDate,
    required this.tourStartDate,
    required this.numberOfParticipants,
    required this.totalPrice,
    this.status = BookingStatus.pending,
    this.specialRequests,
    this.cancellationReason,
    this.cancelledAt,
    this.confirmedAt,
    this.paidAt,
    this.completedAt,
    this.paymentDetails,
    this.participantNames,
    this.contactNumber,
    this.emergencyContact,
    this.duration,
    this.reviewContent,
    this.rating,
    this.reviewCreatedAt,
    this.reviewerId,
    this.reviewerName,
    this.reviewModeratedAt,
    this.reviewModerateReason,
    this.reviewStatus,
  });

  factory BookingModel.fromMap(Map<String, dynamic> data) {
    return BookingModel(
      tourTitle: data['tourTitle'],
      id: data['id'],
      tourId: data['tourId'],
      touristId: data['touristId'],
      guideId: data['guideId'],
      itineraryId: data['itineraryId'],
      bookingDate: data['bookingDate'].toDate(),
      tourStartDate: data['tourStartDate'].toDate(),
      numberOfParticipants: data['numberOfParticipants'],
      totalPrice: data['totalPrice'].toDouble(),
      status: BookingStatus.values[data['status'] ?? 0],
      specialRequests: data['specialRequests'],
      cancellationReason: data['cancellationReason'],
      cancelledAt: data['cancelledAt']?.toDate(),
      confirmedAt: data['confirmedAt']?.toDate(),
      paidAt: data['paidAt']?.toDate(),
      completedAt: data['completedAt']?.toDate(),
      paymentDetails: data['paymentDetails'],
      participantNames: List<String>.from(data['participantNames'] ?? []),
      contactNumber: data['contactNumber'],
      emergencyContact: data['emergencyContact'],
      duration: data['duration'] as int?,
      reviewContent: data['reviewContent'],
      rating: data['rating']?.toDouble(),
      reviewCreatedAt: data['reviewCreatedAt']?.toDate(),
      reviewerId: data['reviewerId'],
      reviewerName: data['reviewerName'],
      reviewModeratedAt: data['reviewModeratedAt']?.toDate(),
      reviewModerateReason: data['reviewModerateReason'],
      reviewStatus: data['reviewStatus'] != null
          ? ReviewSubmissionStatus.values[data['reviewStatus']]
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'tourTitle': tourTitle,
      'id': id,
      'tourId': tourId,
      'touristId': touristId,
      'guideId': guideId,
      'itineraryId': itineraryId,
      'bookingDate': bookingDate,
      'tourStartDate': tourStartDate,
      'numberOfParticipants': numberOfParticipants,
      'totalPrice': totalPrice,
      'status': status.index,
      'specialRequests': specialRequests,
      'cancellationReason': cancellationReason,
      'cancelledAt': cancelledAt,
      'confirmedAt': confirmedAt,
      'paidAt': paidAt,
      'completedAt': completedAt,
      'paymentDetails': paymentDetails,
      'participantNames': participantNames,
      'contactNumber': contactNumber,
      'emergencyContact': emergencyContact,
      'duration': duration,
      'reviewContent': reviewContent,
      'rating': rating,
      'reviewCreatedAt': reviewCreatedAt,
      'reviewerId': reviewerId,
      'reviewerName': reviewerName,
      'reviewModeratedAt': reviewModeratedAt,
      'reviewModerateReason': reviewModerateReason,
      'reviewStatus': reviewStatus?.index,
    };
  }

  // Helper methods
  bool get isUpcoming => tourStartDate.isAfter(DateTime.now()) && !isCancelled;
  bool get isPast =>
      tourStartDate.isBefore(DateTime.now()) ||
      status == BookingStatus.completed;
  bool get isActive =>
      status == BookingStatus.confirmed ||
      status == BookingStatus.paid ||
      status == BookingStatus.inProgress;
  bool get isCancelled =>
      status == BookingStatus.cancelled || status == BookingStatus.rejected;
  bool get canCancel =>
      status == BookingStatus.pending || status == BookingStatus.confirmed;
  bool get canModify =>
      status == BookingStatus.pending || status == BookingStatus.confirmed;
  bool get requiresPayment => status == BookingStatus.confirmed;

  String get statusDisplayText {
    switch (status) {
      case BookingStatus.pending:
        return 'Pending Approval';
      case BookingStatus.confirmed:
        return 'Confirmed - Payment Required';
      case BookingStatus.paid:
        return 'Paid - Ready to Go';
      case BookingStatus.inProgress:
        return 'Tour in Progress';
      case BookingStatus.completed:
        return 'Completed';
      case BookingStatus.cancelled:
        return 'Cancelled';
      case BookingStatus.rejected:
        return 'Rejected';
      case BookingStatus.refunded:
        return 'Refunded';
    }
  }

  Color get statusColor {
    switch (status) {
      case BookingStatus.pending:
        return const Color(0xFFFFA726); // Orange
      case BookingStatus.confirmed:
        return const Color(0xFF42A5F5); // Blue
      case BookingStatus.paid:
        return const Color(0xFF66BB6A); // Green
      case BookingStatus.inProgress:
        return const Color(0xFF26A69A); // Teal
      case BookingStatus.completed:
        return const Color(0xFF4CAF50); // Dark Green
      case BookingStatus.cancelled:
      case BookingStatus.rejected:
        return const Color(0xFFE53935); // Red
      case BookingStatus.refunded:
        return const Color(0xFF8D6E63); // Brown
    }
  }
}
