import 'package:flutter/material.dart';
import 'package:tourmate_app/services/auth_service.dart';
import 'package:tourmate_app/services/database_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tourmate_app/models/message_model.dart';
import 'package:tourmate_app/models/chat_room_model.dart';
import 'package:tourmate_app/models/report_model.dart';
import '../../utils/app_theme.dart';

class ChatScreen extends StatefulWidget {
  final ChatRoomModel chatRoom;
  final String currentUserId;
  final bool isAdminMonitoring;

  const ChatScreen({
    super.key,
    required this.chatRoom,
    required this.currentUserId,
    this.isAdminMonitoring = false,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final AuthService _authService = AuthService();
  final DatabaseService _db = DatabaseService();
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  bool _isTyping = false;
  String? _displayTitle;

  @override
  void initState() {
    super.initState();
    // Mark messages as read when entering chat
    _markMessagesAsRead();
    // Load the display title
    _loadDisplayTitle();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _markMessagesAsRead() async {
    await _db.markMessagesAsRead(widget.chatRoom.id, widget.currentUserId);
  }

  Future<void> _loadDisplayTitle() async {
    final title =
        await widget.chatRoom.getDisplayTitle(widget.currentUserId, _db);
    setState(() {
      _displayTitle = title;
    });
  }

  Future<void> _sendMessage() async {
    final messageText = _messageController.text.trim();
    if (messageText.isEmpty) return;

    final user = _authService.getCurrentUser();
    if (user == null) return;

    final userName = widget.chatRoom.participantNames[user.uid] ?? 'Unknown';
    final userRole = widget.chatRoom.participantRoles[user.uid] ?? 'Tourist';

    final message = MessageModel(
      id: '', // Will be set by Firestore
      chatRoomId: widget.chatRoom.id,
      senderId: user.uid,
      senderName: userName,
      senderRole: userRole,
      content: messageText,
      timestamp: DateTime.now(),
    );

    setState(() {
      _isTyping = false;
    });

    try {
      await _db.sendMessage(message);
      _messageController.clear();

      // Scroll to bottom after sending
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send message: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
              child: Icon(
                widget.chatRoom.type == ChatRoomType.adminSupport
                    ? Icons.support_agent
                    : Icons.person,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _displayTitle ?? 'Loading...',
                style: AppTheme.headlineSmall.copyWith(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: AppTheme.textPrimary),
            onPressed: _showChatOptions,
          ),
        ],
      ),
      body: Column(
        children: [
          // Messages List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _db.getMessages(widget.chatRoom.id),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
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
                          'No messages yet',
                          style: AppTheme.bodyLarge.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Start the conversation!',
                          style: AppTheme.bodyMedium.copyWith(
                            color: AppTheme.textSecondary.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final messages = snapshot.data!.docs.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  data['id'] = doc.id;
                  return MessageModel.fromMap(data);
                }).toList();

                // Scroll to bottom when new messages arrive
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (_scrollController.hasClients) {
                    _scrollController.animateTo(
                      _scrollController.position.maxScrollExtent,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOut,
                    );
                  }
                });

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isCurrentUser =
                        message.senderId == widget.currentUserId;
                    final showTimestamp = index == 0 ||
                        messages[index - 1]
                                .timestamp
                                .difference(message.timestamp)
                                .inMinutes >
                            5;

                    return Column(
                      children: [
                        if (showTimestamp)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            child: Text(
                              _formatMessageTime(message.timestamp),
                              style: AppTheme.bodySmall.copyWith(
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ),
                        _buildMessageBubble(message, isCurrentUser),
                      ],
                    );
                  },
                );
              },
            ),
          ),

          // Typing Indicator (placeholder for future implementation)
          if (_isTyping)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.white,
              child: Row(
                children: [
                  Text(
                    'Someone is typing...',
                    style: AppTheme.bodySmall.copyWith(
                      color: AppTheme.textSecondary,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),

          // Message Input or Read-Only Indicator
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: widget.isAdminMonitoring
                ? _buildReadOnlyIndicator()
                : widget.chatRoom.status == ChatRoomStatus.blocked
                    ? _buildBlockedIndicator()
                    : Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _messageController,
                              decoration: InputDecoration(
                                hintText: 'Type a message...',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(24),
                                  borderSide: BorderSide.none,
                                ),
                                filled: true,
                                fillColor: AppTheme.backgroundColor,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                              ),
                              maxLines: null,
                              textInputAction: TextInputAction.send,
                              onSubmitted: (_) => _sendMessage(),
                              onChanged: (text) {
                                setState(() {
                                  _isTyping = text.trim().isNotEmpty;
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            decoration: BoxDecoration(
                              gradient: AppTheme.primaryGradient,
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.send, color: Colors.white),
                              onPressed: _sendMessage,
                            ),
                          ),
                        ],
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(MessageModel message, bool isCurrentUser) {
    return Align(
      alignment: isCurrentUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isCurrentUser ? AppTheme.primaryColor : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: isCurrentUser
                ? const Radius.circular(16)
                : const Radius.circular(4),
            bottomRight: isCurrentUser
                ? const Radius.circular(4)
                : const Radius.circular(16),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.content,
              style: AppTheme.bodyMedium.copyWith(
                color: isCurrentUser ? Colors.white : AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _formatMessageTime(message.timestamp),
                  style: AppTheme.bodySmall.copyWith(
                    color:
                        isCurrentUser ? Colors.white70 : AppTheme.textSecondary,
                  ),
                ),
                if (isCurrentUser) ...[
                  const SizedBox(width: 4),
                  Icon(
                    message.statusIcon,
                    size: 12,
                    color: message.statusColor,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatMessageTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays == 0) {
      return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }

  void _showChatOptions() {
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
              'Chat Options',
              style: AppTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            ...[
              if (widget.chatRoom.status == ChatRoomStatus.blocked &&
                  widget.chatRoom.blockedBy == widget.currentUserId)
                ListTile(
                  leading: const Icon(Icons.block, color: Colors.green),
                  title: const Text('Unblock Conversation'),
                  onTap: () {
                    Navigator.pop(context);
                    _unblockConversation();
                  },
                )
              else if (widget.chatRoom.status != ChatRoomStatus.blocked)
                ListTile(
                  leading: const Icon(Icons.block),
                  title: const Text('Block Conversation'),
                  onTap: () {
                    Navigator.pop(context);
                    _blockConversation();
                  },
                ),
            ],
            ListTile(
              leading: const Icon(Icons.report),
              title: const Text('Report Conversation'),
              onTap: () {
                Navigator.pop(context);
                _reportConversation();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _blockConversation() async {
    final user = _authService.getCurrentUser();
    if (user == null) return;

    try {
      await _db.blockChatRoom(widget.chatRoom.id, user.uid);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Conversation blocked')),
      );
      // Refresh the chat room data
      setState(() {});
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to block conversation: $e')),
      );
    }
  }

  void _unblockConversation() async {
    final user = _authService.getCurrentUser();
    if (user == null) return;

    try {
      await _db.unblockChatRoom(widget.chatRoom.id);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Conversation unblocked')),
      );
      // Refresh the chat room data
      setState(() {});
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to unblock conversation: $e')),
      );
    }
  }

  void _reportConversation() {
    showDialog(
      context: context,
      builder: (context) => ReportDialog(
        chatRoom: widget.chatRoom,
        currentUserId: widget.currentUserId,
        onReportSubmitted: (report) async {
          try {
            final db = DatabaseService();
            await db.createReport(report);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Report submitted successfully')),
            );
            // The notification to the reporter is now handled in database_service.createReport()
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to submit report: $e')),
            );
          }
        },
      ),
    );
  }

  void _clearChatHistory() {
    // Implement clear history functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Clear history functionality coming soon')),
    );
  }

  String? _getBlockedNotice() {
    if (widget.chatRoom.status != ChatRoomStatus.blocked) return null;

    final currentUserId = widget.currentUserId;
    final blockedBy = widget.chatRoom.blockedBy;

    if (blockedBy == null) return null;

    final isCurrentUserBlocker = blockedBy == currentUserId;
    final otherParticipantId = widget.chatRoom.participants
        .firstWhere((id) => id != currentUserId, orElse: () => '');
    final otherUserRole =
        widget.chatRoom.participantRoles[otherParticipantId] ?? 'User';

    if (isCurrentUserBlocker) {
      return otherUserRole.toLowerCase() == 'tourist'
          ? "You've blocked this tourist."
          : "You've blocked this tour guide.";
    } else {
      return otherUserRole.toLowerCase() == 'tourist'
          ? "You've been blocked by the tourist."
          : "You've been blocked by the tour guide.";
    }
  }

  Widget _buildBlockedIndicator() {
    final notice = _getBlockedNotice();
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          if (notice != null)
            Text(
              notice,
              style: AppTheme.bodyMedium.copyWith(
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          const SizedBox(height: 8),
          Text(
            'Message input is disabled',
            style: AppTheme.bodySmall.copyWith(
              color: AppTheme.textSecondary.withOpacity(0.7),
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReadOnlyIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Text(
          'Read-Only View - Monitoring Mode',
          style: AppTheme.bodyMedium.copyWith(
            color: AppTheme.textSecondary,
            fontWeight: FontWeight.w600,
            fontStyle: FontStyle.italic,
          ),
        ),
      ),
    );
  }
}

class ReportDialog extends StatefulWidget {
  final ChatRoomModel chatRoom;
  final String currentUserId;
  final Function(ReportModel) onReportSubmitted;

  const ReportDialog({
    super.key,
    required this.chatRoom,
    required this.currentUserId,
    required this.onReportSubmitted,
  });

  @override
  State<ReportDialog> createState() => _ReportDialogState();
}

class _ReportDialogState extends State<ReportDialog> {
  ReportReason? _selectedReason;
  final TextEditingController _descriptionController = TextEditingController();
  List<String> _selectedMessageIds = [];
  bool _isLoading = false;
  List<MessageModel> _recentMessages = [];

  @override
  void initState() {
    super.initState();
    _loadRecentMessages();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadRecentMessages() async {
    final db = DatabaseService();
    final messages =
        await db.getChatRoomMessages(widget.chatRoom.id, limit: 10);
    setState(() {
      _recentMessages = messages;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Report Conversation'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Report Reason (Required)',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...ReportReason.values.map((reason) {
              return RadioListTile<ReportReason>(
                title: Text(_getReasonText(reason)),
                value: reason,
                groupValue: _selectedReason,
                onChanged: (value) {
                  setState(() {
                    _selectedReason = value;
                  });
                },
                dense: true,
              );
            }),
            const SizedBox(height: 16),
            const Text(
              'Description (Optional)',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                hintText: 'Provide additional details about the report...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            const Text(
              'Select Messages (Optional - Max 5)',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            const Text(
              'Only selected messages will be reviewed for moderation purposes.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            if (_recentMessages.isEmpty)
              const Text('Loading messages...')
            else
              Column(
                children: _recentMessages.map((message) {
                  final isSelected = _selectedMessageIds.contains(message.id);
                  return CheckboxListTile(
                    title: Text(
                      '${message.senderName}: ${message.content}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      _formatMessageTime(message.timestamp),
                      style: const TextStyle(fontSize: 12),
                    ),
                    value: isSelected,
                    onChanged: _selectedMessageIds.length >= 5 && !isSelected
                        ? null
                        : (value) {
                            setState(() {
                              if (value == true) {
                                _selectedMessageIds.add(message.id);
                              } else {
                                _selectedMessageIds.remove(message.id);
                              }
                            });
                          },
                    dense: true,
                  );
                }).toList(),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed:
              _isLoading || _selectedReason == null ? null : _submitReport,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Submit Report'),
        ),
      ],
    );
  }

  String _getReasonText(ReportReason reason) {
    switch (reason) {
      case ReportReason.harassment:
        return 'Harassment';
      case ReportReason.scamFraud:
        return 'Scam / Fraud';
      case ReportReason.hateSpeech:
        return 'Hate Speech';
      case ReportReason.inappropriateContent:
        return 'Inappropriate Content';
      case ReportReason.spam:
        return 'Spam';
      case ReportReason.other:
        return 'Other';
    }
  }

  String _formatMessageTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays == 0) {
      return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }

  void _submitReport() async {
    if (_selectedReason == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Get selected messages
      final selectedMessages = _recentMessages
          .where((message) => _selectedMessageIds.contains(message.id))
          .toList();

      // Create reported message snapshots
      final reportedMessageSnapshots = selectedMessages.map((message) {
        return ReportedMessageSnapshot(
          messageId: message.id,
          senderId: message.senderId,
          content: message.content,
          timestamp: message.timestamp,
        );
      }).toList();

      // Determine reported user (the other participant)
      final reportedUserId = widget.chatRoom.participants
          .firstWhere((id) => id != widget.currentUserId);

      // Create report
      final report = ReportModel(
        reportId: 'report_${DateTime.now().millisecondsSinceEpoch}',
        chatRoomId: widget.chatRoom.id,
        reportedByUserId: widget.currentUserId,
        reportedUserId: reportedUserId,
        reason: _selectedReason!,
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        reportedMessageSnapshots: reportedMessageSnapshots,
        reportedAt: DateTime.now(),
      );

      widget.onReportSubmitted(report);
      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to submit report: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}
