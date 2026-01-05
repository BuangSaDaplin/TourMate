import 'package:flutter/material.dart';
import 'package:tourmate_app/services/itinerary_service.dart';
import 'package:tourmate_app/services/auth_service.dart';
import 'package:tourmate_app/models/itinerary_model.dart';
import 'package:tourmate_app/screens/itinerary/itinerary_screen.dart';
import '../../utils/app_theme.dart';

class ItinerariesScreen extends StatefulWidget {
  const ItinerariesScreen({super.key});

  @override
  State<ItinerariesScreen> createState() => _ItinerariesScreenState();
}

class _ItinerariesScreenState extends State<ItinerariesScreen> {
  final ItineraryService _itineraryService = ItineraryService();
  final AuthService _authService = AuthService();
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _getCurrentUser();
  }

  Future<void> _getCurrentUser() async {
    final user = _authService.getCurrentUser();
    if (user != null) {
      setState(() {
        _currentUserId = user.uid;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUserId == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('My Itineraries'),
          backgroundColor: Colors.white,
          elevation: 0,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('My Itineraries'),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: AppTheme.primaryColor),
            onPressed: _createNewItinerary,
            tooltip: 'Create New Itinerary',
          ),
        ],
      ),
      body: FutureBuilder<List<ItineraryModel>>(
        future: _itineraryService.getUserItineraries(_currentUserId!),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return _buildEmptyState();
          }

          final itineraries = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: itineraries.length,
            itemBuilder: (context, index) {
              return _buildItineraryCard(itineraries[index]);
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.map_outlined,
            size: 64,
            color: AppTheme.textSecondary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No itineraries yet',
            style: AppTheme.headlineSmall.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first travel itinerary!',
            style: AppTheme.bodyMedium.copyWith(
              color: AppTheme.textSecondary.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _createNewItinerary,
            icon: const Icon(Icons.add),
            label: const Text('Create Itinerary'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItineraryCard(ItineraryModel itinerary) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _openItinerary(itinerary),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      itinerary.title,
                      style: AppTheme.headlineSmall.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(itinerary.status),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      itinerary.status.toString().split('.').last.toUpperCase(),
                      style: AppTheme.bodySmall.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                itinerary.description,
                style: AppTheme.bodyMedium.copyWith(
                  color: AppTheme.textSecondary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: AppTheme.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${_formatDate(itinerary.startDate)} - ${_formatDate(itinerary.endDate)}',
                    style: AppTheme.bodySmall.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(
                    Icons.check_circle,
                    size: 16,
                    color: itinerary.isCompleted ? Colors.green : AppTheme.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${itinerary.completedItems.length}/${itinerary.items.length} done',
                    style: AppTheme.bodySmall.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.attach_money,
                    size: 16,
                    color: AppTheme.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Total: \$${itinerary.totalCost.toStringAsFixed(2)}',
                    style: AppTheme.bodySmall.copyWith(
                      color: AppTheme.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  if (itinerary.isPublic)
                    Icon(
                      Icons.share,
                      size: 16,
                      color: AppTheme.primaryColor,
                    ),
                  const SizedBox(width: 8),
                  PopupMenuButton<String>(
                    onSelected: (value) => _handleItineraryAction(itinerary, value),
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'share',
                        child: Text('Share'),
                      ),
                      const PopupMenuItem(
                        value: 'duplicate',
                        child: Text('Duplicate'),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Text('Delete'),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              LinearProgressIndicator(
                value: itinerary.completionPercentage / 100,
                backgroundColor: AppTheme.dividerColor,
                valueColor: AlwaysStoppedAnimation<Color>(_getStatusColor(itinerary.status)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(ItineraryStatus status) {
    switch (status) {
      case ItineraryStatus.draft:
        return Colors.grey;
      case ItineraryStatus.published:
        return AppTheme.primaryColor;
      case ItineraryStatus.completed:
        return Colors.green;
      case ItineraryStatus.archived:
        return Colors.blueGrey;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}';
  }

  void _openItinerary(ItineraryModel itinerary) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ItineraryScreen(itinerary: itinerary),
      ),
    );
  }

  void _createNewItinerary() {
    // Navigate to itinerary creation screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Create itinerary functionality coming soon!')),
    );
  }

  void _handleItineraryAction(ItineraryModel itinerary, String action) {
    switch (action) {
      case 'share':
        _shareItinerary(itinerary);
        break;
      case 'duplicate':
        _duplicateItinerary(itinerary);
        break;
      case 'delete':
        _deleteItinerary(itinerary);
        break;
    }
  }

  void _shareItinerary(ItineraryModel itinerary) async {
    try {
      final shareCode = await _itineraryService.shareItinerary(itinerary.id);
      final shareUrl = 'https://tourmate.app/itinerary/$shareCode';

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Share Itinerary'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Share this link with others:'),
              const SizedBox(height: 8),
              SelectableText(
                shareUrl,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 14,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Done'),
            ),
          ],
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to share itinerary: $e')),
      );
    }
  }

  void _duplicateItinerary(ItineraryModel itinerary) {
    // Create a copy with new ID and title
    final duplicatedItinerary = ItineraryModel(
      id: 'itinerary_${DateTime.now().millisecondsSinceEpoch}',
      userId: itinerary.userId,
      title: '${itinerary.title} (Copy)',
      description: itinerary.description,
      startDate: itinerary.startDate,
      endDate: itinerary.endDate,
      status: ItineraryStatus.draft,
      items: itinerary.items.map((item) => ItineraryItemModel(
        id: 'item_${DateTime.now().millisecondsSinceEpoch}_${item.id}',
        title: item.title,
        description: item.description,
        type: item.type,
        startTime: item.startTime,
        endTime: item.endTime,
        location: item.location,
        address: item.address,
        cost: item.cost,
        notes: item.notes,
        imageUrl: item.imageUrl,
        isCompleted: false, // Reset completion status
        order: item.order,
        metadata: item.metadata,
      )).toList(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      relatedBookingId: itinerary.relatedBookingId,
      relatedTourId: itinerary.relatedTourId,
    );

    _itineraryService.createItinerary(duplicatedItinerary).then((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Itinerary duplicated')),
      );
    }).catchError((e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to duplicate itinerary: $e')),
      );
    });
  }

  void _deleteItinerary(ItineraryModel itinerary) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Itinerary'),
        content: const Text('Are you sure you want to delete this itinerary? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              try {
                await _itineraryService.deleteItinerary(itinerary.id);
                Navigator.of(context).pop(); // Close dialog
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Itinerary deleted')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed to delete itinerary: $e')),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}