import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tourmate_app/models/booking_model.dart';
import '../../utils/app_theme.dart';

class AdminBookingMonitoringScreen extends StatefulWidget {
  const AdminBookingMonitoringScreen({super.key});

  @override
  State<AdminBookingMonitoringScreen> createState() => _AdminBookingMonitoringScreenState();
}

class _AdminBookingMonitoringScreenState extends State<AdminBookingMonitoringScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedStatus = 'All';
  String _searchQuery = '';

  final List<String> _statusFilters = [
    'All',
    'Pending',
    'Confirmed',
    'Paid',
    'In Progress',
    'Completed',
    'Cancelled',
    'Rejected'
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
        title: const Text('Booking Monitoring'),
        backgroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primaryColor,
          unselectedLabelColor: AppTheme.textSecondary,
          indicatorColor: AppTheme.primaryColor,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'All Bookings'),
            Tab(text: 'Issues'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(),
          _buildAllBookingsTab(),
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
          Text('Booking Overview', style: AppTheme.headlineMedium),
          const SizedBox(height: 24),

          // Statistics Cards
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('bookings').snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final bookings = snapshot.data!.docs
                  .map((doc) => BookingModel.fromMap(doc.data() as Map<String, dynamic>))
                  .toList();

              final stats = _calculateBookingStats(bookings);

              return Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          'Total Bookings',
                          stats['total'].toString(),
                          Icons.book_online,
                          AppTheme.primaryColor,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildStatCard(
                          'Pending Approval',
                          stats['pending'].toString(),
                          Icons.pending,
                          AppTheme.accentColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          'Active Tours',
                          stats['active'].toString(),
                          Icons.directions_walk,
                          AppTheme.successColor,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildStatCard(
                          'Revenue',
                          '₱${stats['revenue'].toStringAsFixed(0)}',
                          Icons.attach_money,
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

          // Recent Activity
          Text('Recent Activity', style: AppTheme.headlineSmall),
          const SizedBox(height: 16),

          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('bookings')
                .orderBy('bookingDate', descending: true)
                .limit(10)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final recentBookings = snapshot.data!.docs
                  .map((doc) => BookingModel.fromMap(doc.data() as Map<String, dynamic>))
                  .toList();

              return Column(
                children: recentBookings.map((booking) => _buildActivityItem(booking)).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAllBookingsTab() {
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
                  hintText: 'Search by tour, guide, or tourist...',
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

              // Status Filter
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _statusFilters.map((status) {
                    final isSelected = _selectedStatus == status;
                    return Container(
                      margin: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(status),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            _selectedStatus = selected ? status : 'All';
                          });
                        },
                        backgroundColor: Colors.grey[100],
                        selectedColor: AppTheme.primaryColor.withOpacity(0.1),
                        checkmarkColor: AppTheme.primaryColor,
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),

        // Bookings List
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('bookings')
                .orderBy('bookingDate', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              var bookings = snapshot.data!.docs
                  .map((doc) => BookingModel.fromMap(doc.data() as Map<String, dynamic>))
                  .toList();

              // Apply filters
              if (_selectedStatus != 'All') {
                bookings = bookings.where((booking) {
                  switch (_selectedStatus) {
                    case 'Pending':
                      return booking.status == BookingStatus.pending;
                    case 'Confirmed':
                      return booking.status == BookingStatus.confirmed;
                    case 'Paid':
                      return booking.status == BookingStatus.paid;
                    case 'In Progress':
                      return booking.status == BookingStatus.inProgress;
                    case 'Completed':
                      return booking.status == BookingStatus.completed;
                    case 'Cancelled':
                      return booking.status == BookingStatus.cancelled;
                    case 'Rejected':
                      return booking.status == BookingStatus.rejected;
                    default:
                      return true;
                  }
                }).toList();
              }

              // Apply search
              if (_searchQuery.isNotEmpty) {
                bookings = bookings.where((booking) {
                  // This would need to be enhanced with actual tour and user data
                  return booking.id.contains(_searchQuery) ||
                         booking.tourId.contains(_searchQuery);
                }).toList();
              }

              if (bookings.isEmpty) {
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
                        'No bookings found',
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
                itemCount: bookings.length,
                itemBuilder: (context, index) {
                  return _buildBookingCard(bookings[index]);
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
          .collection('bookings')
          .where('status', whereIn: [
            BookingStatus.cancelled.index,
            BookingStatus.rejected.index,
          ])
          .orderBy('bookingDate', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final issueBookings = snapshot.data!.docs
            .map((doc) => BookingModel.fromMap(doc.data() as Map<String, dynamic>))
            .toList();

        if (issueBookings.isEmpty) {
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
                  'No booking issues found',
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
          itemCount: issueBookings.length,
          itemBuilder: (context, index) {
            return _buildIssueCard(issueBookings[index]);
          },
        );
      },
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
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

  Widget _buildActivityItem(BookingModel booking) {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: booking.statusColor.withOpacity(0.1),
          child: Icon(
            _getStatusIcon(booking.status),
            color: booking.statusColor,
          ),
        ),
        title: Text(
          'Booking ${booking.statusDisplayText.toLowerCase()}',
          style: AppTheme.bodyMedium.copyWith(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          'Tour ID: ${booking.tourId} • ₱${booking.totalPrice.toStringAsFixed(2)}',
          style: AppTheme.bodySmall,
        ),
        trailing: Text(
          '${booking.bookingDate.day}/${booking.bookingDate.month}',
          style: AppTheme.bodySmall.copyWith(color: AppTheme.textSecondary),
        ),
      ),
    );
  }

  Widget _buildBookingCard(BookingModel booking) {
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
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: booking.statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    booking.statusDisplayText,
                    style: AppTheme.bodySmall.copyWith(
                      color: booking.statusColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  '₱${booking.totalPrice.toStringAsFixed(2)}',
                  style: AppTheme.bodyLarge.copyWith(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Tour ID: ${booking.tourId}',
              style: AppTheme.bodyLarge.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.person, size: 16, color: AppTheme.textSecondary),
                const SizedBox(width: 4),
                Text(
                  'Tourist ID: ${booking.touristId}',
                  style: AppTheme.bodySmall,
                ),
                const SizedBox(width: 16),
                Icon(Icons.business, size: 16, color: AppTheme.textSecondary),
                const SizedBox(width: 4),
                Text(
                  'Guide ID: ${booking.guideId ?? 'N/A'}',
                  style: AppTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 16, color: AppTheme.textSecondary),
                const SizedBox(width: 4),
                Text(
                  'Tour: ${booking.tourStartDate.day}/${booking.tourStartDate.month}/${booking.tourStartDate.year}',
                  style: AppTheme.bodySmall,
                ),
                const SizedBox(width: 16),
                Icon(Icons.people, size: 16, color: AppTheme.textSecondary),
                const SizedBox(width: 4),
                Text(
                  '${booking.numberOfParticipants} people',
                  style: AppTheme.bodySmall,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIssueCard(BookingModel booking) {
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
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: booking.statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    booking.statusDisplayText,
                    style: AppTheme.bodySmall.copyWith(
                      color: booking.statusColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.more_vert),
                  onPressed: () => _showIssueActions(booking),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Tour ID: ${booking.tourId}',
              style: AppTheme.bodyLarge.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            if (booking.cancellationReason != null && booking.cancellationReason!.isNotEmpty)
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
                        'Reason: ${booking.cancellationReason}',
                        style: AppTheme.bodySmall.copyWith(color: AppTheme.errorColor),
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

  Map<String, dynamic> _calculateBookingStats(List<BookingModel> bookings) {
    return {
      'total': bookings.length,
      'pending': bookings.where((b) => b.status == BookingStatus.pending).length,
      'active': bookings.where((b) => b.status == BookingStatus.inProgress).length,
      'revenue': bookings
          .where((b) => b.status == BookingStatus.completed || b.status == BookingStatus.paid)
          .fold(0.0, (sum, b) => sum + b.totalPrice),
    };
  }

  IconData _getStatusIcon(BookingStatus status) {
    switch (status) {
      case BookingStatus.pending:
        return Icons.pending;
      case BookingStatus.confirmed:
        return Icons.event_available;
      case BookingStatus.paid:
        return Icons.payment;
      case BookingStatus.inProgress:
        return Icons.directions_walk;
      case BookingStatus.completed:
        return Icons.check_circle;
      case BookingStatus.cancelled:
        return Icons.cancel;
      case BookingStatus.rejected:
        return Icons.close;
      case BookingStatus.refunded:
        return Icons.replay;
    }
  }

  void _showIssueActions(BookingModel booking) {
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
                // Navigate to detailed booking view
              },
            ),
            ListTile(
              leading: const Icon(Icons.message),
              title: const Text('Contact Parties'),
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
                // Generate issue report
              },
            ),
          ],
        ),
      ),
    );
  }
}