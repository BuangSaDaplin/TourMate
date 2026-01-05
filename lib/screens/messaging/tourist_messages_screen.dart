import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../utils/app_theme.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../../models/chat_room_model.dart';
import 'chat_screen.dart';

class TouristMessagesScreen extends StatefulWidget {
  const TouristMessagesScreen({super.key});

  @override
  State<TouristMessagesScreen> createState() => _TouristMessagesScreenState();
}

class _TouristMessagesScreenState extends State<TouristMessagesScreen> {
  final AuthService _authService = AuthService();
  final DatabaseService _db = DatabaseService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Messages'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // TODO: Implement search functionality
            },
          ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {
              // TODO: Implement menu options
            },
          ),
        ],
      ),
      body: StreamBuilder<List<ChatRoomModel>>(
        stream: _getCurrentUserChatRooms(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Error loading messages: ${snapshot.error}'),
            );
          }

          final chatRooms = snapshot.data ?? [];

          if (chatRooms.isEmpty) {
            return _buildEmptyState();
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: chatRooms.length,
            itemBuilder: (context, index) {
              final chatRoom = chatRooms[index];
              return _buildChatRoomCard(chatRoom);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Implement new message functionality
        },
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.message),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.message_outlined,
              size: 50,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No Messages Yet',
            style: AppTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Start a conversation with your tour guides',
            style: AppTheme.bodyMedium.copyWith(
              color: AppTheme.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Stream<List<ChatRoomModel>> _getCurrentUserChatRooms() {
    final user = _authService.getCurrentUser();
    if (user == null) {
      return Stream.value([]);
    }
    return _db.getUserChatRooms(user.uid);
  }

  Widget _buildChatRoomCard(ChatRoomModel chatRoom) {
    final currentUser = _authService.getCurrentUser();
    if (currentUser == null) return const SizedBox.shrink();

    // Get the other participant's name
    final otherParticipantId = chatRoom.participants.firstWhere(
      (id) => id != currentUser.uid,
      orElse: () => chatRoom.participants.first,
    );
    final otherParticipantName =
        chatRoom.participantNames[otherParticipantId] ?? 'Unknown';

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatScreen(
              chatRoom: chatRoom,
              currentUserId: currentUser.uid,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: AppTheme.cardDecoration,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  otherParticipantName,
                  style: AppTheme.bodyLarge.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (chatRoom.lastMessageTime != null)
                  Text(
                    _formatLastMessageTime(chatRoom.lastMessageTime!),
                    style: AppTheme.bodySmall.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    chatRoom.lastMessage ?? 'No messages yet',
                    style: AppTheme.bodyMedium.copyWith(
                      color: chatRoom.hasUnreadMessages
                          ? AppTheme.textPrimary
                          : AppTheme.textSecondary,
                      fontWeight: chatRoom.hasUnreadMessages
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (chatRoom.hasUnreadMessages) ...[
                  const SizedBox(width: 8),
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppTheme.accentColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatLastMessageTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays == 0) {
      return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d';
    } else {
      return '${timestamp.day}/${timestamp.month}';
    }
  }
}
