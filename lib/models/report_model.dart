enum ReportReason {
  harassment,
  scamFraud,
  hateSpeech,
  inappropriateContent,
  spam,
  other,
}

enum ReportStatus {
  pending,
  underReview,
  resolved,
  dismissed,
}

enum ResolutionAction {
  noViolationFound,
  blockConversation,
  issueFormalWarning,
  flagUser,
}

class ReportedMessageSnapshot {
  final String messageId;
  final String senderId;
  final String content;
  final DateTime timestamp;

  ReportedMessageSnapshot({
    required this.messageId,
    required this.senderId,
    required this.content,
    required this.timestamp,
  });

  factory ReportedMessageSnapshot.fromMap(Map<String, dynamic> data) {
    return ReportedMessageSnapshot(
      messageId: data['messageId'] ?? '',
      senderId: data['senderId'] ?? '',
      content: data['content'] ?? '',
      timestamp: data['timestamp']?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'messageId': messageId,
      'senderId': senderId,
      'content': content,
      'timestamp': timestamp,
    };
  }
}

class ReportModel {
  final String reportId;
  final String chatRoomId;
  final String reportedByUserId;
  final String reportedUserId;
  final ReportReason reason;
  final String? description;
  final List<ReportedMessageSnapshot> reportedMessageSnapshots;
  final DateTime reportedAt;
  final ReportStatus status;
  final DateTime? resolvedAt;
  final ResolutionAction? resolutionAction;
  final String? adminNotes;
  final String? reviewedByAdminId;

  ReportModel({
    required this.reportId,
    required this.chatRoomId,
    required this.reportedByUserId,
    required this.reportedUserId,
    required this.reason,
    this.description,
    required this.reportedMessageSnapshots,
    required this.reportedAt,
    this.status = ReportStatus.pending,
    this.resolvedAt,
    this.resolutionAction,
    this.adminNotes,
    this.reviewedByAdminId,
  });

  factory ReportModel.fromMap(Map<String, dynamic> data) {
    return ReportModel(
      reportId: data['reportId'] ?? '',
      chatRoomId: data['chatRoomId'] ?? '',
      reportedByUserId: data['reportedByUserId'] ?? '',
      reportedUserId: data['reportedUserId'] ?? '',
      reason: ReportReason.values[data['reason'] ?? 0],
      description: data['description'],
      reportedMessageSnapshots:
          (data['reportedMessageSnapshots'] as List<dynamic>?)
                  ?.map((snapshot) => ReportedMessageSnapshot.fromMap(snapshot))
                  .toList() ??
              [],
      reportedAt: data['reportedAt']?.toDate() ?? DateTime.now(),
      status: ReportStatus.values[data['status'] ?? 0],
      resolvedAt: data['resolvedAt']?.toDate(),
      resolutionAction: data['resolutionAction'] != null
          ? ResolutionAction.values[data['resolutionAction']]
          : null,
      adminNotes: data['adminNotes'],
      reviewedByAdminId: data['reviewedByAdminId'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'reportId': reportId,
      'chatRoomId': chatRoomId,
      'reportedByUserId': reportedByUserId,
      'reportedUserId': reportedUserId,
      'reason': reason.index,
      'description': description,
      'reportedMessageSnapshots':
          reportedMessageSnapshots.map((snapshot) => snapshot.toMap()).toList(),
      'reportedAt': reportedAt,
      'status': status.index,
    };
  }

  String get reasonText {
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

  String get statusText {
    switch (status) {
      case ReportStatus.pending:
        return 'Pending';
      case ReportStatus.underReview:
        return 'Under Review';
      case ReportStatus.resolved:
        return 'Resolved';
      case ReportStatus.dismissed:
        return 'Dismissed';
    }
  }
}
