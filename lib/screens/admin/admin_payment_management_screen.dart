import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tourmate_app/models/payment_model.dart';
import 'package:tourmate_app/models/booking_model.dart';
import 'package:tourmate_app/models/user_model.dart';
import 'package:tourmate_app/services/payment_service.dart';
import 'package:tourmate_app/services/database_service.dart';
import '../../utils/app_theme.dart';

class AdminPaymentManagementScreen extends StatefulWidget {
  const AdminPaymentManagementScreen({super.key});

  @override
  State<AdminPaymentManagementScreen> createState() =>
      _AdminPaymentManagementScreenState();
}

class _AdminPaymentManagementScreenState
    extends State<AdminPaymentManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final PaymentService _paymentService = PaymentService();
  final DatabaseService _databaseService = DatabaseService();

  String _selectedStatus = 'All';
  String _selectedMethod = 'All';
  String _searchQuery = '';

  final List<String> _statusFilters = [
    'All',
    'Pending',
    'Processing',
    'Completed',
    'Failed',
    'Cancelled',
    'Refunded',
  ];

  final List<String> _methodFilters = [
    'All',
    'Credit Card',
    'Debit Card',
    'PayPal',
    'GCash',
    'PayMaya',
    'Bank Transfer',
    'Cash',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
        title: const Text('Payment Management'),
        backgroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primaryColor,
          unselectedLabelColor: AppTheme.textSecondary,
          indicatorColor: AppTheme.primaryColor,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'All Payments'),
            Tab(text: 'Refund Requests'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(),
          _buildAllPaymentsTab(),
          _buildRefundRequestsTab(),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Payment Overview', style: AppTheme.headlineMedium),
          const SizedBox(height: 24),

          // Analytics Cards
          FutureBuilder<Map<String, dynamic>>(
            future: _paymentService.getPaymentAnalytics(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final analytics = snapshot.data!;

              return Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildAnalyticsCard(
                          'Total Revenue',
                          '₱${analytics['totalRevenue'].toStringAsFixed(0)}',
                          Text('₱',
                              style: TextStyle(
                                  color: AppTheme.accentColor,
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold)),
                          AppTheme.accentColor,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildAnalyticsCard(
                          'Platform Fees',
                          '₱${analytics['totalPlatformFees'].toStringAsFixed(0)}',
                          Icon(Icons.account_balance_wallet,
                              color: AppTheme.primaryColor, size: 32),
                          AppTheme.primaryColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildAnalyticsCard(
                          'Total Payments',
                          analytics['totalPayments'].toString(),
                          Icon(Icons.payment,
                              color: AppTheme.accentColor, size: 32),
                          AppTheme.accentColor,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildAnalyticsCard(
                          'Success Rate',
                          '${((analytics['completedPayments'] / analytics['totalPayments'] * 100)).toStringAsFixed(1)}%',
                          Icon(Icons.trending_up,
                              color: AppTheme.accentColor, size: 32),
                          AppTheme.accentColor,
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 32),

          // Payment Method Distribution
          Text('Payment Methods', style: AppTheme.headlineSmall),
          const SizedBox(height: 16),

          FutureBuilder<Map<String, dynamic>>(
            future: _paymentService.getPaymentAnalytics(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final analytics = snapshot.data!;
              final methodStats =
                  analytics['paymentMethodStats'] as Map<PaymentMethod, int>;

              return Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: methodStats.entries.map((entry) {
                      final percentage =
                          (entry.value / analytics['totalPayments'] * 100)
                              .toStringAsFixed(1);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          children: [
                            Icon(entry.key.paymentMethodIcon,
                                color: AppTheme.primaryColor),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                entry.key.paymentMethodDisplayText,
                                style: AppTheme.bodyMedium,
                              ),
                            ),
                            Text(
                              '${entry.value} (${percentage}%)',
                              style: AppTheme.bodyMedium
                                  .copyWith(fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 32),

          // Recent Payments
          Text('Recent Payments', style: AppTheme.headlineSmall),
          const SizedBox(height: 16),

          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('payments')
                .orderBy('createdAt', descending: true)
                .limit(5)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final recentPayments = snapshot.data!.docs
                  .map((doc) =>
                      PaymentModel.fromMap(doc.data() as Map<String, dynamic>))
                  .toList();

              return Column(
                children: recentPayments
                    .map((payment) => _buildRecentPaymentItem(payment))
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAllPaymentsTab() {
    return Column(
      children: [
        // Filters
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: Column(
            children: [
              // Search
              TextField(
                decoration: InputDecoration(
                  hintText: 'Search by payment ID, booking ID, or user...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
              ),
              const SizedBox(height: 12),

              // Status and Method Filters
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedStatus,
                      decoration: InputDecoration(
                        labelText: 'Status',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      items: _statusFilters.map((status) {
                        return DropdownMenuItem(
                          value: status,
                          child: Text(status),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedStatus = value!;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedMethod,
                      decoration: InputDecoration(
                        labelText: 'Method',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      items: _methodFilters.map((method) {
                        return DropdownMenuItem(
                          value: method,
                          child: Text(method),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedMethod = value!;
                        });
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Payments List
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('payments')
                .orderBy('createdAt', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              var payments = snapshot.data!.docs
                  .map((doc) =>
                      PaymentModel.fromMap(doc.data() as Map<String, dynamic>))
                  .toList();

              // Apply filters
              if (_selectedStatus != 'All') {
                payments = payments.where((payment) {
                  switch (_selectedStatus) {
                    case 'Pending':
                      return payment.status == PaymentStatus.pending;
                    case 'Processing':
                      return payment.status == PaymentStatus.processing;
                    case 'Completed':
                      return payment.status == PaymentStatus.completed;
                    case 'Failed':
                      return payment.status == PaymentStatus.failed;
                    case 'Cancelled':
                      return payment.status == PaymentStatus.cancelled;
                    case 'Refunded':
                      return payment.status == PaymentStatus.refunded;
                    default:
                      return true;
                  }
                }).toList();
              }

              if (_selectedMethod != 'All') {
                payments = payments.where((payment) {
                  return payment.paymentMethodDisplayText == _selectedMethod;
                }).toList();
              }

              // Apply search
              if (_searchQuery.isNotEmpty) {
                payments = payments.where((payment) {
                  return payment.id.contains(_searchQuery) ||
                      payment.bookingId.contains(_searchQuery) ||
                      payment.userId.contains(_searchQuery);
                }).toList();
              }

              if (payments.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.search_off,
                        size: 64,
                        color: AppTheme.textSecondary.withOpacity(0.5),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No payments found',
                        style: AppTheme.bodyLarge.copyWith(
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
        ),
      ],
    );
  }

  Widget _buildRefundRequestsTab() {
    return FutureBuilder<List<BookingModel>>(
      future: _databaseService.getRefundRequests(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

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
                  'Failed to load refund requests',
                  style: AppTheme.bodyLarge.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          );
        }

        final refundRequests = snapshot.data ?? [];

        if (refundRequests.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.check_circle,
                  size: 64,
                  color: AppTheme.successColor.withOpacity(0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  'No refund requests found',
                  style: AppTheme.bodyLarge.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: refundRequests.length,
          itemBuilder: (context, index) {
            return _buildRefundRequestCard(refundRequests[index]);
          },
        );
      },
    );
  }

  Widget _buildAnalyticsCard(
      String title, String value, Widget iconWidget, Color color) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            iconWidget,
            const SizedBox(height: 8),
            Text(
              value,
              style: AppTheme.headlineSmall.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: AppTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentPaymentItem(PaymentModel payment) {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: payment.statusColor.withOpacity(0.1),
          child: Icon(
            payment.paymentMethodIcon,
            color: payment.statusColor,
          ),
        ),
        title: Text(
          '₱${payment.amount.toStringAsFixed(2)} - ${payment.paymentMethodDisplayText}',
          style: AppTheme.bodyMedium.copyWith(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          'Booking: ${payment.bookingId} • ${payment.statusDisplayText}',
          style: AppTheme.bodySmall,
        ),
        trailing: Text(
          '${payment.createdAt.day}/${payment.createdAt.month}',
          style: AppTheme.bodySmall.copyWith(color: AppTheme.textSecondary),
        ),
      ),
    );
  }

  Widget _buildPaymentCard(PaymentModel payment) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
            Text(
              'Payment ID: ${payment.id}',
              style: AppTheme.bodyLarge.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.book_online,
                    size: 16, color: AppTheme.textSecondary),
                const SizedBox(width: 4),
                Text(
                  'Booking: ${payment.bookingId}',
                  style: AppTheme.bodySmall,
                ),
                const SizedBox(width: 16),
                Icon(Icons.person, size: 16, color: AppTheme.textSecondary),
                const SizedBox(width: 4),
                Text(
                  'User: ${payment.userId}',
                  style: AppTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(payment.paymentMethodIcon,
                    size: 16, color: AppTheme.textSecondary),
                const SizedBox(width: 4),
                Text(
                  payment.paymentMethodDisplayText,
                  style: AppTheme.bodySmall,
                ),
                const SizedBox(width: 16),
                Icon(Icons.access_time,
                    size: 16, color: AppTheme.textSecondary),
                const SizedBox(width: 4),
                Text(
                  '${payment.createdAt.day}/${payment.createdAt.month}/${payment.createdAt.year}',
                  style: AppTheme.bodySmall,
                ),
              ],
            ),
            if (payment.transactionId != null) ...[
              const SizedBox(height: 8),
              Text(
                'Transaction: ${payment.transactionId}',
                style: AppTheme.bodySmall.copyWith(
                  color: AppTheme.textSecondary,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildIssueCard(PaymentModel payment) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                IconButton(
                  icon: const Icon(Icons.more_vert),
                  onPressed: () => _showIssueActions(payment),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Payment ID: ${payment.id}',
              style: AppTheme.bodyLarge.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              'Amount: ₱${payment.amount.toStringAsFixed(2)}',
              style: AppTheme.bodyMedium,
            ),
            const SizedBox(height: 4),
            Text(
              'Method: ${payment.paymentMethodDisplayText}',
              style: AppTheme.bodySmall.copyWith(color: AppTheme.textSecondary),
            ),
            if (payment.failureReason != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.errorColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.warning, size: 16, color: AppTheme.errorColor),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        payment.failureReason!,
                        style: AppTheme.bodySmall
                            .copyWith(color: AppTheme.errorColor),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRefundRequestCard(BookingModel booking) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getRefundStatusColor(booking.refundStatus)
                        .withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _getRefundStatusText(booking.refundStatus),
                    style: AppTheme.bodySmall.copyWith(
                      color: _getRefundStatusColor(booking.refundStatus),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.more_vert),
                  onPressed: () => _showRefundActions(booking),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              booking.tourTitle,
              style: AppTheme.bodyLarge.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.person, size: 16, color: AppTheme.textSecondary),
                const SizedBox(width: 4),
                Text(
                  'Tourist ID: ${booking.touristId}',
                  style: AppTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Total Price: ₱${booking.totalPrice.toStringAsFixed(2)}',
              style: AppTheme.bodyMedium,
            ),
            if (booking.refundStatus == RefundStatus.processingRefund ||
                booking.refundStatus == RefundStatus.approvedRefund) ...[
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.successColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Refund Breakdown',
                      style: AppTheme.bodySmall.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.successColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Refund Amount: ₱${(booking.paymentDetails?['refundAmount'] ?? booking.totalPrice).toStringAsFixed(2)} (${(booking.paymentDetails?['refundPercentage'] ?? 100).toStringAsFixed(0)}%)',
                      style: AppTheme.bodySmall.copyWith(
                        color: AppTheme.successColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 4),
            Text(
              'Requested: ${_formatDate(booking.requestedAt ?? booking.bookingDate)}',
              style: AppTheme.bodySmall.copyWith(color: AppTheme.textSecondary),
            ),
            if (booking.refundReason != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.backgroundColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Refund Reason',
                      style: AppTheme.bodySmall.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      booking.refundReason!,
                      style: AppTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showIssueActions(PaymentModel payment) {
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
              'Issue Actions',
              style: AppTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.info),
              title: const Text('View Details'),
              onTap: () {
                Navigator.pop(context);
                // Navigate to detailed payment view
              },
            ),
            if (payment.canRefund)
              ListTile(
                leading: const Icon(Icons.replay),
                title: const Text('Process Refund'),
                onTap: () {
                  Navigator.pop(context);
                  _processRefund(payment);
                },
              ),
            ListTile(
              leading: const Icon(Icons.message),
              title: const Text('Contact User'),
              onTap: () {
                Navigator.pop(context);
                // Open messaging interface
              },
            ),
            ListTile(
              leading: const Icon(Icons.report),
              title: const Text('Generate Report'),
              onTap: () {
                Navigator.pop(context);
                // Generate payment issue report
              },
            ),
          ],
        ),
      ),
    );
  }

  void _processRefund(PaymentModel payment) {
    final amountController =
        TextEditingController(text: payment.amount.toString());
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Process Refund'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Process refund for ₱${payment.amount.toStringAsFixed(2)}',
              style: AppTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: amountController,
              decoration: const InputDecoration(
                labelText: 'Refund Amount',
                hintText: 'Enter amount to refund',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Reason',
                hintText: 'Reason for refund',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
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
              final amount = double.tryParse(amountController.text);
              if (amount == null || amount <= 0 || amount > payment.amount) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter a valid refund amount'),
                    backgroundColor: Colors.orange,
                  ),
                );
                return;
              }

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
                  amount: amount,
                );

                if (success && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Refund processed successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } else if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Failed to process refund'),
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
            child: const Text('Process Refund'),
          ),
        ],
      ),
    );
  }

  Color _getRefundStatusColor(RefundStatus? status) {
    switch (status) {
      case RefundStatus.pendingRefund:
        return AppTheme.primaryColor;
      case RefundStatus.approvedRefund:
        return Colors.blue;
      case RefundStatus.processingRefund:
        return Colors.green;
      case RefundStatus.rejectedRefund:
        return AppTheme.errorColor;
      default:
        return AppTheme.textSecondary;
    }
  }

  String _getRefundStatusText(RefundStatus? status) {
    switch (status) {
      case RefundStatus.pendingRefund:
        return 'Pending';
      case RefundStatus.approvedRefund:
        return 'Approved';
      case RefundStatus.processingRefund:
        return 'Processing';
      case RefundStatus.rejectedRefund:
        return 'Rejected';
      default:
        return 'Unknown';
    }
  }

  void _showRefundActions(BookingModel booking) {
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
              'Refund Actions',
              style: AppTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            if (booking.refundStatus == RefundStatus.pendingRefund) ...[
              ListTile(
                leading: const Icon(Icons.check, color: Colors.green),
                title: const Text('Approve Refund Request'),
                subtitle: const Text('Calculate and set refund amount'),
                onTap: () async {
                  Navigator.pop(context);
                  try {
                    final success =
                        await _databaseService.approveRefund(booking.id);
                    if (success && mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                              'Refund approved and calculated successfully'),
                          backgroundColor: Colors.green,
                        ),
                      );
                      // Refresh the list
                      setState(() {});
                    } else if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Failed to approve refund'),
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
              ),
              ListTile(
                leading: const Icon(Icons.close, color: Colors.red),
                title: const Text('Reject Refund'),
                onTap: () => _showRejectRefundDialog(booking),
              ),
            ] else if (booking.refundStatus ==
                RefundStatus.processingRefund) ...[
              ListTile(
                leading: const Icon(Icons.payment, color: Colors.blue),
                title: const Text('Approve Refund Payment'),
                subtitle: const Text('Transfer funds to user wallet'),
                onTap: () async {
                  Navigator.pop(context);
                  try {
                    final success =
                        await _databaseService.processRefund(booking.id);
                    if (success && mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content:
                              Text('Refund payment processed successfully'),
                          backgroundColor: Colors.green,
                        ),
                      );
                      // Refresh the list
                      setState(() {});
                    } else if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Failed to process refund payment'),
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
              ),
              ListTile(
                leading: const Icon(Icons.close, color: Colors.red),
                title: const Text('Reject Refund'),
                subtitle: const Text('Reject the refund request'),
                onTap: () => _showRejectRefundDialog(booking),
              ),
            ],
            ListTile(
              leading: const Icon(Icons.info),
              title: const Text('View Details'),
              onTap: () {
                Navigator.pop(context);
                _showRefundDetailsDialog(booking);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showRejectRefundDialog(BookingModel booking) {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Refund'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Provide a reason for rejecting the refund request for "${booking.tourTitle}"',
              style: AppTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Rejection Reason',
                hintText: 'Explain why the refund is being rejected',
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
                    content: Text('Please provide a reason for rejection'),
                    backgroundColor: Colors.orange,
                  ),
                );
                return;
              }

              Navigator.pop(context); // Close reject dialog
              Navigator.pop(context); // Close actions sheet

              try {
                final success = await _databaseService.rejectRefund(
                  booking.id,
                  reasonController.text.trim(),
                );

                if (success && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Refund rejected successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } else if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Failed to reject refund'),
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
            child: const Text('Reject Refund'),
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

  void _showRefundDetailsDialog(BookingModel booking) {
    showDialog(
      context: context,
      builder: (context) => _RefundDetailsDialog(booking: booking),
    );
  }
}

class _RefundDetailsDialog extends StatefulWidget {
  final BookingModel booking;

  const _RefundDetailsDialog({
    required this.booking,
  });

  @override
  State<_RefundDetailsDialog> createState() => _RefundDetailsDialogState();
}

class _RefundDetailsDialogState extends State<_RefundDetailsDialog> {
  final DatabaseService _databaseService = DatabaseService();
  final PaymentService _paymentService = PaymentService();

  UserModel? _tourist;
  UserModel? _guide;
  PaymentModel? _payment;

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDetails();
  }

  Future<void> _loadDetails() async {
    try {
      // Load tourist information
      _tourist = await _databaseService.getUser(widget.booking.touristId);

      // Load guide information
      if (widget.booking.guideId != null) {
        _guide = await _databaseService.getUser(widget.booking.guideId!);
      }

      // Load payment information
      _payment = await _paymentService.getPaymentByBookingId(widget.booking.id);

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading refund details: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.9,
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.receipt_long,
                    color: Colors.white,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Refund Details',
                      style: AppTheme.headlineMedium.copyWith(
                        color: Colors.white,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      Icons.close,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Booking Information Section
                          _buildSectionHeader('Booking Information'),
                          _buildInfoCard([
                            _buildInfoRow('Booking ID', widget.booking.id),
                            _buildInfoRow(
                                'Tour Title', widget.booking.tourTitle),
                            _buildInfoRow('Tour ID', widget.booking.tourId),
                            _buildInfoRow(
                              'Tour Date',
                              _formatDate(widget.booking.tourStartDate),
                            ),
                            _buildInfoRow(
                              'Booking Date',
                              _formatDate(widget.booking.bookingDate),
                            ),
                            _buildInfoRow(
                              'Number of Participants',
                              widget.booking.numberOfParticipants.toString(),
                            ),
                            _buildInfoRow(
                              'Total Booking Price',
                              '₱${widget.booking.totalPrice.toStringAsFixed(2)}',
                            ),
                          ]),

                          const SizedBox(height: 24),

                          // Tourist Information Section
                          _buildSectionHeader('Tourist Information'),
                          _buildInfoCard([
                            _buildInfoRow(
                                'Tourist ID', widget.booking.touristId),
                            _buildInfoRow(
                              'Tourist Full Name',
                              _tourist?.displayName ?? 'Not available',
                            ),
                            _buildInfoRow(
                              'Contact Number',
                              _tourist?.phoneNumber ?? 'Not available',
                            ),
                            _buildInfoRow(
                              'Email',
                              _tourist?.email ?? 'Not available',
                            ),
                          ]),

                          const SizedBox(height: 24),

                          // Guide Information Section
                          _buildSectionHeader('Guide Information'),
                          _buildInfoCard([
                            _buildInfoRow(
                              'Guide ID',
                              widget.booking.guideId ?? 'Not assigned',
                            ),
                            _buildInfoRow(
                              'Guide Name',
                              _guide?.displayName ?? 'Not available',
                            ),
                            _buildInfoRow(
                              'Contact Number',
                              _guide?.phoneNumber ?? 'Not available',
                            ),
                            _buildInfoRow(
                              'Email',
                              _guide?.email ?? 'Not available',
                            ),
                          ]),

                          const SizedBox(height: 24),

                          // Payment Information Section
                          _buildSectionHeader('Payment Information'),
                          _buildInfoCard([
                            _buildInfoRow(
                              'Payment ID',
                              _payment?.id ?? 'Not available',
                            ),
                            _buildInfoRow(
                              'Payment Method',
                              _payment?.paymentMethodDisplayText ??
                                  'Not available',
                            ),
                            _buildInfoRow(
                              'Payment Date',
                              _payment?.completedAt != null
                                  ? _formatDate(_payment!.completedAt!)
                                  : 'Not available',
                            ),
                            _buildInfoRow(
                              'Payment Status',
                              _payment?.statusDisplayText ?? 'Not available',
                            ),
                            _buildInfoRow(
                              'Platform Fee',
                              _payment != null
                                  ? '₱${_payment!.platformFee.toStringAsFixed(2)}'
                                  : 'Not available',
                            ),
                            _buildInfoRow(
                              'Guide Amount',
                              _payment != null
                                  ? '₱${_payment!.guideAmount.toStringAsFixed(2)}'
                                  : 'Not available',
                            ),
                          ]),

                          const SizedBox(height: 24),

                          // Refund Request Information Section
                          _buildSectionHeader('Refund Request Information'),
                          _buildInfoCard([
                            _buildInfoRow(
                              'Refund Status',
                              _getRefundStatusText(widget.booking.refundStatus),
                            ),
                            _buildInfoRow(
                              'Refund Reason',
                              widget.booking.refundReason ?? 'Not provided',
                            ),
                            _buildInfoRow(
                              'Refund Requested Date',
                              widget.booking.requestedAt != null
                                  ? _formatDate(widget.booking.requestedAt!)
                                  : 'Not available',
                            ),
                            _buildInfoRow(
                              'Refund Amount',
                              _calculateRefundAmount(),
                            ),
                            _buildInfoRow(
                              'Refund Percentage Applied',
                              _calculateRefundPercentage(),
                            ),
                          ]),
                        ],
                      ),
                    ),
            ),

            // Actions
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                      'Close',
                      style: AppTheme.bodyMedium.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: AppTheme.headlineSmall.copyWith(
          color: AppTheme.primaryColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildInfoCard(List<Widget> children) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: children,
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: AppTheme.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: AppTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _getRefundStatusText(RefundStatus? status) {
    switch (status) {
      case RefundStatus.pendingRefund:
        return 'Pending';
      case RefundStatus.approvedRefund:
        return 'Approved';
      case RefundStatus.rejectedRefund:
        return 'Rejected';
      case RefundStatus.processingRefund:
        return 'Processing';
      default:
        return 'Unknown';
    }
  }

  String _calculateRefundAmount() {
    if (widget.booking.paymentDetails == null) return 'Not calculated';

    final refundAmount = widget.booking.paymentDetails!['refundAmount'];
    if (refundAmount != null) {
      return '₱${refundAmount.toStringAsFixed(2)}';
    }

    // Calculate based on percentage
    final percentage = _calculateRefundPercentageValue();
    final amount = widget.booking.totalPrice * (percentage / 100);
    return '₱${amount.toStringAsFixed(2)}';
  }

  String _calculateRefundPercentage() {
    final percentage = _calculateRefundPercentageValue();
    return '$percentage% → ${percentage == 100 ? 'if refund requested before the tour date' : 'if refund requested on the same date as the tour'}';
  }

  double _calculateRefundPercentageValue() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tourDate = DateTime(
      widget.booking.tourStartDate.year,
      widget.booking.tourStartDate.month,
      widget.booking.tourStartDate.day,
    );

    if (today.isBefore(tourDate)) {
      return 100.0; // Full refund if requested before tour date
    } else if (today.isAtSameMomentAs(tourDate)) {
      return 70.0; // 70% refund if requested on the same day as tour
    } else {
      return 0.0; // No refund if requested after tour date
    }
  }
}
