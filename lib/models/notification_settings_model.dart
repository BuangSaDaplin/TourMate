class NotificationSettingsModel {
  final String userId;
  final bool pushNotifications;
  final bool emailNotifications;
  final bool bookingNotifications;
  final bool paymentNotifications;
  final bool messageNotifications;
  final bool reviewNotifications;
  final bool systemNotifications;
  final bool marketingNotifications;
  final Map<String, bool> quietHours; // day -> enabled
  final String? emailAddress;

  const NotificationSettingsModel({
    required this.userId,
    this.pushNotifications = true,
    this.emailNotifications = false,
    this.bookingNotifications = true,
    this.paymentNotifications = true,
    this.messageNotifications = true,
    this.reviewNotifications = true,
    this.systemNotifications = true,
    this.marketingNotifications = false,
    this.quietHours = const {},
    this.emailAddress,
  });

  factory NotificationSettingsModel.fromMap(Map<String, dynamic> map) {
    return NotificationSettingsModel(
      userId: map['userId'] ?? '',
      pushNotifications: map['pushNotifications'] ?? true,
      emailNotifications: map['emailNotifications'] ?? false,
      bookingNotifications: map['bookingNotifications'] ?? true,
      paymentNotifications: map['paymentNotifications'] ?? true,
      messageNotifications: map['messageNotifications'] ?? true,
      reviewNotifications: map['reviewNotifications'] ?? true,
      systemNotifications: map['systemNotifications'] ?? true,
      marketingNotifications: map['marketingNotifications'] ?? false,
      quietHours: Map<String, bool>.from(map['quietHours'] ?? {}),
      emailAddress: map['emailAddress'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'pushNotifications': pushNotifications,
      'emailNotifications': emailNotifications,
      'bookingNotifications': bookingNotifications,
      'paymentNotifications': paymentNotifications,
      'messageNotifications': messageNotifications,
      'reviewNotifications': reviewNotifications,
      'systemNotifications': systemNotifications,
      'marketingNotifications': marketingNotifications,
      'quietHours': quietHours,
      'emailAddress': emailAddress,
    };
  }

  NotificationSettingsModel copyWith({
    String? userId,
    bool? pushNotifications,
    bool? emailNotifications,
    bool? bookingNotifications,
    bool? paymentNotifications,
    bool? messageNotifications,
    bool? reviewNotifications,
    bool? systemNotifications,
    bool? marketingNotifications,
    Map<String, bool>? quietHours,
    String? emailAddress,
  }) {
    return NotificationSettingsModel(
      userId: userId ?? this.userId,
      pushNotifications: pushNotifications ?? this.pushNotifications,
      emailNotifications: emailNotifications ?? this.emailNotifications,
      bookingNotifications: bookingNotifications ?? this.bookingNotifications,
      paymentNotifications: paymentNotifications ?? this.paymentNotifications,
      messageNotifications: messageNotifications ?? this.messageNotifications,
      reviewNotifications: reviewNotifications ?? this.reviewNotifications,
      systemNotifications: systemNotifications ?? this.systemNotifications,
      marketingNotifications: marketingNotifications ?? this.marketingNotifications,
      quietHours: quietHours ?? this.quietHours,
      emailAddress: emailAddress ?? this.emailAddress,
    );
  }

  // Check if notifications should be sent based on current time and quiet hours
  bool shouldSendNotification() {
    if (!pushNotifications) return false;

    final now = DateTime.now();
    final dayName = _getDayName(now.weekday);
    final isQuietHour = quietHours[dayName] ?? false;

    if (isQuietHour) {
      // Check if current time is within quiet hours (assuming 10 PM - 8 AM)
      final hour = now.hour;
      return hour >= 8 && hour < 22;
    }

    return true;
  }

  String _getDayName(int weekday) {
    switch (weekday) {
      case 1:
        return 'monday';
      case 2:
        return 'tuesday';
      case 3:
        return 'wednesday';
      case 4:
        return 'thursday';
      case 5:
        return 'friday';
      case 6:
        return 'saturday';
      case 7:
        return 'sunday';
      default:
        return 'monday';
    }
  }
}