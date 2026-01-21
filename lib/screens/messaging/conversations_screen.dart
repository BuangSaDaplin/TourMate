import 'package:flutter/material.dart';
import 'package:tourmate_app/services/auth_service.dart';
import 'package:tourmate_app/services/database_service.dart';
import 'package:tourmate_app/models/chat_room_model.dart';
import 'package:tourmate_app/screens/messaging/chat_screen.dart';
import '../../utils/app_theme.dart';

class ConversationsScreen extends StatefulWidget {
  const ConversationsScreen({super.key});

  @override
  State<ConversationsScreen> createState() => _ConversationsScreenState();
}

class _ConversationsScreenState extends State<ConversationsScreen> {
  final AuthService _authService = AuthService();
  final DatabaseService _db = DatabaseService();
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _getCurrentUser();
  }

  Future<void> _getCurrentUser() async {
    final user = _authService.getCurrentUser();
    if (user != null) {
      setState(() {
        _currentUserId = user.uid;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUserId == null) {
      return Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: const Text('Messages'),
          backgroundColor: Colors.white,
          elevation: 0,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Messages'),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: AppTheme.textPrimary),
            onPressed: () {
              // Implement search functionality
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Search coming soon!')),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<List<ChatRoomModel>>(
        stream: _db.getUserChatRooms(_currentUserId!),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: AppTheme.errorColor,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Failed to load conversations',
                    style: AppTheme.headlineSmall.copyWith(
                      color: AppTheme.errorColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Please try again later',
                    style: AppTheme.bodyMedium.copyWith(
                      color: AppTheme.textSecondary.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {});
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.chat_bubble_outline,
                    size: 64,
                    color: AppTheme.textSecondary.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No conversations yet',
                    style: AppTheme.headlineSmall.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Start chatting with tour guides!',
                    style: AppTheme.bodyMedium.copyWith(
                      color: AppTheme.textSecondary.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            );
          }

          final chatRooms = snapshot.data!;

          return ListView.builder(
            itemCount: chatRooms.length,
            itemBuilder: (context, index) {
              final chatRoom = chatRooms[index];
              return _buildConversationTile(chatRoom);
            },
          );
        },
      ),
    );
  }

  Widget _buildConversationTile(ChatRoomModel chatRoom) {
    return Dismissible(
      key: Key(chatRoom.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.red,
        child: const Icon(
          Icons.delete,
          color: Colors.white,
        ),
      ),
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete Conversation'),
            content: const Text(
                'Are you sure you want to delete this conversation?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Delete'),
              ),
            ],
          ),
        );
      },
      onDismissed: (direction) {
        // Archive the conversation instead of deleting
        _db.updateChatRoomStatus(chatRoom.id, ChatRoomStatus.archived);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Conversation archived')),
        );
      },
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: ListTile(
          contentPadding: const EdgeInsets.all(16),
          leading: Stack(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                child: Icon(
                  chatRoom.type == ChatRoomType.adminSupport
                      ? Icons.support_agent
                      : Icons.person,
                  color: AppTheme.primaryColor,
                ),
              ),
              if (chatRoom.hasUnreadMessages)
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        chatRoom.unreadCount > 99
                            ? '99+'
                            : chatRoom.unreadCount.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              if (chatRoom.status == ChatRoomStatus.blocked)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.block,
                      color: Colors.white,
                      size: 10,
                    ),
                  ),
                ),
            ],
          ),
          title: Row(
            children: [
              Expanded(
                child: FutureBuilder<String>(
                  future: chatRoom.getDisplayTitle(_currentUserId!, _db),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Text(
                        'Loading...',
                        style: AppTheme.bodyLarge.copyWith(
                          fontWeight: FontWeight.w600,
                          color: chatRoom.hasUnreadMessages
                              ? AppTheme.textPrimary
                              : AppTheme.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      );
                    }
                    return Text(
                      snapshot.data ?? 'Chat',
                      style: AppTheme.bodyLarge.copyWith(
                        fontWeight: FontWeight.w600,
                        color: chatRoom.hasUnreadMessages
                            ? AppTheme.textPrimary
                            : AppTheme.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    );
                  },
                ),
              ),
              if (chatRoom.lastMessageTime != null)
                Text(
                  _formatTime(chatRoom.lastMessageTime!),
                  style: AppTheme.bodySmall.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
            ],
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              chatRoom.displaySubtitle,
              style: AppTheme.bodyMedium.copyWith(
                color: chatRoom.hasUnreadMessages
                    ? AppTheme.textPrimary.withOpacity(0.8)
                    : AppTheme.textSecondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => ChatScreen(
                  chatRoom: chatRoom,
                  currentUserId: _currentUserId!,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  String _formatTime(DateTime timestamp) {
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

  void _showNewChatOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Start New Conversation',
              style: AppTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.support_agent,
                    color: AppTheme.primaryColor),
              ),
              title: const Text('Contact Support'),
              subtitle: const Text('Get help from our admin team'),
              onTap: () {
                Navigator.pop(context);
                _startAdminSupportChat();
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.accentColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.explore, color: AppTheme.accentColor),
              ),
              title: const Text('Find Tour Guides'),
              subtitle: const Text('Browse and contact available guides'),
              onTap: () {
                Navigator.pop(context);
                // Navigate to tour browse or guide list
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Guide browsing coming soon!')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _startAdminSupportChat() async {
    if (_currentUserId == null) return;

    try {
      // Create or get admin support chat room
      final chatRoomId = ChatRoomModel.generateAdminChatRoomId(_currentUserId!);
      final existingRoom = await _db.getChatRoom(chatRoomId);

      if (existingRoom != null) {
        // Navigate to existing chat
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ChatScreen(
              chatRoom: existingRoom,
              currentUserId: _currentUserId!,
            ),
          ),
        );
      } else {
        // Create new admin support chat room
        final newChatRoom = ChatRoomModel(
          id: chatRoomId,
          title: 'Admin Support',
          description: 'Get help from our support team',
          type: ChatRoomType.adminSupport,
          participants: [_currentUserId!, 'admin'], // Add admin user ID
          participantNames: {
            _currentUserId!: 'You',
            'admin': 'Support Team',
          },
          participantRoles: {
            _currentUserId!: 'Tourist', // Would get from user data
            'admin': 'Admin',
          },
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final createdRoom = await _db.createChatRoom(newChatRoom);
        if (createdRoom != null) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => ChatScreen(
                chatRoom: createdRoom,
                currentUserId: _currentUserId!,
              ),
            ),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to start support chat: $e')),
      );
    }
  }
}
