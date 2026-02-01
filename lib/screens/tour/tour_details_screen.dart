import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:tourmate_app/models/tour_model.dart';
import 'package:tourmate_app/models/booking_model.dart';
import 'package:tourmate_app/services/itinerary_service.dart';
import 'package:tourmate_app/models/itinerary_model.dart';
import 'package:tourmate_app/services/auth_service.dart';
import 'package:tourmate_app/services/database_service.dart';
import 'package:tourmate_app/screens/itinerary/itinerary_screen.dart';
import 'package:tourmate_app/screens/tour/tour_map_screen.dart';
import 'package:tourmate_app/data/cebu_graph_data.dart';
import 'package:tourmate_app/data/tour_spot_model.dart';
import 'package:intl/intl.dart';
import '../../utils/app_theme.dart';

class TourDetailsScreen extends StatefulWidget {
  final String tourId;
  final bool isPreview;

  const TourDetailsScreen(
      {super.key, required this.tourId, this.isPreview = false});

  @override
  State<TourDetailsScreen> createState() => _TourDetailsScreenState();
}

class _TourDetailsScreenState extends State<TourDetailsScreen> {
  late TourModel tourData; // Changed from hardcoded to 'late'
  bool isLoading = true;
  List<TourModel> alternativeTours = [];
  int _currentImageIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadTourData(); // NEW: Load data dynamically
  }

  void _loadTourData() async {
    final db = DatabaseService();
    try {
      final tour = await db.getTour(widget.tourId);
      if (tour != null) {
        setState(() {
          tourData = tour;
          isLoading = false;
        });
        _loadAlternativeTours();
      } else {
        // Handle tour not found
        setState(() {
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tour not found')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load tour: $e')),
      );
    }
  }

  void _loadAlternativeTours() async {
    final db = DatabaseService();
    try {
      final approvedTours = await db.getApprovedTours();
      final alternatives = approvedTours
          .where((tour) =>
              tour.category.any((cat) => tourData.category.contains(cat)) &&
              tour.id != tourData.id)
          .take(3)
          .toList();
      setState(() {
        alternativeTours = alternatives;
      });
    } catch (e) {
      // Handle error silently for alternative tours
      print('Failed to load alternative tours: $e');
    }
  }

  void _viewMapForTour() async {
    try {
      // Get the meetingPoint from the tour data
      final meetingPoint = tourData.meetingPoint;
      if (meetingPoint.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Meeting location not available on map')),
        );
        return;
      }

      // Find matching tour spot in cebu_graph_data
      TourSpot? matchingSpot;
      for (final spot in CebuGraphData.allSpots) {
        if (spot.name.toLowerCase() == meetingPoint.toLowerCase()) {
          matchingSpot = spot;
          break;
        }
      }

      if (matchingSpot == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Meeting location not available on map')),
        );
        return;
      }

      // Navigate to the map screen with the matched spot's id
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TourMapScreen(tourId: matchingSpot!.id),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading map: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    final user = authService.getCurrentUser();

    // Show loading screen while data is being fetched
    if (isLoading) {
      return Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

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
                  tourData.mediaURL.isEmpty
                      ? Container(
                          color: AppTheme.primaryColor.withOpacity(0.2),
                          child: Center(
                            child: Icon(
                              Icons.image,
                              size: 80,
                              color: AppTheme.primaryColor.withOpacity(0.5),
                            ),
                          ),
                        )
                      : tourData.mediaURL.length == 1
                          ? Container(
                              decoration: BoxDecoration(
                                image: DecorationImage(
                                  image: tourData.mediaURL.first
                                          .startsWith('http')
                                      ? NetworkImage(tourData.mediaURL.first)
                                      : AssetImage(
                                              'assets/images/${tourData.mediaURL.first}')
                                          as ImageProvider,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            )
                          : CarouselSlider(
                              options: CarouselOptions(
                                height: 300,
                                viewportFraction: 1.0,
                                enableInfiniteScroll: true,
                                autoPlay: false,
                                onPageChanged: (index, reason) {
                                  setState(() {
                                    _currentImageIndex = index;
                                  });
                                },
                              ),
                              items: tourData.mediaURL.map((imageUrl) {
                                return Builder(
                                  builder: (BuildContext context) {
                                    return Container(
                                      width: MediaQuery.of(context).size.width,
                                      decoration: BoxDecoration(
                                        image: DecorationImage(
                                          image: imageUrl.startsWith('http')
                                              ? NetworkImage(imageUrl)
                                              : AssetImage(
                                                      'assets/images/$imageUrl')
                                                  as ImageProvider,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    );
                                  },
                                );
                              }).toList(),
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
                      child: tourData.mediaURL.length > 1
                          ? Align(
                              alignment: Alignment.bottomCenter,
                              child: Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: AnimatedSmoothIndicator(
                                  activeIndex: _currentImageIndex,
                                  count: tourData.mediaURL.length,
                                  effect: const ExpandingDotsEffect(
                                    dotWidth: 8,
                                    dotHeight: 8,
                                    activeDotColor: Colors.white,
                                    dotColor: Colors.white54,
                                  ),
                                ),
                              ),
                            )
                          : null,
                    ),
                  ),
                  Positioned(
                    bottom: 16,
                    right: 16,
                    child: ElevatedButton.icon(
                      onPressed: _viewMapForTour,
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
                        rating: tourData.rating,
                        itemBuilder: (context, index) =>
                            const Icon(Icons.star, color: Colors.amber),
                        itemCount: 5,
                        itemSize: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${tourData.rating.toStringAsFixed(1)} ',
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
                  Column(
                    children: tourData.highlights.map((highlight) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF4CAF50).withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.check,
                                size: 16,
                                color: Color(0xFF4CAF50),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                highlight, // <--- THIS MUST BE DYNAMIC
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.black87,
                                  height: 1.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  // Itinerary Button
                  ElevatedButton(
                    onPressed: () async {
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
                        // Create itinerary from tour's actual itinerary data
                        final List<ItineraryItemModel> items = [];
                        DateTime currentTime = tourData.startTime;

                        for (int i = 0; i < tourData.itinerary.length; i++) {
                          final item = tourData.itinerary[i];
                          final title = item['activity'] ??
                              item['title'] ??
                              'Activity ${i + 1}';
                          final description = item['description'] ?? '';
                          final timeStr = item['time'];

                          DateTime startTime = currentTime;
                          if (timeStr != null) {
                            // Parse time string, assume it's HH:mm format
                            final timeParts = timeStr.split(':');
                            if (timeParts.length == 2) {
                              final hour = int.tryParse(timeParts[0]) ?? 0;
                              final minute = int.tryParse(timeParts[1]) ?? 0;
                              startTime = DateTime(
                                  currentTime.year,
                                  currentTime.month,
                                  currentTime.day,
                                  hour,
                                  minute);
                            }
                          }

                          DateTime endTime = startTime
                              .add(const Duration(hours: 1)); // Default 1 hour

                          if (i < tourData.itinerary.length - 1) {
                            final nextItem = tourData.itinerary[i + 1];
                            final nextTimeStr = nextItem['time'];
                            if (nextTimeStr != null) {
                              final timeParts = nextTimeStr.split(':');
                              if (timeParts.length == 2) {
                                final hour = int.tryParse(timeParts[0]) ?? 0;
                                final minute = int.tryParse(timeParts[1]) ?? 0;
                                endTime = DateTime(
                                    currentTime.year,
                                    currentTime.month,
                                    currentTime.day,
                                    hour,
                                    minute);
                              }
                            }
                          } else {
                            // For the last item, calculate end time based on tour duration in minutes
                            // Convert tour duration from hours to minutes and add to start time
                            final tourDurationInMinutes =
                                (double.tryParse(tourData.duration) ?? 0.0 * 60)
                                    .round();
                            endTime = startTime
                                .add(Duration(minutes: tourDurationInMinutes));
                          }

                          items.add(ItineraryItemModel(
                            id: 'tour_item_$i',
                            title: title,
                            description: description,
                            type: ActivityType.tour,
                            startTime: startTime,
                            endTime: endTime,
                            order: i,
                          ));

                          currentTime = endTime;
                        }

                        final tourStartDate =
                            DateTime.now().add(const Duration(days: 3));
                        final tourEndDate = tourStartDate.add(
                            tourData.endTime.difference(tourData.startTime));

                        final previewItinerary = ItineraryModel(
                          id: 'preview_${tourData.id}',
                          userId: user.uid,
                          title: '${tourData.title} Itinerary',
                          description: tourData.description,
                          startDate: tourStartDate,
                          endDate: tourEndDate,
                          status: ItineraryStatus.draft,
                          items: items.map((item) {
                            final itemDate = DateTime(
                                tourStartDate.year,
                                tourStartDate.month,
                                tourStartDate.day,
                                item.startTime.hour,
                                item.startTime.minute);
                            final itemEndDate = DateTime(
                                tourStartDate.year,
                                tourStartDate.month,
                                tourStartDate.day,
                                item.endTime.hour,
                                item.endTime.minute);
                            return ItineraryItemModel(
                              id: item.id,
                              title: item.title,
                              description: item.description,
                              type: item.type,
                              startTime: itemDate,
                              endTime: itemEndDate,
                              location: item.location,
                              address: item.address,
                              cost: item.cost,
                              notes: item.notes,
                              imageUrl: item.imageUrl,
                              isCompleted: item.isCompleted,
                              order: item.order,
                              metadata: item.metadata,
                            );
                          }).toList(),
                          createdAt: DateTime.now(),
                          updatedAt: DateTime.now(),
                          relatedTourId: tourData.id,
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
                      children: _buildScheduleItems(),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // What's Included
                  Text("What's Included", style: AppTheme.headlineSmall),
                  const SizedBox(height: 12),
                  ...tourData.included.map<Widget>((item) {
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
                  ...tourData.notIncluded.map<Widget>((item) {
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
                    child: alternativeTours.isEmpty
                        ? const Center(
                            child: Text('No alternative tours available'))
                        : ListView(
                            scrollDirection: Axis.horizontal,
                            children: alternativeTours
                                .map(_buildAlternativeTourFromModel)
                                .toList(),
                          ),
                  ),
                  const SizedBox(height: 100), // Space for bottom button
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildScheduleItems() {
    final tourDate = DateTime.now().add(const Duration(days: 3));
    final dateFormat = DateFormat('MMM dd, yyyy');

    // Default times
    String meetupTime = '7:00 AM';
    String endTime = '3:00 PM';

    if (tourData.itinerary.isNotEmpty) {
      // Get first itinerary item time as meetup time
      final firstItem = tourData.itinerary.first;
      if (firstItem.containsKey('time') && firstItem['time'] != null) {
        meetupTime = _formatTimeString(firstItem['time']!);
      }

      // Get last itinerary item time as end time
      final lastItem = tourData.itinerary.last;
      if (lastItem.containsKey('time') && lastItem['time'] != null) {
        endTime = _formatTimeString(lastItem['time']!);
      }
    }

    // Calculate pickup time (2 hours before meetup)
    final meetupDateTime = DateFormat('h:mm a').parse(meetupTime);
    final pickupDateTime = meetupDateTime.subtract(const Duration(hours: 2));
    final pickupTime = DateFormat('h:mm a').format(pickupDateTime);

    // Calculate return time (2 hours after end)
    final endDateTime = DateFormat('h:mm a').parse(endTime);
    final returnDateTime = endDateTime.add(const Duration(hours: 2));
    final returnTime = DateFormat('h:mm a').format(returnDateTime);

    return [
      _buildScheduleItem('Tour Start', meetupTime),
      const SizedBox(height: 12),
      _buildScheduleItem('Tour End', endTime),
      const SizedBox(height: 12),
      _buildScheduleItem('Tour Duration', '${tourData.duration} hours'),
    ];
  }

  String _formatTimeString(String timeString) {
    try {
      // Try parsing as 24-hour format first (HH:mm)
      final time24 = DateFormat('HH:mm').parse(timeString);
      return DateFormat('h:mm a').format(time24);
    } catch (e) {
      // If that fails, try parsing as 12-hour format (h:mm a)
      try {
        final time12 = DateFormat('h:mm a').parse(timeString);
        return DateFormat('h:mm a').format(time12);
      } catch (e2) {
        // If both fail, return a default time
        return '7:00 AM';
      }
    }
  }

  Widget _buildScheduleItem(String label, String time) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            label,
            style: AppTheme.bodyMedium,
            softWrap: true,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          time,
          style: AppTheme.bodyMedium.copyWith(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildAlternativeTourFromModel(TourModel tour) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TourDetailsScreen(tourId: tour.id),
          ),
        );
      },
      child: Container(
        width: 200,
        margin: const EdgeInsets.only(right: 16),
        decoration: AppTheme.cardDecoration,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 87,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                image: tour.mediaURL.isNotEmpty
                    ? DecorationImage(
                        image: tour.mediaURL.first.startsWith('http')
                            ? NetworkImage(tour.mediaURL.first)
                            : AssetImage('assets/images/${tour.mediaURL.first}')
                                as ImageProvider,
                        fit: BoxFit.cover,
                      )
                    : null,
                color: tour.mediaURL.isEmpty
                    ? AppTheme.primaryColor.withOpacity(0.2)
                    : null,
              ),
              child: tour.mediaURL.isEmpty
                  ? Center(
                      child: Icon(
                        Icons.image,
                        size: 40,
                        color: AppTheme.primaryColor.withOpacity(0.5),
                      ),
                    )
                  : null,
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tour.title,
                    style: AppTheme.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    tour.meetingPoint,
                    style: AppTheme.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '₱${tour.price.toStringAsFixed(0)}',
                        style: AppTheme.bodyMedium.copyWith(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Row(
                        children: [
                          const Icon(Icons.star, size: 14, color: Colors.amber),
                          const SizedBox(width: 2),
                          Text(tour.rating.toStringAsFixed(1),
                              style: AppTheme.bodySmall),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
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
