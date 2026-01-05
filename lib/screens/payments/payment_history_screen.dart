import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tourmate_app/models/payment_model.dart';
import 'package:tourmate_app/services/auth_service.dart';
import 'package:tourmate_app/services/payment_service.dart';
import 'package:tourmate_app/services/user_profile_service.dart';
import '../../utils/app_theme.dart';

class PaymentHistoryScreen extends StatefulWidget {
  const PaymentHistoryScreen({super.key});

  @override
  State<PaymentHistoryScreen> createState() => _PaymentHistoryScreenState();
}

class _PaymentHistoryScreenState extends State<PaymentHistoryScreen> {
  final AuthService _authService = AuthService();
  final PaymentService _paymentService = PaymentService();
  final UserProfileService _userProfileService = UserProfileService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Payment History'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: StreamBuilder<List<PaymentModel>>(
        stream: _getPaymentHistory(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: AppTheme.errorColor.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Failed to load payment history',
                    style: AppTheme.bodyLarge.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final payments = snapshot.data ?? [];

          if (payments.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.payment,
                    size: 64,
                    color: AppTheme.textSecondary.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No payment history found',
                    style: AppTheme.bodyLarge.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your completed payments will appear here',
                    style: AppTheme.bodySmall.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: payments.length,
            itemBuilder: (context, index) {
              return _buildPaymentCard(payments[index]);
            },
          );
        },
      ),
    );
  }

  Stream<List<PaymentModel>> _getPaymentHistory() async* {
    final user = _authService.getCurrentUser();
    if (user == null) {
      yield [];
      return;
    }

    final userProfile =
        await _userProfileService.getCompleteUserProfile(user.uid);
    final isGuide = userProfile?.role == 'guide';

    final payments = isGuide
        ? await _paymentService.getGuidePayments(user.uid)
        : await _paymentService.getUserPayments(user.uid);

    yield payments;
  }

  Future<bool> _isTourist() async {
    final user = _authService.getCurrentUser();
    if (user == null) return false;

    final userProfile =
        await _userProfileService.getCompleteUserProfile(user.uid);
    return userProfile?.role != 'guide';
  }

  Widget _buildPaymentCard(PaymentModel payment) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _showPaymentDetails(payment),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with status and amount
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: payment.statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      payment.statusDisplayText,
                      style: AppTheme.bodySmall.copyWith(
                        color: payment.statusColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Text(
                    '₱${payment.amount.toStringAsFixed(2)}',
                    style: AppTheme.headlineSmall.copyWith(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Payment method and date
              Row(
                children: [
                  Icon(
                    payment.paymentMethodIcon,
                    size: 20,
                    color: AppTheme.textSecondary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    payment.paymentMethodDisplayText,
                    style: AppTheme.bodyMedium,
                  ),
                  const Spacer(),
                  Text(
                    _formatDate(payment.createdAt),
                    style: AppTheme.bodySmall.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Transaction ID
              if (payment.transactionId != null)
                Text(
                  'Transaction: ${payment.transactionId}',
                  style: AppTheme.bodySmall.copyWith(
                    color: AppTheme.textSecondary,
                    fontFamily: 'monospace',
                  ),
                ),

              // Fee breakdown for completed payments
              if (payment.isCompleted) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.backgroundColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      _buildFeeRow(
                          'Tour Amount', payment.amount - payment.platformFee),
                      _buildFeeRow('Platform Fee', payment.platformFee),
                      const Divider(),
                      _buildFeeRow('Guide Receives', payment.guideAmount,
                          isTotal: true),
                    ],
                  ),
                ),
              ],

              // Action button for failed/refundable payments (only for tourists)
              FutureBuilder<bool>(
                future: _isTourist(),
                builder: (context, snapshot) {
                  final isTourist = snapshot.data ?? false;
                  if (!isTourist || (!payment.canRefund && !payment.isFailed)) {
                    return const SizedBox.shrink();
                  }
                  return Column(
                    children: [
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () => payment.canRefund
                              ? _requestRefund(payment)
                              : _retryPayment(payment),
                          icon: Icon(
                            payment.canRefund ? Icons.replay : Icons.refresh,
                            size: 16,
                          ),
                          label: Text(
                            payment.canRefund
                                ? 'Request Refund'
                                : 'Retry Payment',
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: payment.canRefund
                                ? AppTheme.errorColor
                                : AppTheme.primaryColor,
                            side: BorderSide(
                              color: payment.canRefund
                                  ? AppTheme.errorColor
                                  : AppTheme.primaryColor,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeeRow(String label, double amount, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: isTotal
                ? AppTheme.bodySmall.copyWith(fontWeight: FontWeight.w600)
                : AppTheme.bodySmall,
          ),
          Text(
            '₱${amount.toStringAsFixed(2)}',
            style: isTotal
                ? AppTheme.bodySmall.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.successColor,
                  )
                : AppTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  void _showPaymentDetails(PaymentModel payment) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Payment Details',
              style: AppTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            _buildDetailRow('Payment ID', payment.id),
            _buildDetailRow('Booking ID', payment.bookingId),
            _buildDetailRow('Amount', '₱${payment.amount.toStringAsFixed(2)}'),
            _buildDetailRow('Method', payment.paymentMethodDisplayText),
            _buildDetailRow('Status', payment.statusDisplayText),
            _buildDetailRow('Date', _formatDate(payment.createdAt)),
            if (payment.transactionId != null)
              _buildDetailRow('Transaction ID', payment.transactionId!),
            if (payment.completedAt != null)
              _buildDetailRow('Completed', _formatDate(payment.completedAt!)),
            if (payment.failureReason != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.errorColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Failure Reason',
                      style: AppTheme.bodySmall.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.errorColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      payment.failureReason!,
                      style: AppTheme.bodySmall.copyWith(
                        color: AppTheme.errorColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),
            if (payment.canRefund)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _requestRefund(payment);
                  },
                  icon: const Icon(Icons.replay, size: 16),
                  label: const Text('Request Refund'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.errorColor,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: AppTheme.bodySmall.copyWith(
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }

  void _requestRefund(PaymentModel payment) {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Request Refund'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Request a refund for ₱${payment.amount.toStringAsFixed(2)}',
              style: AppTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Reason for refund',
                hintText: 'Please explain why you want a refund',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              if (reasonController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please provide a reason for the refund'),
                    backgroundColor: Colors.orange,
                  ),
                );
                return;
              }

              Navigator.pop(context);

              try {
                final success = await _paymentService.processRefund(
                  paymentId: payment.id,
                  reason: reasonController.text.trim(),
                );

                if (success && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Refund request submitted successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } else if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Failed to process refund request'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: ${e.toString()}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: TextButton.styleFrom(foregroundColor: AppTheme.errorColor),
            child: const Text('Request Refund'),
          ),
        ],
      ),
    );
  }

  void _retryPayment(PaymentModel payment) {
    // Navigate to payment screen with retry option
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Retry payment feature coming soon'),
        backgroundColor: Colors.blue,
      ),
    );
  }
}
