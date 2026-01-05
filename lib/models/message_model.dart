import 'package:flutter/material.dart';

enum MessageType {
  text,
  image,
  file,
  system, // For automated messages like booking confirmations
  itinerary, // For sharing itinerary cards
}

enum MessageStatus {
  sending,
  sent,
  delivered,
  read,
  failed,
}

class MessageModel {
  final String id;
  final String chatRoomId;
  final String senderId;
  final String senderName;
  final String senderRole; // 'Tourist', 'Tour Guide', 'Admin'
  final String content;
  final MessageType type;
  final MessageStatus status;
  final DateTime timestamp;
  final String? imageUrl;
  final String? fileUrl;
  final String? fileName;
  final bool isRead;
  final List<String> readBy; // List of user IDs who have read this message
  // Itinerary sharing fields
  final String? itineraryId;
  final String? tourName;
  final DateTime? bookingDate;

  MessageModel({
    required this.id,
    required this.chatRoomId,
    required this.senderId,
    required this.senderName,
    required this.senderRole,
    required this.content,
    this.type = MessageType.text,
    this.status = MessageStatus.sent,
    required this.timestamp,
    this.imageUrl,
    this.fileUrl,
    this.fileName,
    this.isRead = false,
    this.readBy = const [],
    this.itineraryId,
    this.tourName,
    this.bookingDate,
  });

  factory MessageModel.fromMap(Map<String, dynamic> data) {
    return MessageModel(
      id: data['id'] ?? '',
      chatRoomId: data['chatRoomId'] ?? '',
      senderId: data['senderId'] ?? '',
      senderName: data['senderName'] ?? 'Unknown',
      senderRole: data['senderRole'] ?? 'Tourist',
      content: data['content'] ?? '',
      type: MessageType.values[data['type'] ?? 0],
      status: MessageStatus.values[data['status'] ?? 1], // Default to sent
      timestamp: data['timestamp']?.toDate() ?? DateTime.now(),
      imageUrl: data['imageUrl'],
      fileUrl: data['fileUrl'],
      fileName: data['fileName'],
      isRead: data['isRead'] ?? false,
      readBy: List<String>.from(data['readBy'] ?? []),
      itineraryId: data['itineraryId'],
      tourName: data['tourName'],
      bookingDate: data['bookingDate']?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'chatRoomId': chatRoomId,
      'senderId': senderId,
      'senderName': senderName,
      'senderRole': senderRole,
      'content': content,
      'type': type.index,
      'status': status.index,
      'timestamp': timestamp,
      'imageUrl': imageUrl,
      'fileUrl': fileUrl,
      'fileName': fileName,
      'isRead': isRead,
      'readBy': readBy,
      'itineraryId': itineraryId,
      'tourName': tourName,
      'bookingDate': bookingDate,
    };
  }

  // Helper methods
  bool get isFromCurrentUser =>
      false; // Will be set by UI based on current user
  bool get isImage => type == MessageType.image;
  bool get isFile => type == MessageType.file;
  bool get isSystem => type == MessageType.system;
  bool get isItinerary => type == MessageType.itinerary;

  String get statusText {
    switch (status) {
      case MessageStatus.sending:
        return 'Sending...';
      case MessageStatus.sent:
        return 'Sent';
      case MessageStatus.delivered:
        return 'Delivered';
      case MessageStatus.read:
        return 'Read';
      case MessageStatus.failed:
        return 'Failed to send';
    }
  }

  Color get statusColor {
    switch (status) {
      case MessageStatus.sending:
        return Colors.grey;
      case MessageStatus.sent:
        return Colors.grey;
      case MessageStatus.delivered:
        return Colors.blue;
      case MessageStatus.read:
        return Colors.blue.shade800;
      case MessageStatus.failed:
        return Colors.red;
    }
  }

  IconData get statusIcon {
    switch (status) {
      case MessageStatus.sending:
        return Icons.access_time;
      case MessageStatus.sent:
        return Icons.check;
      case MessageStatus.delivered:
        return Icons.done_all;
      case MessageStatus.read:
        return Icons.done_all;
      case MessageStatus.failed:
        return Icons.error;
    }
  }
}
