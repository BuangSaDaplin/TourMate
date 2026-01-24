import 'package:flutter/material.dart';
import 'package:tourmate_app/services/auth_service.dart';
import 'package:tourmate_app/services/database_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tourmate_app/models/message_model.dart';
import 'package:tourmate_app/models/chat_room_model.dart';
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
                        _buildOppositeMessageBubble(message, isCurrentUser),
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

  // --- THE OPPOSITE UI FIX ---
  Widget _buildOppositeMessageBubble(MessageModel message, bool isCurrentUser) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        mainAxisAlignment: isCurrentUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isCurrentUser) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.grey[300],
              child: Text(message.senderName.isNotEmpty ? message.senderName[0] : '?', 
                style: const TextStyle(fontSize: 12)),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isCurrentUser ? AppTheme.primaryColor : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: isCurrentUser ? const Radius.circular(16) : const Radius.circular(4),
                  bottomRight: isCurrentUser ? const Radius.circular(4) : const Radius.circular(16),
                ),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(message.content, 
                    style: TextStyle(color: isCurrentUser ? Colors.white : Colors.black87)),
                  const SizedBox(height: 4),
                  Text(
                    "${message.timestamp.hour}:${message.timestamp.minute.toString().padLeft(2, '0')}",
                    style: TextStyle(fontSize: 10, color: isCurrentUser ? Colors.white70 : Colors.grey),
                  ),
                ],
              ),
            ),
          ),
          if (isCurrentUser) const SizedBox(width: 24), // Spacer
        ],
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

  // --- REPORT DIALOG ---
  void _reportConversation() {
    final reasonController = TextEditingController();
    bool hasAttachedProof = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Report Conversation'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Reason for reporting:', style: TextStyle(fontWeight: FontWeight.bold)),
                TextField(
                  controller: reasonController,
                  decoration: const InputDecoration(hintText: 'e.g. Harassment, Scam'),
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: () => setState(() => hasAttachedProof = !hasAttachedProof),
                  child: Row(
                    children: [
                      Icon(
                        hasAttachedProof ? Icons.check_circle : Icons.attach_file,
                        color: hasAttachedProof ? Colors.green : Colors.grey,
                      ),
                      const SizedBox(width: 8),
                      Text(hasAttachedProof ? 'Proof Attached' : 'Attach Screenshot'),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () async {
                  if (reasonController.text.isEmpty) return;
                  Navigator.pop(context);
                  
                  // Save to Firestore
                  await FirebaseFirestore.instance.collection('reports').add({
                    'chatRoomId': widget.chatRoom.id,
                    'reportedBy': widget.currentUserId,
                    'reason': reasonController.text,
                    'hasProof': hasAttachedProof,
                    'timestamp': FieldValue.serverTimestamp(),
                    'status': 'pending',
                  });
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Report submitted.'), backgroundColor: Colors.green),
                  );
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                child: const Text('Submit'),
              ),
            ],
          );
        }
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
