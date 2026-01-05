import 'package:flutter/material.dart';
import 'package:tourmate_app/services/database_service.dart';
import 'package:tourmate_app/models/chat_room_model.dart';
import 'package:tourmate_app/models/message_model.dart';
import 'package:tourmate_app/screens/messaging/chat_screen.dart';
import '../../utils/app_theme.dart';

class AdminMessagingMonitorScreen extends StatefulWidget {
  const AdminMessagingMonitorScreen({super.key});

  @override
  State<AdminMessagingMonitorScreen> createState() => _AdminMessagingMonitorScreenState();
}

class _AdminMessagingMonitorScreenState extends State<AdminMessagingMonitorScreen>
    with SingleTickerProviderStateMixin {
  final DatabaseService _db = DatabaseService();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Message Monitoring'),
        backgroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primaryColor,
          unselectedLabelColor: AppTheme.textSecondary,
          indicatorColor: AppTheme.primaryColor,
          tabs: const [
            Tab(text: 'All Chats'),
            Tab(text: 'Active'),
            Tab(text: 'Issues'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAllChatsTab(),
          _buildActiveChatsTab(),
          _buildIssuesTab(),
        ],
      ),
    );
  }

  Widget _buildAllChatsTab() {
    return StreamBuilder<List<ChatRoomModel>>(
      stream: _db.getAllChatRooms(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
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
              ],
            ),
          );
        }

        final chatRooms = snapshot.data!;
        return ListView.builder(
          itemCount: chatRooms.length,
          itemBuilder: (context, index) {
            return _buildChatRoomCard(chatRooms[index]);
          },
        );
      },
    );
  }

  Widget _buildActiveChatsTab() {
    return StreamBuilder<List<ChatRoomModel>>(
      stream: _db.getAllChatRooms(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final activeChats = snapshot.data!
            .where((chat) => chat.isActive && chat.lastMessageTime != null)
            .toList();

        if (activeChats.isEmpty) {
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
                  'No active conversations',
                  style: AppTheme.headlineSmall.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: activeChats.length,
          itemBuilder: (context, index) {
            return _buildChatRoomCard(activeChats[index]);
          },
        );
      },
    );
  }

  Widget _buildIssuesTab() {
    return StreamBuilder<List<ChatRoomModel>>(
      stream: _db.getAllChatRooms(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        // Filter for chats that might have issues (no recent activity, blocked, etc.)
        final issueChats = snapshot.data!
            .where((chat) =>
                chat.isBlocked ||
                (chat.lastMessageTime != null &&
                 DateTime.now().difference(chat.lastMessageTime!).inDays > 7))
            .toList();

        if (issueChats.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.check_circle_outline,
                  size: 64,
                  color: Colors.green.withOpacity(0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  'No issues found',
                  style: AppTheme.headlineSmall.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'All conversations are running smoothly',
                  style: AppTheme.bodyMedium.copyWith(
                    color: AppTheme.textSecondary.withOpacity(0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: issueChats.length,
          itemBuilder: (context, index) {
            return _buildChatRoomCard(issueChats[index], showIssueIndicator: true);
          },
        );
      },
    );
  }

  Widget _buildChatRoomCard(ChatRoomModel chatRoom, {bool showIssueIndicator = false}) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _openChatRoom(chatRoom),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      chatRoom.title,
                      style: AppTheme.headlineSmall.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (showIssueIndicator)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red.withOpacity(0.3)),
                      ),
                      child: Text(
                        chatRoom.isBlocked ? 'Blocked' : 'Inactive',
                        style: AppTheme.bodySmall.copyWith(
                          color: Colors.red,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: chatRoom.statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      chatRoom.status.toString().split('.').last,
                      style: AppTheme.bodySmall.copyWith(
                        color: chatRoom.statusColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Type: ${chatRoom.type.toString().split('.').last}',
                style: AppTheme.bodySmall.copyWith(
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${chatRoom.participants.length} participants',
                style: AppTheme.bodySmall.copyWith(
                  color: AppTheme.textSecondary,
                ),
              ),
              if (chatRoom.lastMessage != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Last: ${chatRoom.lastMessage}',
                  style: AppTheme.bodyMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              if (chatRoom.lastMessageTime != null) ...[
                const SizedBox(height: 4),
                Text(
                  'Updated: ${_formatDateTime(chatRoom.lastMessageTime!)}',
                  style: AppTheme.bodySmall.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton.icon(
                    onPressed: () => _openChatRoom(chatRoom),
                    icon: const Icon(Icons.chat, size: 16),
                    label: const Text('View Chat'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) => _handleChatAction(chatRoom, value),
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'view_details',
                        child: Text('View Details'),
                      ),
                      const PopupMenuItem(
                        value: 'block',
                        child: Text('Block Chat'),
                      ),
                      const PopupMenuItem(
                        value: 'unblock',
                        child: Text('Unblock Chat'),
                      ),
                      const PopupMenuItem(
                        value: 'archive',
                        child: Text('Archive'),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openChatRoom(ChatRoomModel chatRoom) {
    // For admin monitoring, we need to pass the admin user ID
    // In a real app, this would be the current admin's ID
    const adminUserId = 'admin_user_id';

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ChatScreen(
          chatRoom: chatRoom,
          currentUserId: adminUserId,
        ),
      ),
    );
  }

  void _handleChatAction(ChatRoomModel chatRoom, String action) {
    switch (action) {
      case 'view_details':
        _showChatDetails(chatRoom);
        break;
      case 'block':
        _db.updateChatRoomStatus(chatRoom.id, ChatRoomStatus.blocked);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Chat blocked')),
        );
        break;
      case 'unblock':
        _db.updateChatRoomStatus(chatRoom.id, ChatRoomStatus.active);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Chat unblocked')),
        );
        break;
      case 'archive':
        _db.updateChatRoomStatus(chatRoom.id, ChatRoomStatus.archived);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Chat archived')),
        );
        break;
    }
  }

  void _showChatDetails(ChatRoomModel chatRoom) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(chatRoom.title),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('ID: ${chatRoom.id}'),
              Text('Type: ${chatRoom.type.toString().split('.').last}'),
              Text('Status: ${chatRoom.status.toString().split('.').last}'),
              Text('Participants: ${chatRoom.participants.length}'),
              Text('Created: ${_formatDateTime(chatRoom.createdAt)}'),
              if (chatRoom.lastMessageTime != null)
                Text('Last Activity: ${_formatDateTime(chatRoom.lastMessageTime!)}'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}