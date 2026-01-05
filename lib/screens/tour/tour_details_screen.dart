import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tourmate_app/models/tour_model.dart';
import 'package:tourmate_app/models/booking_model.dart';
import 'package:tourmate_app/models/user_model.dart';
import 'package:tourmate_app/services/itinerary_service.dart';
import 'package:tourmate_app/models/itinerary_model.dart';
import 'package:tourmate_app/services/auth_service.dart';
import 'package:tourmate_app/screens/booking/booking_screen.dart';
import 'package:tourmate_app/screens/itinerary/itinerary_screen.dart';
import '../../utils/app_theme.dart';

class TourDetailsScreen extends StatefulWidget {
  final String tourId;

  const TourDetailsScreen({super.key, required this.tourId});

  @override
  State<TourDetailsScreen> createState() => _TourDetailsScreenState();
}

class _TourDetailsScreenState extends State<TourDetailsScreen> {
  // Mock tour data - in real app, fetch based on tourId
  TourModel tourData = TourModel(
    id: '1',
    title: 'Kawasan Falls Canyoneering',
    description:
        'Experience the thrill of jumping, swimming, and trekking through the stunning Kawasan Falls canyon. This adventure takes you through crystal-clear turquoise waters, natural rock formations, and breathtaking waterfalls.',
    price: 2500.0,
    category: ['Adventure'],
    maxParticipants: 10,
    currentParticipants: 0,
    startTime: DateTime.now(),
    endTime: DateTime.now(),
    meetingPoint: 'Badian, Cebu',
    mediaURL: ['kawasan1.jpg', 'kawasan2.jpg', 'kawasan3.jpg'],
    createdBy: 'guide1',
    shared: true,
    itinerary: [],
    status: 'published',
    duration: 8,
    languages: ['English'],
    specializations: ['Hiking', 'Snorkeling'],
  );

  List<UserModel> guides = [];
  bool isLoadingGuides = false;
  UserModel? selectedGuide;

  @override
  void initState() {
    super.initState();
    _fetchGuides();
  }

  Future<void> _fetchGuides() async {
    setState(() {
      isLoadingGuides = true;
    });

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'guide')
          .where('status', isEqualTo: 1)
          .get();

      setState(() {
        guides = snapshot.docs
            .map((doc) => UserModel.fromFirestore(doc.data()))
            .toList();
        isLoadingGuides = false;
      });
    } catch (e) {
      setState(() {
        isLoadingGuides = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load guides: $e')),
      );
    }
  }

  void _showGuideSelectionDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select a Guide'),
          content: SizedBox(
            width: double.maxFinite,
            height: 400,
            child: isLoadingGuides
                ? const Center(child: CircularProgressIndicator())
                : guides.isEmpty
                    ? const Center(child: Text('No guides available'))
                    : ListView.builder(
                        itemCount: guides.length,
                        itemBuilder: (context, index) {
                          final guide = guides[index];
                          final isOnline = guide.activeStatus == 1;
                          final color = isOnline ? Colors.black : Colors.grey;

                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor:
                                  AppTheme.primaryColor.withOpacity(0.2),
                              child: Icon(
                                Icons.person,
                                color: isOnline
                                    ? AppTheme.primaryColor
                                    : Colors.grey,
                              ),
                            ),
                            title: Text(
                              guide.displayName ?? guide.email,
                              style: TextStyle(color: color),
                            ),
                            subtitle: Row(
                              children: [
                                Icon(Icons.star,
                                    size: 16,
                                    color:
                                        isOnline ? Colors.amber : Colors.grey),
                                const SizedBox(width: 4),
                                Text(
                                  '${guide.averageRating?.toStringAsFixed(1) ?? 'N/A'} • ${guide.toursCompleted ?? 0} tours',
                                  style: TextStyle(color: color),
                                ),
                              ],
                            ),
                            onTap: () {
                              setState(() {
                                tourData =
                                    tourData.copyWith(createdBy: guide.uid);
                                selectedGuide = guide;
                              });
                              Navigator.of(context).pop();
                            },
                          );
                        },
                      ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: CustomScrollView(
        slivers: [
          // App Bar with Image
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppTheme.primaryColor.withOpacity(0.7),
                          AppTheme.accentColor.withOpacity(0.7),
                        ],
                      ),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.image,
                        size: 100,
                        color: Colors.white30,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 100,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Colors.black.withOpacity(0.7),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 16,
                    right: 16,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        // TODO: Implement map view functionality
                      },
                      icon: const Icon(Icons.location_on),
                      label: const Text('View Map'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white.withOpacity(0.9),
                        foregroundColor: AppTheme.textPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            leading: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimary),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            actions: [
              Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(
                    Icons.favorite_border,
                    color: AppTheme.textPrimary,
                  ),
                  onPressed: () {},
                ),
              ),
              Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.share, color: AppTheme.textPrimary),
                  onPressed: () {},
                ),
              ),
            ],
          ),
          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title and Price
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tourData.title,
                              style: AppTheme.headlineMedium,
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(
                                  Icons.location_on,
                                  size: 16,
                                  color: AppTheme.textSecondary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  tourData.meetingPoint,
                                  style: AppTheme.bodyMedium,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '₱${tourData.price.toStringAsFixed(0)}',
                            style: AppTheme.headlineMedium.copyWith(
                              color: AppTheme.primaryColor,
                            ),
                          ),
                          Text('per person', style: AppTheme.bodySmall),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Rating and Duration
                  Row(
                    children: [
                      RatingBarIndicator(
                        rating: 4.9,
                        itemBuilder: (context, index) =>
                            const Icon(Icons.star, color: Colors.amber),
                        itemCount: 5,
                        itemSize: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '4.9 (234 reviews)',
                        style: AppTheme.bodyMedium,
                      ),
                      const Spacer(),
                      const Icon(
                        Icons.access_time,
                        size: 16,
                        color: AppTheme.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text('${tourData.duration} hours',
                          style: AppTheme.bodyMedium),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Guide Info
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: AppTheme.cardDecoration,
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundColor: AppTheme.primaryColor.withOpacity(
                            0.2,
                          ),
                          child: const Icon(
                            Icons.person,
                            size: 30,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                selectedGuide?.displayName ??
                                    'No guide selected',
                                style: AppTheme.bodyLarge.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              if (selectedGuide != null)
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.star,
                                      size: 16,
                                      color: Colors.amber,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${selectedGuide!.averageRating?.toStringAsFixed(1) ?? 'N/A'} • ${selectedGuide!.toursCompleted ?? 0} tours',
                                      style: AppTheme.bodySmall,
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                        if (selectedGuide != null)
                          TextButton(
                            onPressed: () {},
                            child: const Text('View Profile'),
                          ),
                        TextButton(
                          onPressed: _showGuideSelectionDialog,
                          child: const Text('Select Guide'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Description
                  Text('About this tour', style: AppTheme.headlineSmall),
                  const SizedBox(height: 12),
                  Text(
                    tourData.description,
                    style: AppTheme.bodyLarge.copyWith(height: 1.5),
                  ),
                  const SizedBox(height: 24),
                  // Highlights
                  Text('Highlights', style: AppTheme.headlineSmall),
                  const SizedBox(height: 12),
                  ...[
                    'Jump from heights up to 10 meters',
                    'Swim in natural pools',
                    'Trek through tropical canyon',
                    'Professional guide and safety equipment',
                    'Lunch included',
                  ].map<Widget>((highlight) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.check_circle,
                            size: 20,
                            color: AppTheme.successColor,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(highlight, style: AppTheme.bodyMedium),
                          ),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 24),
                  // Itinerary Button
                  ElevatedButton(
                    onPressed: () async {
                      // Create a preview itinerary for this tour
                      final itineraryService = ItineraryService();
                      final authService = AuthService();

                      final user = authService.getCurrentUser();
                      if (user == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content:
                                  Text('Please log in to view itineraries')),
                        );
                        return;
                      }

                      try {
                        // Create a mock booking for itinerary generation
                        final mockBooking = BookingModel(
                          tourTitle: tourData.title,
                          id: 'preview_${tourData.id}',
                          tourId: tourData.id,
                          touristId: user.uid,
                          guideId: tourData.createdBy,
                          bookingDate: DateTime.now(),
                          tourStartDate: tourData.startTime,
                          numberOfParticipants: 1,
                          totalPrice: tourData.price,
                          status: BookingStatus.confirmed,
                        );

                        final previewItinerary =
                            await itineraryService.generateItineraryFromBooking(
                          mockBooking,
                          tourData,
                        );

                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) =>
                                ItineraryScreen(itinerary: previewItinerary),
                          ),
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text('Failed to load itinerary: $e')),
                        );
                      }
                    },
                    child: const Text('View Itinerary'),
                  ),
                  const SizedBox(height: 24),
                  // Schedule
                  Text('Schedule', style: AppTheme.headlineSmall),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        _buildScheduleItem(
                          'Hotel Pickup',
                          '5:00 AM',
                        ),
                        const SizedBox(height: 12),
                        _buildScheduleItem(
                          'Tour Start',
                          '7:00 AM',
                        ),
                        const SizedBox(height: 12),
                        _buildScheduleItem(
                          'Tour End',
                          '3:00 PM',
                        ),
                        const SizedBox(height: 12),
                        _buildScheduleItem(
                          'Hotel Return',
                          '5:00 PM',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  // What's Included
                  Text("What's Included", style: AppTheme.headlineSmall),
                  const SizedBox(height: 12),
                  ...[
                    'Hotel pickup and drop-off',
                    'Professional guide',
                    'Safety equipment',
                    'Lunch and snacks',
                    'Waterproof bag',
                  ].map<Widget>((item) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.check,
                            size: 20,
                            color: AppTheme.successColor,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(item, style: AppTheme.bodyMedium),
                          ),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 16),
                  Text(
                    "What's Not Included",
                    style: AppTheme.bodyLarge.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...[
                    'Personal expenses',
                    'Tips and gratuities',
                    'Travel insurance',
                  ].map<Widget>((item) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.close,
                            size: 20,
                            color: AppTheme.errorColor,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(item, style: AppTheme.bodyMedium),
                          ),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 24),
                  // Alternative Tours
                  Text('Alternative Cebu Tours', style: AppTheme.headlineSmall),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 200,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        _buildAlternativeTour(
                          'Oslob Whale Shark Encounter',
                          'Oslob, Cebu',
                          3500,
                          4.8,
                        ),
                        _buildAlternativeTour(
                          'Bantayan Island Hopping',
                          'Bantayan Island',
                          2800,
                          4.7,
                        ),
                        _buildAlternativeTour(
                          'Moalboal Sardine Run',
                          'Moalboal, Cebu',
                          2200,
                          4.9,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 100), // Space for bottom button
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: ElevatedButton(
            onPressed: selectedGuide != null
                ? () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => BookingScreen(tour: tourData),
                      ),
                    );
                  }
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  selectedGuide != null ? AppTheme.primaryColor : Colors.grey,
              foregroundColor:
                  selectedGuide != null ? Colors.white : Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Book Now',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildScheduleItem(String label, String time) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTheme.bodyMedium),
        Text(
          time,
          style: AppTheme.bodyMedium.copyWith(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildAlternativeTour(
    String title,
    String location,
    double price,
    double rating,
  ) {
    return Container(
      width: 200,
      margin: const EdgeInsets.only(right: 16),
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 100,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.2),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            child: Center(
              child: Icon(
                Icons.image,
                size: 40,
                color: AppTheme.primaryColor.withOpacity(0.5),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTheme.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  location,
                  style: AppTheme.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '₱${price.toStringAsFixed(0)}',
                      style: AppTheme.bodyMedium.copyWith(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Row(
                      children: [
                        const Icon(Icons.star, size: 14, color: Colors.amber),
                        const SizedBox(width: 2),
                        Text(rating.toString(), style: AppTheme.bodySmall),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
