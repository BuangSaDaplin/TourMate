import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../utils/app_theme.dart';
import '../../services/database_service.dart';
import '../../models/tour_model.dart';
import 'create_tour_screen.dart';

class ToursManagementScreen extends StatefulWidget {
  const ToursManagementScreen({super.key});

  @override
  State<ToursManagementScreen> createState() => _ToursManagementScreenState();
}

class _ToursManagementScreenState extends State<ToursManagementScreen> {
  final DatabaseService _databaseService = DatabaseService();
  String _selectedFilter = 'pending';
  List<TourModel> _tours = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTours();
  }

  Future<void> _loadTours() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final tours = await _databaseService.getToursByGuide(user.uid);
        setState(() {
          _tours = tours;
          _isLoading = false;
        });
      } catch (e) {
        setState(() {
          _isLoading = false;
        });
        // Handle error
      }
    }
  }

  List<TourModel> get _filteredTours {
    if (_selectedFilter == 'All') return _tours;
    return _tours.where((tour) => tour.status == _selectedFilter).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Filter Tabs
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: Row(
            children: [
              _buildFilterTab('Pending'),
              const SizedBox(width: 8),
              _buildFilterTab('Approved'),
              const SizedBox(width: 8),
              _buildFilterTab('Rejected'),
            ],
          ),
        ),
        // Tours List
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _filteredTours.length,
            itemBuilder: (context, index) {
              final tour = _filteredTours[index];
              return _buildTourCard(tour);
            },
          ),
        ),
        // Create New Tour Button
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: ElevatedButton.icon(
            onPressed: () {
              // Navigate to create tour screen
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CreateTourScreen(),
                ),
              );
            },
            icon: const Icon(Icons.add),
            label: const Text('Suggest New Tour'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterTab(String filter) {
    final isSelected = _selectedFilter == filter;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedFilter = filter;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primaryColor : Colors.grey[100],
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            filter,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.white : AppTheme.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTourCard(TourModel tour) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tour Header
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.image,
                  color: AppTheme.primaryColor,
                  size: 30,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tour.title,
                      style: AppTheme.bodyLarge.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _getStatusColor(tour.status).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        tour.status,
                        style: TextStyle(
                          color: _getStatusColor(tour.status),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Tour Stats
          Row(
            children: [
              Expanded(
                child: _buildTourStat(
                  '${tour.currentParticipants}',
                  'Bookings',
                  Icons.people,
                ),
              ),
              Expanded(
                child: _buildTourStat(
                  '₱${tour.price * tour.currentParticipants}',
                  'Earnings',
                  Icons.attach_money,
                ),
              ),
              Expanded(
                child: _buildTourStat(
                  '-',
                  'Rating',
                  Icons.star,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    // Handle edit
                  },
                  icon: const Icon(Icons.edit, size: 16),
                  label: const Text('Edit'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    _showDeleteDialog(tour);
                  },
                  icon: const Icon(Icons.delete, size: 16),
                  label: const Text('Delete'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    foregroundColor: AppTheme.errorColor,
                    side: const BorderSide(color: AppTheme.errorColor),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTourStat(String value, String label, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: AppTheme.primaryColor, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppTheme.bodyLarge.copyWith(
            fontWeight: FontWeight.w600,
            color: AppTheme.primaryColor,
          ),
        ),
        Text(
          label,
          style: AppTheme.bodySmall.copyWith(color: AppTheme.textSecondary),
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Pending':
        return AppTheme.accentColor;
      case 'Approved':
        return AppTheme.successColor;
      case 'Rejected':
        return AppTheme.errorColor;
      default:
        return AppTheme.textSecondary;
    }
  }

  Future<void> _deleteTour(TourModel tour) async {
    try {
      await _databaseService.deleteTour(tour.id);
      setState(() {
        _tours.remove(tour);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${tour.title} has been deleted successfully'),
          backgroundColor: AppTheme.successColor,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Failed to delete tour'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  void _showDeleteDialog(TourModel tour) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Tour'),
          content: Text(
              'Are you sure you want to delete "${tour.title}"? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _deleteTour(tour);
              },
              style: TextButton.styleFrom(foregroundColor: AppTheme.errorColor),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }
}
