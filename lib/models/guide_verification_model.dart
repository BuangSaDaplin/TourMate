enum VerificationStatus { pending, approved, rejected }

class GuideVerification {
  final String id;
  final String guideId;
  final String guideName;
  final String guideEmail;
  final String? bio;
  final List<String>? idDocumentUrl;
  final List<String>? lguDocumentUrl;
  final VerificationStatus status;
  final DateTime submittedAt;
  final DateTime? reviewedAt;
  final String? reviewedBy;
  final String? rejectionReason;

  GuideVerification({
    required this.id,
    required this.guideId,
    required this.guideName,
    required this.guideEmail,
    this.bio,
    this.idDocumentUrl,
    this.lguDocumentUrl,
    this.status = VerificationStatus.pending,
    required this.submittedAt,
    this.reviewedAt,
    this.reviewedBy,
    this.rejectionReason,
  });

  factory GuideVerification.fromMap(Map<String, dynamic> data) {
    return GuideVerification(
      id: data['id'] ?? '',
      guideId: data['guideId'] ?? '',
      guideName: data['guideName'] ?? '',
      guideEmail: data['guideEmail'] ?? '',
      bio: data['bio'],
      idDocumentUrl: data['idDocumentUrl'] != null
          ? List<String>.from(data['idDocumentUrl'])
          : null,
      lguDocumentUrl: data['lguDocumentUrl'] != null
          ? List<String>.from(data['lguDocumentUrl'])
          : null,
      status: VerificationStatus.values[data['status'] ?? 0],
      submittedAt: DateTime.parse(
          data['submittedAt'] ?? DateTime.now().toIso8601String()),
      reviewedAt: data['reviewedAt'] != null
          ? DateTime.parse(data['reviewedAt'])
          : null,
      reviewedBy: data['reviewedBy'],
      rejectionReason: data['rejectionReason'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'guideId': guideId,
      'guideName': guideName,
      'guideEmail': guideEmail,
      'bio': bio,
      'idDocumentUrl': idDocumentUrl,
      'lguDocumentUrl': lguDocumentUrl,
      'status': status.index,
      'submittedAt': submittedAt.toIso8601String(),
      'reviewedAt': reviewedAt?.toIso8601String(),
      'reviewedBy': reviewedBy,
      'rejectionReason': rejectionReason,
    };
  }

  GuideVerification copyWith({
    String? id,
    String? guideId,
    String? guideName,
    String? guideEmail,
    String? bio,
    List<String>? idDocumentUrl,
    List<String>? lguDocumentUrl,
    VerificationStatus? status,
    DateTime? submittedAt,
    DateTime? reviewedAt,
    String? reviewedBy,
    String? rejectionReason,
  }) {
    return GuideVerification(
      id: id ?? this.id,
      guideId: guideId ?? this.guideId,
      guideName: guideName ?? this.guideName,
      guideEmail: guideEmail ?? this.guideEmail,
      bio: bio ?? this.bio,
      idDocumentUrl: idDocumentUrl ?? this.idDocumentUrl,
      lguDocumentUrl: lguDocumentUrl ?? this.lguDocumentUrl,
      status: status ?? this.status,
      submittedAt: submittedAt ?? this.submittedAt,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      reviewedBy: reviewedBy ?? this.reviewedBy,
      rejectionReason: rejectionReason ?? this.rejectionReason,
    );
  }
}
