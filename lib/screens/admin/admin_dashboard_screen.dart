import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/database_service.dart';
import '../../utils/app_theme.dart';
import '../../models/user_model.dart';
import '../../models/payment_model.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final DatabaseService _databaseService = DatabaseService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        elevation: 0,
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(icon: Icon(Icons.dashboard), text: 'Overview'),
            Tab(icon: Icon(Icons.verified_user), text: 'Verifications'),
            Tab(icon: Icon(Icons.payment), text: 'Payments'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(),
          _buildVerificationsTab(),
          _buildPaymentsTab(),
        ],
      ),
    );
  }

  // TAB 1: OVERVIEW
  Widget _buildOverviewTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Platform Overview', style: AppTheme.headlineMedium),
          const SizedBox(height: 24),
          Expanded(
            child: Row(
              children: [
                // Total Users Card
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: _firestore.collection('users').snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return _buildErrorCard('Error loading users');
                      }

                      if (!snapshot.hasData) {
                        return _buildLoadingCard('Loading users...');
                      }

                      final userCount = snapshot.data!.docs.length;
                      return _buildStatCard(
                        icon: Icons.people,
                        title: 'Total Users',
                        value: userCount.toString(),
                        color: AppTheme.primaryColor,
                      );
                    },
                  ),
                ),
                const SizedBox(width: 16),
                // Total Bookings Card
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: _firestore.collection('bookings').snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return _buildErrorCard('Error loading bookings');
                      }

                      if (!snapshot.hasData) {
                        return _buildLoadingCard('Loading bookings...');
                      }

                      final bookingCount = snapshot.data!.docs.length;
                      return _buildStatCard(
                        icon: Icons.book_online,
                        title: 'Total Bookings',
                        value: bookingCount.toString(),
                        color: AppTheme.accentColor,
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Row(
              children: [
                // Active Tours Card
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: _firestore
                        .collection('tours')
                        .where('status', isEqualTo: 'active')
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return _buildErrorCard('Error loading tours');
                      }

                      if (!snapshot.hasData) {
                        return _buildLoadingCard('Loading tours...');
                      }

                      final tourCount = snapshot.data!.docs.length;
                      return _buildStatCard(
                        icon: Icons.tour,
                        title: 'Active Tours',
                        value: tourCount.toString(),
                        color: AppTheme.successColor,
                      );
                    },
                  ),
                ),
                const SizedBox(width: 16),
                // Pending Verifications Card
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: _firestore
                        .collection('users')
                        .where('role', isEqualTo: 'guide')
                        .where('isVerified', isEqualTo: false)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return _buildErrorCard('Error loading verifications');
                      }

                      if (!snapshot.hasData) {
                        return _buildLoadingCard('Loading verifications...');
                      }

                      final verificationCount = snapshot.data!.docs.length;
                      return _buildStatCard(
                        icon: Icons.pending_actions,
                        title: 'Pending Verifications',
                        value: verificationCount.toString(),
                        color: AppTheme.errorColor,
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Recent Activity Section
          Expanded(
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Recent Activity', style: AppTheme.headlineSmall),
                    const SizedBox(height: 16),
                    Expanded(
                      child: StreamBuilder<QuerySnapshot>(
                        stream: _firestore
                            .collection('bookings')
                            .orderBy('bookingDate', descending: true)
                            .limit(10)
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (snapshot.hasError) {
                            return Center(
                                child: Text('Error loading recent bookings'));
                          }

                          if (!snapshot.hasData ||
                              snapshot.data!.docs.isEmpty) {
                            return const Center(
                                child: Text('No recent activity'));
                          }

                          return ListView.builder(
                            itemCount: snapshot.data!.docs.length,
                            itemBuilder: (context, index) {
                              final booking = snapshot.data!.docs[index];
                              final data =
                                  booking.data() as Map<String, dynamic>;

                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundColor:
                                      AppTheme.primaryColor.withOpacity(0.1),
                                  child: Icon(Icons.book_online,
                                      color: AppTheme.primaryColor),
                                ),
                                title:
                                    Text(data['tourTitle'] ?? 'Tour Booking'),
                                subtitle: Text(
                                    'User: ${data['touristId']} • Status: ${_getStatusText(data['status'])}'),
                                trailing: Text(
                                  '${_formatDate(data['bookingDate'])}',
                                  style: AppTheme.bodySmall,
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // TAB 2: VERIFICATIONS
  Widget _buildVerificationsTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Guide Verifications', style: AppTheme.headlineMedium),
          const SizedBox(height: 16),
          Text(
            'Review and verify tour guide applications',
            style: AppTheme.bodyLarge.copyWith(color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('users')
                  .where('role', isEqualTo: 'guide')
                  .where('isVerified', isEqualTo: false)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error, size: 64, color: AppTheme.errorColor),
                        const SizedBox(height: 16),
                        Text('Error loading verification requests',
                            style: AppTheme.bodyLarge),
                      ],
                    ),
                  );
                }

                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.verified,
                            size: 64, color: AppTheme.successColor),
                        const SizedBox(height: 16),
                        Text('No pending verifications',
                            style: AppTheme.bodyLarge),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    final userDoc = snapshot.data!.docs[index];
                    final userData = userDoc.data() as Map<String, dynamic>;

                    return Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor:
                                      AppTheme.accentColor.withOpacity(0.1),
                                  child: Text(
                                    (userData['displayName']?[0] ??
                                            userData['email'][0])
                                        .toString(),
                                    style:
                                        TextStyle(color: AppTheme.accentColor),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        userData['displayName'] ?? 'No Name',
                                        style: AppTheme.bodyLarge.copyWith(
                                            fontWeight: FontWeight.w600),
                                      ),
                                      Text(
                                        userData['email'],
                                        style: AppTheme.bodySmall.copyWith(
                                            color: AppTheme.textSecondary),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppTheme.errorColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    'Pending',
                                    style: TextStyle(
                                      color: AppTheme.errorColor,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'Phone: ${userData['phoneNumber'] ?? 'Not provided'}',
                                    style: AppTheme.bodyMedium,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'Specializations: ${(userData['specializations'] as List?)?.join(', ') ?? 'Not specified'}',
                                    style: AppTheme.bodyMedium,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton.icon(
                                  onPressed: () =>
                                      _viewUserDetails(userDoc.id, userData),
                                  icon: const Icon(Icons.visibility),
                                  label: const Text('View Details'),
                                  style: TextButton.styleFrom(
                                    foregroundColor: AppTheme.textSecondary,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton.icon(
                                  onPressed: () => _verifyUser(userDoc.id),
                                  icon: const Icon(Icons.check),
                                  label: const Text('Verify'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.successColor,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // TAB 3: PAYMENTS
  Widget _buildPaymentsTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Payment Management', style: AppTheme.headlineMedium),
          const SizedBox(height: 16),
          Text(
            'Monitor all payment transactions',
            style: AppTheme.bodyLarge.copyWith(color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('payments')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error, size: 64, color: AppTheme.errorColor),
                        const SizedBox(height: 16),
                        Text('Error loading payments',
                            style: AppTheme.bodyLarge),
                      ],
                    ),
                  );
                }

                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.payment,
                            size: 64, color: AppTheme.textSecondary),
                        const SizedBox(height: 16),
                        Text('No payments found', style: AppTheme.bodyLarge),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    final paymentDoc = snapshot.data!.docs[index];
                    final payment = paymentDoc.data() as Map<String, dynamic>;

                    return Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor:
                              _getPaymentStatusColor(payment['status'])
                                  .withOpacity(0.1),
                          child: Icon(
                            _getPaymentIcon(payment['status']),
                            color: _getPaymentStatusColor(payment['status']),
                          ),
                        ),
                        title: Text(
                          '₱${(payment['amount'] ?? 0).toDouble().toStringAsFixed(2)}',
                          style: AppTheme.bodyLarge
                              .copyWith(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Method: ${payment['method'] ?? 'Unknown'}'),
                            Text(
                                'Booking ID: ${payment['bookingId'] ?? 'N/A'}'),
                            Text('Date: ${_formatDate(payment['date'])}'),
                          ],
                        ),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getPaymentStatusColor(payment['status'])
                                .withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            payment['status']?.toString().toUpperCase() ??
                                'UNKNOWN',
                            style: TextStyle(
                              color: _getPaymentStatusColor(payment['status']),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Helper Methods
  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: color),
            const SizedBox(height: 16),
            Text(
              value,
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style:
                  AppTheme.bodyMedium.copyWith(color: AppTheme.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorCard(String message) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error, size: 48, color: AppTheme.errorColor),
            const SizedBox(height: 16),
            Text(message, style: AppTheme.bodyMedium),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingCard(String message) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(message, style: AppTheme.bodyMedium),
          ],
        ),
      ),
    );
  }

  Future<void> _verifyUser(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'isVerified': true,
        'verifiedAt': FieldValue.serverTimestamp(),
        'verifiedBy': FirebaseAuth.instance.currentUser?.uid,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('User verified successfully'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error verifying user: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  void _viewUserDetails(String userId, Map<String, dynamic> userData) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('User Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Name: ${userData['displayName'] ?? 'No name'}'),
            Text('Email: ${userData['email']}'),
            Text('Phone: ${userData['phoneNumber'] ?? 'Not provided'}'),
            Text(
                'Languages: ${(userData['languages'] as List?)?.join(', ') ?? 'Not specified'}'),
            Text('Tours Completed: ${userData['toursCompleted'] ?? 0}'),
            Text(
                'Average Rating: ${userData['averageRating']?.toString() ?? 'No rating'}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  String _formatDate(dynamic date) {
    if (date == null) return 'N/A';
    if (date is Timestamp) {
      return '${date.toDate().day}/${date.toDate().month}/${date.toDate().year}';
    }
    if (date is DateTime) {
      return '${date.day}/${date.month}/${date.year}';
    }
    return 'Invalid Date';
  }

  String _getStatusText(dynamic status) {
    if (status == null) return 'Unknown';
    if (status is int) {
      const statuses = [
        'Pending',
        'Confirmed',
        'Paid',
        'In Progress',
        'Completed',
        'Cancelled',
        'Rejected',
        'Refunded'
      ];
      return statuses.length > status ? statuses[status] : 'Unknown';
    }
    return status.toString();
  }

  Color _getPaymentStatusColor(dynamic status) {
    switch (status) {
      case 'completed':
        return AppTheme.successColor;
      case 'failed':
      case 'cancelled':
        return AppTheme.errorColor;
      case 'pending':
      case 'processing':
        return Colors.orange;
      default:
        return AppTheme.textSecondary;
    }
  }

  IconData _getPaymentIcon(dynamic status) {
    switch (status) {
      case 'completed':
        return Icons.check_circle;
      case 'failed':
      case 'cancelled':
        return Icons.cancel;
      case 'pending':
      case 'processing':
        return Icons.pending;
      default:
        return Icons.payment;
    }
  }
}
