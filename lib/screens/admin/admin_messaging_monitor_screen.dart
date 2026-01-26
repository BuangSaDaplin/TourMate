import 'package:flutter/material.dart';
import 'package:tourmate_app/services/database_service.dart';
import 'package:tourmate_app/models/chat_room_model.dart';
import 'package:tourmate_app/models/message_model.dart';
import 'package:tourmate_app/models/report_model.dart';
import 'package:tourmate_app/screens/messaging/chat_screen.dart';
import '../../utils/app_theme.dart';

class AdminMessagingMonitorScreen extends StatefulWidget {
  const AdminMessagingMonitorScreen({super.key});

  @override
  State<AdminMessagingMonitorScreen> createState() =>
      _AdminMessagingMonitorScreenState();
}

class _AdminMessagingMonitorScreenState
    extends State<AdminMessagingMonitorScreen>
    with SingleTickerProviderStateMixin {
  final DatabaseService _db = DatabaseService();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
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
            Tab(text: 'Reports'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAllChatsTab(),
          _buildActiveChatsTab(),
          _buildIssuesTab(),
          _buildReportsTab(),
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
                    DateTime.now().difference(chat.lastMessageTime!).inDays >
                        7))
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
            return _buildChatRoomCard(issueChats[index],
                showIssueIndicator: true);
          },
        );
      },
    );
  }

  Widget _buildReportsTab() {
    return StreamBuilder<List<ReportModel>>(
      stream: _db.getAllReports(),
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
                  Icons.report_problem,
                  size: 64,
                  color: AppTheme.textSecondary.withOpacity(0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  'No reports yet',
                  style: AppTheme.headlineSmall.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Reports will appear here when users submit them',
                  style: AppTheme.bodyMedium.copyWith(
                    color: AppTheme.textSecondary.withOpacity(0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        final reports = snapshot.data!;
        return ListView.builder(
          itemCount: reports.length,
          itemBuilder: (context, index) {
            return _buildReportCard(reports[index]);
          },
        );
      },
    );
  }

  Widget _buildChatRoomCard(ChatRoomModel chatRoom,
      {bool showIssueIndicator = false}) {
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
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
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
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
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
          isAdminMonitoring: true, // Enable read-only mode for admin monitoring
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
                Text(
                    'Last Activity: ${_formatDateTime(chatRoom.lastMessageTime!)}'),
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

  Widget _buildReportCard(ReportModel report) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _showReportDetails(report),
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
                      report.reasonText,
                      style: AppTheme.headlineSmall.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color:
                          _getReportStatusColor(report.status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _getReportStatusColor(report.status)
                            .withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      report.statusText,
                      style: AppTheme.bodySmall.copyWith(
                        color: _getReportStatusColor(report.status),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '${report.reportedMessageSnapshots.length} message(s) reported',
                style: AppTheme.bodySmall.copyWith(
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Reported: ${_formatDateTime(report.reportedAt)}',
                style: AppTheme.bodySmall.copyWith(
                  color: AppTheme.textSecondary,
                ),
              ),
              if (report.description != null && report.description!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    report.description!,
                    style: AppTheme.bodyMedium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton.icon(
                    onPressed: () => _showReportDetails(report),
                    icon: const Icon(Icons.visibility, size: 16),
                    label: const Text('View Details'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                    ),
                  ),
                  Row(
                    children: [
                      if (report.status == ReportStatus.pending)
                        ElevatedButton.icon(
                          onPressed: () => _markAsUnderReview(report),
                          icon: const Icon(Icons.visibility, size: 16),
                          label: const Text('Mark as Under Review'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                          ),
                        ),
                      if (report.status == ReportStatus.underReview)
                        ElevatedButton.icon(
                          onPressed: () => _showResolveReportDialog(report),
                          icon: const Icon(Icons.check_circle, size: 16),
                          label: const Text('Resolve Report'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                          ),
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

  Color _getReportStatusColor(ReportStatus status) {
    switch (status) {
      case ReportStatus.pending:
        return Colors.orange;
      case ReportStatus.underReview:
        return Colors.blue;
      case ReportStatus.resolved:
        return Colors.green;
      case ReportStatus.dismissed:
        return Colors.grey;
    }
  }

  void _showReportDetails(ReportModel report) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Report Details - ${report.reasonText}'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Report ID: ${report.reportId}'),
              Text('Chat Room ID: ${report.chatRoomId}'),
              Text('Reported User ID: ${report.reportedUserId}'),
              Text('Reported By: ${report.reportedByUserId}'),
              Text('Status: ${report.statusText}'),
              Text('Reported At: ${_formatDateTime(report.reportedAt)}'),
              if (report.description != null && report.description!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text('Description: ${report.description}'),
                ),
              const SizedBox(height: 16),
              const Text(
                'Reported Messages:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...report.reportedMessageSnapshots.map((snapshot) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'From: ${snapshot.senderId}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(snapshot.content),
                      Text(
                        'Time: ${_formatDateTime(snapshot.timestamp)}',
                        style:
                            const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                );
              }),
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

  void _handleReportAction(ReportModel report, String action) {
    switch (action) {
      case 'mark_under_review':
        _db.updateReportStatus(report.reportId, ReportStatus.underReview);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Report marked as under review')),
        );
        break;
      case 'resolve':
        _db.updateReportStatus(report.reportId, ReportStatus.resolved);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Report resolved')),
        );
        break;
      case 'dismiss':
        _db.updateReportStatus(report.reportId, ReportStatus.dismissed);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Report dismissed')),
        );
        break;
    }
  }

  void _markAsUnderReview(ReportModel report) {
    _db.updateReportStatus(report.reportId, ReportStatus.underReview);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Report marked as under review')),
    );
  }

  void _showResolveReportDialog(ReportModel report) {
    ResolutionAction? selectedAction;
    final TextEditingController notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Resolve Report'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Report information
                const Text('Report Information:',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text('Reason: ${report.reasonText}'),
                Text('Reported User ID: ${report.reportedUserId}'),
                Text(
                    'Number of messages: ${report.reportedMessageSnapshots.length}'),
                Text(
                    'Message timestamps: ${report.reportedMessageSnapshots.map((s) => _formatDateTime(s.timestamp)).join(', ')}'),
                const SizedBox(height: 16),

                // Message previews
                const Text('Message Previews:',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ...report.reportedMessageSnapshots.map((snapshot) => Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('From: ${snapshot.senderId}',
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold)),
                          Text(snapshot.content),
                          Text(_formatDateTime(snapshot.timestamp),
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                    )),
                const SizedBox(height: 16),

                // Resolution action
                const Text('Resolution Action (Required):',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Column(
                  children: [
                    RadioListTile<ResolutionAction>(
                      title: const Text('No Violation Found'),
                      subtitle: const Text('Send reminder notification'),
                      value: ResolutionAction.noViolationFound,
                      groupValue: selectedAction,
                      onChanged: (value) =>
                          setState(() => selectedAction = value),
                    ),
                    RadioListTile<ResolutionAction>(
                      title: const Text('Block Conversation'),
                      subtitle: const Text('Set ChatRoom.status = blocked'),
                      value: ResolutionAction.blockConversation,
                      groupValue: selectedAction,
                      onChanged: (value) =>
                          setState(() => selectedAction = value),
                    ),
                    RadioListTile<ResolutionAction>(
                      title: const Text('Issue Formal Warning'),
                      subtitle: const Text('Create warning record'),
                      value: ResolutionAction.issueFormalWarning,
                      groupValue: selectedAction,
                      onChanged: (value) =>
                          setState(() => selectedAction = value),
                    ),
                    RadioListTile<ResolutionAction>(
                      title: const Text('Flag User (Escalation)'),
                      subtitle: const Text('Set User.isFlagged = true'),
                      value: ResolutionAction.flagUser,
                      groupValue: selectedAction,
                      onChanged: (value) =>
                          setState(() => selectedAction = value),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Admin notes
                const Text('Admin Resolution Notes (Required):',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                TextField(
                  controller: notesController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText: 'Enter resolution notes...',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: selectedAction != null &&
                      notesController.text.trim().isNotEmpty
                  ? () async {
                      // Get admin ID (in real app, this would come from auth)
                      const adminId = 'admin_user_id';

                      await _db.resolveReport(
                        reportId: report.reportId,
                        resolutionAction: selectedAction!,
                        adminNotes: notesController.text.trim(),
                        adminId: adminId,
                      );

                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Report resolved successfully')),
                      );
                    }
                  : null,
              child: const Text('Confirm Resolution'),
            ),
          ],
        ),
      ),
    );
  }
}
