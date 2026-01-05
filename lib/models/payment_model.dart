import 'package:flutter/material.dart';

enum PaymentStatus {
  pending,      // Payment initiated but not completed
  processing,   // Payment is being processed
  completed,    // Payment successfully completed
  failed,       // Payment failed
  cancelled,    // Payment was cancelled
  refunded,     // Payment was refunded
  disputed,     // Payment is under dispute
}

enum PaymentMethod {
  creditCard,
  debitCard,
  paypal,
  gcash,
  paymaya,
  bankTransfer,
  cash,
}

// Extension methods for PaymentMethod
extension PaymentMethodExtension on PaymentMethod {
  String get paymentMethodDisplayText {
    switch (this) {
      case PaymentMethod.creditCard:
        return 'Credit Card';
      case PaymentMethod.debitCard:
        return 'Debit Card';
      case PaymentMethod.paypal:
        return 'PayPal';
      case PaymentMethod.gcash:
        return 'GCash';
      case PaymentMethod.paymaya:
        return 'PayMaya';
      case PaymentMethod.bankTransfer:
        return 'Bank Transfer';
      case PaymentMethod.cash:
        return 'Cash';
    }
  }

  IconData get paymentMethodIcon {
    switch (this) {
      case PaymentMethod.creditCard:
      case PaymentMethod.debitCard:
        return Icons.credit_card;
      case PaymentMethod.paypal:
        return Icons.account_balance_wallet;
      case PaymentMethod.gcash:
      case PaymentMethod.paymaya:
        return Icons.phone_android;
      case PaymentMethod.bankTransfer:
        return Icons.account_balance;
      case PaymentMethod.cash:
        return Icons.money;
    }
  }
}

class PaymentModel {
  final String id;
  final String bookingId;
  final String userId; // Tourist who made the payment
  final String? guideId; // Guide who will receive the payment
  final double amount;
  final double platformFee; // Platform service fee
  final double guideAmount; // Amount going to guide (amount - platformFee)
  final PaymentMethod paymentMethod;
  final PaymentStatus status;
  final DateTime createdAt;
  final DateTime? completedAt;
  final DateTime? refundedAt;
  final String? transactionId; // External payment processor ID
  final String? failureReason;
  final String? refundReason;
  final Map<String, dynamic>? paymentDetails; // Store card details, etc. (encrypted)
  final Map<String, dynamic>? metadata;

  PaymentModel({
    required this.id,
    required this.bookingId,
    required this.userId,
    this.guideId,
    required this.amount,
    required this.platformFee,
    required this.guideAmount,
    required this.paymentMethod,
    this.status = PaymentStatus.pending,
    required this.createdAt,
    this.completedAt,
    this.refundedAt,
    this.transactionId,
    this.failureReason,
    this.refundReason,
    this.paymentDetails,
    this.metadata,
  });

  factory PaymentModel.fromMap(Map<String, dynamic> data) {
    return PaymentModel(
      id: data['id'],
      bookingId: data['bookingId'],
      userId: data['userId'],
      guideId: data['guideId'],
      amount: data['amount'].toDouble(),
      platformFee: data['platformFee'].toDouble(),
      guideAmount: data['guideAmount'].toDouble(),
      paymentMethod: PaymentMethod.values[data['paymentMethod'] ?? 0],
      status: PaymentStatus.values[data['status'] ?? 0],
      createdAt: data['createdAt'].toDate(),
      completedAt: data['completedAt']?.toDate(),
      refundedAt: data['refundedAt']?.toDate(),
      transactionId: data['transactionId'],
      failureReason: data['failureReason'],
      refundReason: data['refundReason'],
      paymentDetails: data['paymentDetails'],
      metadata: data['metadata'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'bookingId': bookingId,
      'userId': userId,
      'guideId': guideId,
      'amount': amount,
      'platformFee': platformFee,
      'guideAmount': guideAmount,
      'paymentMethod': paymentMethod.index,
      'status': status.index,
      'createdAt': createdAt,
      'completedAt': completedAt,
      'refundedAt': refundedAt,
      'transactionId': transactionId,
      'failureReason': failureReason,
      'refundReason': refundReason,
      'paymentDetails': paymentDetails,
      'metadata': metadata,
    };
  }

  // Helper methods
  bool get isCompleted => status == PaymentStatus.completed;
  bool get isFailed => status == PaymentStatus.failed;
  bool get isPending => status == PaymentStatus.pending || status == PaymentStatus.processing;
  bool get canRefund => status == PaymentStatus.completed;
  bool get isRefunded => status == PaymentStatus.refunded;

  String get statusDisplayText {
    switch (status) {
      case PaymentStatus.pending:
        return 'Pending';
      case PaymentStatus.processing:
        return 'Processing';
      case PaymentStatus.completed:
        return 'Completed';
      case PaymentStatus.failed:
        return 'Failed';
      case PaymentStatus.cancelled:
        return 'Cancelled';
      case PaymentStatus.refunded:
        return 'Refunded';
      case PaymentStatus.disputed:
        return 'Disputed';
    }
  }

  Color get statusColor {
    switch (status) {
      case PaymentStatus.pending:
      case PaymentStatus.processing:
        return const Color(0xFFFFA726); // Orange
      case PaymentStatus.completed:
        return const Color(0xFF4CAF50); // Green
      case PaymentStatus.failed:
      case PaymentStatus.cancelled:
        return const Color(0xFFE53935); // Red
      case PaymentStatus.refunded:
        return const Color(0xFF8D6E63); // Brown
      case PaymentStatus.disputed:
        return const Color(0xFF9C27B0); // Purple
    }
  }

  String get paymentMethodDisplayText {
    switch (paymentMethod) {
      case PaymentMethod.creditCard:
        return 'Credit Card';
      case PaymentMethod.debitCard:
        return 'Debit Card';
      case PaymentMethod.paypal:
        return 'PayPal';
      case PaymentMethod.gcash:
        return 'GCash';
      case PaymentMethod.paymaya:
        return 'PayMaya';
      case PaymentMethod.bankTransfer:
        return 'Bank Transfer';
      case PaymentMethod.cash:
        return 'Cash';
    }
  }

  IconData get paymentMethodIcon {
    switch (paymentMethod) {
      case PaymentMethod.creditCard:
      case PaymentMethod.debitCard:
        return Icons.credit_card;
      case PaymentMethod.paypal:
        return Icons.account_balance_wallet;
      case PaymentMethod.gcash:
      case PaymentMethod.paymaya:
        return Icons.phone_android;
      case PaymentMethod.bankTransfer:
        return Icons.account_balance;
      case PaymentMethod.cash:
        return Icons.money;
    }
  }
}