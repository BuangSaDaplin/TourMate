import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tourmate_app/models/payment_model.dart';
import 'package:tourmate_app/services/payment_service.dart';
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
            Tab(text: 'Issues'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(),
          _buildAllPaymentsTab(),
          _buildIssuesTab(),
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
                          Icons.attach_money,
                          AppTheme.successColor,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildAnalyticsCard(
                          'Platform Fees',
                          '₱${analytics['totalPlatformFees'].toStringAsFixed(0)}',
                          Icons.account_balance_wallet,
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
                          Icons.payment,
                          AppTheme.accentColor,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildAnalyticsCard(
                          'Success Rate',
                          '${((analytics['completedPayments'] / analytics['totalPayments'] * 100)).toStringAsFixed(1)}%',
                          Icons.trending_up,
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

  Widget _buildIssuesTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('payments')
          .where('status', whereIn: [
            PaymentStatus.failed.index,
            PaymentStatus.cancelled.index,
            PaymentStatus.disputed.index,
          ])
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final issuePayments = snapshot.data!.docs
            .map((doc) =>
                PaymentModel.fromMap(doc.data() as Map<String, dynamic>))
            .toList();

        if (issuePayments.isEmpty) {
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
                  'No payment issues found',
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
          itemCount: issuePayments.length,
          itemBuilder: (context, index) {
            return _buildIssueCard(issuePayments[index]);
          },
        );
      },
    );
  }

  Widget _buildAnalyticsCard(
      String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
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
}
