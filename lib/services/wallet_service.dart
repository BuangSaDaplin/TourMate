import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/payment_model.dart';

class WalletService {
  final FirebaseFirestore _firestore;

  WalletService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Get real-time balance stream for a user
  Stream<double> getBalanceStream(String userId) {
    return _firestore.collection('users').doc(userId).snapshots().map((
      snapshot,
    ) {
      final eWallet = snapshot.get('eWallet') ?? 0.0;
      return eWallet.toDouble();
    });
  }

  /// Process payment using wallet
  Future<void> payWithWallet({
    required String userId,
    required double amount,
    required String bookingId,
    required String description,
    required String referenceId,
  }) async {
    await _firestore.runTransaction((transaction) async {
      // Read current balance
      final userDoc = await transaction.get(
        _firestore.collection('users').doc(userId),
      );

      if (!userDoc.exists) {
        throw Exception('User not found');
      }

      final currentBalance = userDoc.get('eWallet') ?? 0.0;

      // Check if balance is sufficient
      if (currentBalance < amount) {
        throw Exception('Insufficient funds');
      }

      // Calculate new balance
      final newBalance = currentBalance - amount;

      // Update user's eWallet balance
      transaction.update(_firestore.collection('users').doc(userId), {
        'eWallet': newBalance,
      });

      // Add transaction record
      final transactionRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('transactions')
          .doc();

      final transactionData = {
        'id': transactionRef.id,
        'amount': -amount, // Negative for payment
        'type': 'payment',
        'description': description,
        'timestamp': DateTime.now(),
        'referenceId': referenceId,
        'bookingId': bookingId,
      };

      transaction.set(transactionRef, transactionData);
    });
  }

  /// Get transaction history for a user
  Stream<List<Map<String, dynamic>>> getTransactionHistory(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('transactions')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data();
            return {
              ...data,
              'id': doc.id,
              'timestamp': (data['timestamp'] as Timestamp).toDate(),
            };
          }).toList();
        });
  }

  /// Add funds to wallet
  Future<void> addFunds({
    required String userId,
    required double amount,
    required String description,
    required String referenceId,
  }) async {
    await _firestore.runTransaction((transaction) async {
      final userDoc = await transaction.get(
        _firestore.collection('users').doc(userId),
      );

      if (!userDoc.exists) {
        throw Exception('User not found');
      }

      final currentBalance = userDoc.get('eWallet') ?? 0.0;
      final newBalance = currentBalance + amount;

      // Update user's eWallet balance
      transaction.update(_firestore.collection('users').doc(userId), {
        'eWallet': newBalance,
      });

      // Add transaction record
      final transactionRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('transactions')
          .doc();

      final transactionData = {
        'id': transactionRef.id,
        'amount': amount, // Positive for deposit
        'type': 'deposit',
        'description': description,
        'timestamp': DateTime.now(),
        'referenceId': referenceId,
      };

      transaction.set(transactionRef, transactionData);
    });
  }

  /// Get user's current balance
  Future<double> getCurrentBalance(String userId) async {
    final userDoc = await _firestore.collection('users').doc(userId).get();
    return (userDoc.get('eWallet') ?? 0.0).toDouble();
  }
}
