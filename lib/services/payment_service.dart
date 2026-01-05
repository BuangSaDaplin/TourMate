import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:tourmate_app/models/payment_model.dart';
import 'package:tourmate_app/models/booking_model.dart';
import 'package:tourmate_app/services/notification_service.dart';

class PaymentService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final NotificationService _notificationService = NotificationService();

  // Platform fee configuration
  static const double platformFeePercentage = 0.05; // 5%
  static const double platformFeeFixed = 25.0; // Fixed fee in PHP

  // Payment processing methods
  Future<PaymentModel?> processPayment({
    required String bookingId,
    required String userId,
    required String guideId,
    required double amount,
    required PaymentMethod paymentMethod,
    Map<String, dynamic>? paymentDetails,
  }) async {
    try {
      // Calculate fees
      final platformFee = _calculatePlatformFee(amount);
      final guideAmount = amount - platformFee;

      // Create payment record
      final paymentId = DateTime.now().millisecondsSinceEpoch.toString();
      final payment = PaymentModel(
        id: paymentId,
        bookingId: bookingId,
        userId: userId,
        guideId: guideId,
        amount: amount,
        platformFee: platformFee,
        guideAmount: guideAmount,
        paymentMethod: paymentMethod,
        status: PaymentStatus.processing,
        createdAt: DateTime.now(),
        paymentDetails: paymentDetails,
      );

      // Save to database
      await _db.collection('payments').doc(paymentId).set(payment.toMap());

      // Process payment based on method
      final success = await _processPaymentWithProvider(payment);

      if (success) {
        // Update payment status
        await _updatePaymentStatus(paymentId, PaymentStatus.completed);
        await _updateBookingPaymentStatus(bookingId, BookingStatus.paid);

        // Update payment with completion details
        final updatedPayment = payment.copyWith(
          status: PaymentStatus.completed,
          completedAt: DateTime.now(),
          transactionId: 'txn_${paymentId}',
        );

        await _db.collection('payments').doc(paymentId).update({
          'status': PaymentStatus.completed.index,
          'completedAt': FieldValue.serverTimestamp(),
          'transactionId': 'txn_${paymentId}',
        });

        // Get booking details for notification
        final bookingDoc =
            await _db.collection('bookings').doc(bookingId).get();
        final bookingData = bookingDoc.data();
        final tourTitle = bookingData?['tourTitle'] ?? 'Tour';

        // Create payment completion notification
        final paymentNotification =
            _notificationService.createPaymentNotification(
          userId: userId,
          amount: amount,
          tourTitle: tourTitle,
        );
        await _notificationService.createNotification(paymentNotification);

        return updatedPayment;
      } else {
        // Payment failed
        await _updatePaymentStatus(paymentId, PaymentStatus.failed);

        // Get booking details for notification
        final bookingDoc =
            await _db.collection('bookings').doc(bookingId).get();
        final bookingData = bookingDoc.data();
        final tourTitle = bookingData?['tourTitle'] ?? 'Tour';

        // Create payment failure notification
        final failureNotification =
            _notificationService.createPaymentFailedNotification(
          userId: userId,
          amount: amount,
          tourTitle: tourTitle,
        );
        await _notificationService.createNotification(failureNotification);

        return null;
      }
    } catch (e) {
      print('Payment processing error: $e');
      return null;
    }
  }

  Future<bool> _processPaymentWithProvider(PaymentModel payment) async {
    // Payment processing delay
    await Future.delayed(const Duration(seconds: 2));

    // Integrate with actual payment providers like:
    // - Stripe for credit cards
    // - PayPal for PayPal payments
    // - GCash/PayMaya APIs for mobile payments

    switch (payment.paymentMethod) {
      case PaymentMethod.creditCard:
      case PaymentMethod.debitCard:
        // Integrate with Stripe/PayMongo
        return await _processStripePayment(payment);

      case PaymentMethod.paypal:
        // Integrate with PayPal
        return await _processPayPalPayment(payment);

      case PaymentMethod.gcash:
      case PaymentMethod.paymaya:
        // Integrate with local payment providers
        return await _processLocalPayment(payment);

      case PaymentMethod.bankTransfer:
        // Handle bank transfer (usually manual verification)
        return await _processBankTransfer(payment);

      case PaymentMethod.cash:
        // Cash payments are handled offline
        return true;

      default:
        return false;
    }
  }

  Future<bool> _processStripePayment(PaymentModel payment) async {
    // Integrate with Stripe SDK or API
    try {
      // final paymentIntent = await Stripe.instance.createPaymentMethod(...);
      // final result = await Stripe.instance.confirmPayment(...);
      // return result.status == PaymentIntentStatus.succeeded;
      throw UnimplementedError('Stripe integration not implemented');
    } catch (e) {
      return false;
    }
  }

  Future<bool> _processPayPalPayment(PaymentModel payment) async {
    // Integrate with PayPal SDK or API
    throw UnimplementedError('PayPal integration not implemented');
  }

  Future<bool> _processLocalPayment(PaymentModel payment) async {
    // Integrate with GCash/PayMaya APIs
    throw UnimplementedError('Local payment integration not implemented');
  }

  Future<bool> _processBankTransfer(PaymentModel payment) async {
    // Bank transfers usually require manual verification
    // Set status to pending for admin review
    await _updatePaymentStatus(payment.id, PaymentStatus.pending);
    return true;
  }

  double _calculatePlatformFee(double amount) {
    // Calculate platform fee: percentage + fixed fee
    final percentageFee = amount * platformFeePercentage;
    return percentageFee + platformFeeFixed;
  }

  Future<void> _updatePaymentStatus(
      String paymentId, PaymentStatus status) async {
    await _db.collection('payments').doc(paymentId).update({
      'status': status.index,
      if (status == PaymentStatus.completed)
        'completedAt': FieldValue.serverTimestamp(),
      if (status == PaymentStatus.failed)
        'failureReason': 'Payment processing failed',
    });
  }

  Future<void> _updateBookingPaymentStatus(
      String bookingId, BookingStatus status) async {
    await _db.collection('bookings').doc(bookingId).update({
      'status': status.index,
      'paidAt': FieldValue.serverTimestamp(),
    });
  }

  // Refund processing
  Future<bool> processRefund({
    required String paymentId,
    required String reason,
    double? amount, // Partial refund support
  }) async {
    try {
      final paymentDoc = await _db.collection('payments').doc(paymentId).get();
      if (!paymentDoc.exists) return false;

      final payment = PaymentModel.fromMap(paymentDoc.data()!);
      if (!payment.canRefund) return false;

      final refundAmount = amount ?? payment.amount;

      // Process refund with payment provider
      final refundSuccess =
          await _processRefundWithProvider(payment, refundAmount);

      if (refundSuccess) {
        await _db.collection('payments').doc(paymentId).update({
          'status': PaymentStatus.refunded.index,
          'refundedAt': FieldValue.serverTimestamp(),
          'refundReason': reason,
          'metadata': {
            ...?payment.metadata,
            'refundAmount': refundAmount,
            'refundId': 'ref_${DateTime.now().millisecondsSinceEpoch}',
          },
        });

        // Update booking status
        await _db.collection('bookings').doc(payment.bookingId).update({
          'status': BookingStatus.refunded.index,
        });

        // Get booking details for notification
        final bookingDoc =
            await _db.collection('bookings').doc(payment.bookingId).get();
        final bookingData = bookingDoc.data();
        final tourTitle = bookingData?['tourTitle'] ?? 'Tour';

        // Create refund notification
        if (refundAmount < payment.amount) {
          // Partial refund
          final partialRefundNotification =
              _notificationService.createPartialRefundNotification(
            userId: payment.userId,
            amount: refundAmount,
            tourTitle: tourTitle,
            reason: reason,
          );
          await _notificationService
              .createNotification(partialRefundNotification);
        } else {
          // Full refund
          final refundNotification =
              _notificationService.createRefundProcessedNotification(
            userId: payment.userId,
            amount: refundAmount,
            tourTitle: tourTitle,
          );
          await _notificationService.createNotification(refundNotification);
        }

        return true;
      }

      return false;
    } catch (e) {
      print('Refund processing error: $e');
      return false;
    }
  }

  Future<bool> _processRefundWithProvider(
      PaymentModel payment, double amount) async {
    // Simulate refund processing
    await Future.delayed(const Duration(seconds: 1));
    return true; // Simulate success
  }

  // Payment retrieval methods
  Future<List<PaymentModel>> getUserPayments(String userId) async {
    print('PaymentService: getUserPayments called for userId: $userId');
    try {
      final snapshot = await _db
          .collection('payments')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      final payments =
          snapshot.docs.map((doc) => PaymentModel.fromMap(doc.data())).toList();
      print(
          'PaymentService: Found ${payments.length} user payments using query');
      return payments;
    } catch (e) {
      // If index error, fallback to getting all and filtering
      print(
          'Index error in getUserPayments, falling back to manual filtering: $e');
      final allSnapshot = await _db.collection('payments').get();
      final userPayments = allSnapshot.docs
          .map((doc) => PaymentModel.fromMap(doc.data()))
          .where((payment) => payment.userId == userId)
          .toList();
      userPayments.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      print(
          'PaymentService: Found ${userPayments.length} user payments using manual filtering');
      return userPayments;
    }
  }

  Future<List<PaymentModel>> getGuidePayments(String guideId) async {
    try {
      final snapshot = await _db
          .collection('payments')
          .where('guideId', isEqualTo: guideId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => PaymentModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      // If index error, fallback to getting all and filtering
      print(
          'Index error in getGuidePayments, falling back to manual filtering: $e');
      final allSnapshot = await _db.collection('payments').get();
      final guidePayments = allSnapshot.docs
          .map((doc) => PaymentModel.fromMap(doc.data()))
          .where((payment) => payment.guideId == guideId)
          .toList();
      guidePayments.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return guidePayments;
    }
  }

  Future<List<PaymentModel>> getAllPayments() async {
    final snapshot = await _db
        .collection('payments')
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => PaymentModel.fromMap(doc.data()))
        .toList();
  }

  Future<PaymentModel?> getPaymentById(String paymentId) async {
    final doc = await _db.collection('payments').doc(paymentId).get();
    if (doc.exists) {
      return PaymentModel.fromMap(doc.data()!);
    }
    return null;
  }

  Future<PaymentModel?> getPaymentByBookingId(String bookingId) async {
    final snapshot = await _db
        .collection('payments')
        .where('bookingId', isEqualTo: bookingId)
        .limit(1)
        .get();

    if (snapshot.docs.isNotEmpty) {
      return PaymentModel.fromMap(snapshot.docs.first.data());
    }
    return null;
  }

  // Analytics methods
  Future<Map<String, dynamic>> getPaymentAnalytics() async {
    final payments = await getAllPayments();

    final totalRevenue = payments
        .where((p) => p.isCompleted)
        .fold(0.0, (sum, p) => sum + p.amount);

    final totalPlatformFees = payments
        .where((p) => p.isCompleted)
        .fold(0.0, (sum, p) => sum + p.platformFee);

    final paymentMethodStats = <PaymentMethod, int>{};
    for (final payment in payments) {
      paymentMethodStats[payment.paymentMethod] =
          (paymentMethodStats[payment.paymentMethod] ?? 0) + 1;
    }

    return {
      'totalRevenue': totalRevenue,
      'totalPlatformFees': totalPlatformFees,
      'totalPayments': payments.length,
      'completedPayments': payments.where((p) => p.isCompleted).length,
      'failedPayments': payments.where((p) => p.isFailed).length,
      'paymentMethodStats': paymentMethodStats,
    };
  }

  // Webhook handling for payment status updates
  Future<void> handlePaymentWebhook(Map<String, dynamic> webhookData) async {
    // Handle webhooks from payment providers
    // Update payment status based on webhook data
    final paymentId = webhookData['paymentId'];
    final status = webhookData['status'];

    if (paymentId != null && status != null) {
      PaymentStatus paymentStatus;
      switch (status) {
        case 'succeeded':
          paymentStatus = PaymentStatus.completed;
          break;
        case 'failed':
          paymentStatus = PaymentStatus.failed;
          break;
        case 'cancelled':
          paymentStatus = PaymentStatus.cancelled;
          break;
        default:
          return;
      }

      await _updatePaymentStatus(paymentId, paymentStatus);
    }
  }
}

// Extension to copy PaymentModel with modifications
extension PaymentModelCopy on PaymentModel {
  PaymentModel copyWith({
    String? id,
    String? bookingId,
    String? userId,
    String? guideId,
    double? amount,
    double? platformFee,
    double? guideAmount,
    PaymentMethod? paymentMethod,
    PaymentStatus? status,
    DateTime? createdAt,
    DateTime? completedAt,
    DateTime? refundedAt,
    String? transactionId,
    String? failureReason,
    String? refundReason,
    Map<String, dynamic>? paymentDetails,
    Map<String, dynamic>? metadata,
  }) {
    return PaymentModel(
      id: id ?? this.id,
      bookingId: bookingId ?? this.bookingId,
      userId: userId ?? this.userId,
      guideId: guideId ?? this.guideId,
      amount: amount ?? this.amount,
      platformFee: platformFee ?? this.platformFee,
      guideAmount: guideAmount ?? this.guideAmount,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      refundedAt: refundedAt ?? this.refundedAt,
      transactionId: transactionId ?? this.transactionId,
      failureReason: failureReason ?? this.failureReason,
      refundReason: refundReason ?? this.refundReason,
      paymentDetails: paymentDetails ?? this.paymentDetails,
      metadata: metadata ?? this.metadata,
    );
  }
}
