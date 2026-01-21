import 'package:flutter/material.dart';
import 'package:tourmate_app/services/database_service.dart';

enum ChatRoomType {
  touristGuide, // Tourist messaging with a specific guide
  adminSupport, // User messaging with admin support
  group, // Group conversations (future feature)
}

enum ChatRoomStatus {
  active,
  archived,
  blocked,
}

class ChatRoomModel {
  final String id;
  final String title;
  final String description;
  final ChatRoomType type;
  final ChatRoomStatus status;
  final List<String> participants; // User IDs
  final Map<String, String> participantNames; // userId -> displayName
  final Map<String, String> participantRoles; // userId -> role
  final String? lastMessage;
  final String? lastMessageSenderId;
  final String? lastMessageSenderName;
  final DateTime? lastMessageTime;
  final int unreadCount; // For current user
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? relatedBookingId; // If chat is related to a specific booking
  final String? relatedTourId; // If chat is related to a specific tour
  final String?
      blockedBy; // User ID who initiated the block, null if not blocked

  ChatRoomModel({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    this.status = ChatRoomStatus.active,
    required this.participants,
    this.participantNames = const {},
    this.participantRoles = const {},
    this.lastMessage,
    this.lastMessageSenderId,
    this.lastMessageSenderName,
    this.lastMessageTime,
    this.unreadCount = 0,
    required this.createdAt,
    required this.updatedAt,
    this.relatedBookingId,
    this.relatedTourId,
    this.blockedBy,
  });

  factory ChatRoomModel.fromMap(Map<String, dynamic> data) {
    return ChatRoomModel(
      id: data['id'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      type: ChatRoomType.values[data['type'] ?? 0],
      status: ChatRoomStatus.values[data['status'] ?? 0],
      participants: List<String>.from(data['participants'] ?? []),
      participantNames:
          Map<String, String>.from(data['participantNames'] ?? {}),
      participantRoles:
          Map<String, String>.from(data['participantRoles'] ?? {}),
      lastMessage: data['lastMessage'],
      lastMessageSenderId: data['lastMessageSenderId'],
      lastMessageSenderName: data['lastMessageSenderName'],
      lastMessageTime: data['lastMessageTime']?.toDate(),
      unreadCount: data['unreadCount'] ?? 0,
      createdAt: data['createdAt']?.toDate() ?? DateTime.now(),
      updatedAt: data['updatedAt']?.toDate() ?? DateTime.now(),
      relatedBookingId: data['relatedBookingId'],
      relatedTourId: data['relatedTourId'],
      blockedBy: data['blockedBy'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'type': type.index,
      'status': status.index,
      'participants': participants,
      'participantNames': participantNames,
      'participantRoles': participantRoles,
      'lastMessage': lastMessage,
      'lastMessageSenderId': lastMessageSenderId,
      'lastMessageSenderName': lastMessageSenderName,
      'lastMessageTime': lastMessageTime,
      'unreadCount': unreadCount,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'relatedBookingId': relatedBookingId,
      'relatedTourId': relatedTourId,
      'blockedBy': blockedBy,
    };
  }

  // Helper methods
  bool get isActive => status == ChatRoomStatus.active;
  bool get isArchived => status == ChatRoomStatus.archived;
  bool get isBlocked => status == ChatRoomStatus.blocked;

  bool get hasUnreadMessages => unreadCount > 0;

  Future<String> getDisplayTitle(
      String currentUserId, DatabaseService db) async {
    if (type == ChatRoomType.touristGuide && participants.length == 2) {
      // For tourist-guide chats, always show the other participant's real-time name
      final otherParticipantId = participants.firstWhere(
        (id) => id != currentUserId,
        orElse: () => participants.first,
      );
      final otherUser = await db.getUser(otherParticipantId);
      return otherUser?.displayName ?? 'User';
    }
    return title;
  }

  String get displaySubtitle {
    if (lastMessage != null && lastMessageSenderName != null) {
      return '$lastMessageSenderName: $lastMessage';
    }
    return description;
  }

  Color get statusColor {
    switch (status) {
      case ChatRoomStatus.active:
        return Colors.green;
      case ChatRoomStatus.archived:
        return Colors.grey;
      case ChatRoomStatus.blocked:
        return Colors.red;
    }
  }

  // Create chat room ID for tourist-guide conversations
  static String generateChatRoomId(String touristId, String guideId) {
    // Sort IDs to ensure consistent room ID regardless of who initiates
    final sortedIds = [touristId, guideId]..sort();
    return 'tourist_guide_${sortedIds[0]}_${sortedIds[1]}';
  }

  // Create chat room ID for admin support conversations
  static String generateAdminChatRoomId(String userId) {
    return 'admin_support_$userId';
  }
}
