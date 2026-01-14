import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart' as carousel;
import 'package:firebase_auth/firebase_auth.dart';
import '../../utils/app_theme.dart';
import '../tour/tour_details_screen.dart';
import '../tour/tour_browse_screen.dart';
import '../tour/category_based_tours_screen.dart';
import '../booking/booking_screen.dart';
import '../profile/profile_screen.dart';
import '../bookings/bookings_screen.dart';
import '../favorites/favorites_screen.dart';
import '../notifications/notification_screen.dart';
import '../messaging/tourist_messages_screen.dart';
import '../../widgets/auto_translated_text.dart';
import '../../models/tour_model.dart';
import '../../models/user_model.dart';
import '../../services/database_service.dart';

class MainDashboard extends StatefulWidget {
  const MainDashboard({super.key});

  @override
  State<MainDashboard> createState() => _MainDashboardState();
}

class _MainDashboardState extends State<MainDashboard> {
  int _selectedIndex = 0;
  final _searchController = TextEditingController();

  // State for suggested tours
  List<TourModel> _suggestedTours = [];
  bool _isLoadingSuggestedTours = true;
  UserModel? _currentUser;

  // State for recommended tours
  List<TourModel> _recommendedTours = [];
  bool _isLoadingRecommendedTours = true;

  // State for alternative tours
  List<TourModel> _alternativeTours = [];
  bool _isLoadingAlternativeTours = true;

  @override
  void initState() {
    super.initState();
    _loadCurrentUserAndSuggestedTours();
  }

  Widget _getPage(int index) {
    switch (index) {
      case 0:
        return _homePage; // rebuilt every time
      case 1:
        return const BookingsScreen();
      case 2:
        return const TouristMessagesScreen();
      case 3:
        return const FavoritesScreen();
      case 4:
        return const ProfileScreen();
      default:
        return _homePage;
    }
  }

  Future<void> _loadCurrentUserAndSuggestedTours() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      print('Current user: ${user?.uid}');
      if (user != null) {
        final databaseService = DatabaseService();
        _currentUser = await databaseService.getUser(user.uid);
        print('User data: $_currentUser');
        print('User categories: ${_currentUser?.category}');
        if (_currentUser != null &&
            _currentUser!.category != null &&
            _currentUser!.category!.isNotEmpty) {
          // Fetch tours that match any of the user's categories
          final List<String> userCategories = _currentUser!.category!
              .map((c) => c.toLowerCase().trim())
              .toList();

          final allTours = await databaseService.getApprovedTours();
          print('All approved tours: ${allTours.length}');
          _suggestedTours = allTours.where((tour) {
            final matches = tour.category.any(
              (tourCategory) =>
                  userCategories.contains(tourCategory.toLowerCase().trim()),
            );
            print(
                'Tour ${tour.title} categories: ${tour.category}, matches: $matches');
            return matches;
          }).toList();
          print('Suggested tours: ${_suggestedTours.length}');

          // Load alternative tours that do NOT match user categories
          _alternativeTours = allTours.where((tour) {
            final matches = tour.category.any(
              (tourCategory) =>
                  userCategories.contains(tourCategory.toLowerCase().trim()),
            );
            return !matches;
          }).toList();
          print('Alternative tours: ${_alternativeTours.length}');
        } else {
          print('User has no categories or user data is null');
          // If no categories, load all tours as alternatives
          final allTours = await databaseService.getApprovedTours();
          _alternativeTours = allTours;
        }
      } else {
        print('No authenticated user');
        // If no user, load all tours as alternatives
        final databaseService = DatabaseService();
        final allTours = await databaseService.getApprovedTours();
        _alternativeTours = allTours;
      }

      // Load recommended tours (approved tours, limited to 3)
      final databaseService = DatabaseService();
      final allApprovedTours = await databaseService.getApprovedTours();
      _recommendedTours = allApprovedTours.take(3).toList();
      print('Recommended tours: ${_recommendedTours.length}');
    } catch (e) {
      print('Error loading tours: $e');
    } finally {
      setState(() {
        _isLoadingSuggestedTours = false;
        _isLoadingRecommendedTours = false;
        _isLoadingAlternativeTours = false;
      });
    }
  }

  // Cebu-specific categories
  final List<Map<String, dynamic>> _categories = [
    {'name': 'Adventure', 'icon': Icons.terrain, 'color': Colors.orange},
    {'name': 'Culture', 'icon': Icons.museum, 'color': Colors.purple},
    {'name': 'Nature', 'icon': Icons.park, 'color': Colors.green},
    {'name': 'City', 'icon': Icons.location_city, 'color': Colors.teal},
    {'name': 'Historical', 'icon': Icons.history, 'color': Colors.brown},
    {'name': 'Religious', 'icon': Icons.church, 'color': Colors.deepPurple},
  ];

  // Nearby Cebu destinations
  final List<Map<String, dynamic>> _nearbyDestinations = [
    {'name': 'Simala Shrine', 'distance': '45 km', 'tours': 8},
    {'name': 'Moalboal Sardine Run', 'distance': '89 km', 'tours': 15},
    {'name': 'Malapascua Island', 'distance': '130 km', 'tours': 12},
    {'name': 'Camotes Islands', 'distance': '62 km', 'tours': 10},
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  DateTime? _selectedTourDate;

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

  void _showBookNowModal(BuildContext context) {
    _selectedTourDate = null;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const AutoTranslatedText(
                'Book a Tour',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const AutoTranslatedText(
                    'Select a tour schedule date:',
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  InkWell(
                    onTap: () async {
                      final DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (picked != null) {
                        setState(() {
                          _selectedTourDate = picked;
                        });
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppTheme.dividerColor),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_today,
                              color: AppTheme.primaryColor),
                          const SizedBox(width: 12),
                          Text(
                            _selectedTourDate != null
                                ? '${_selectedTourDate!.day}/${_selectedTourDate!.month}/${_selectedTourDate!.year}'
                                : 'Select Date',
                            style: AppTheme.bodyLarge,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const AutoTranslatedText('Cancel'),
                ),
                ElevatedButton(
                  onPressed: _selectedTourDate == null
                      ? null
                      : () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => BookingScreen(
                                initialDate: _selectedTourDate,
                              ),
                            ),
                          );
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.buttonHighlight,
                  ),
                  child: const AutoTranslatedText('Book Tour'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: _getPage(_selectedIndex),
      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton.extended(
              onPressed: () => _showBookNowModal(context),
              backgroundColor: AppTheme.buttonHighlight,
              icon: const Icon(Icons.calendar_today),
              label: const AutoTranslatedText('Book Now'),
            )
          : null,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month),
            label: 'Bookings',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.message),
            label: 'Messages',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite),
            label: 'Favorites',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }

  Widget get _homePage {
    return SafeArea(
      child: CustomScrollView(
        slivers: [
          // App Bar
          SliverAppBar(
            floating: true,
            backgroundColor: Colors.white,
            elevation: 0,
            title: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.explore,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'TourMate',
                  style: AppTheme.headlineSmall.copyWith(
                    color: AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: Stack(
                  children: [
                    const Icon(Icons.notifications_outlined),
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppTheme.accentColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ],
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const NotificationScreen(),
                    ),
                  );
                },
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.language),
                onSelected: (value) {
                  if (value == 'tl') {
                    isTagalogNotifier.value = true; // Switch to Tagalog
                  } else {
                    isTagalogNotifier.value = false; // Switch to English
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'en', child: Text('English')),
                  // const PopupMenuItem(value: 'ceb', child: Text('Cebuano')), // Hide if not supported
                  const PopupMenuItem(value: 'tl', child: Text('Tagalog')),
                ],
              ),
            ],
          ),
          // Content
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Search Bar
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search Cebu tours, guides, or destinations',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.filter_list),
                        onPressed: () {
                          // Handle filters
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                ),
                // Recommended Tours Carousel
                Padding(
                  padding: const EdgeInsets.only(left: 16, bottom: 8),
                  child: AutoTranslatedText(
                    'Recommended Cebu Tours',
                    style: AppTheme.headlineSmall,
                  ),
                ),
                _isLoadingRecommendedTours
                    ? const Center(child: CircularProgressIndicator())
                    : carousel.CarouselSlider(
                        options: carousel.CarouselOptions(
                          height: 310,
                          viewportFraction: 0.85,
                          enlargeCenterPage: true,
                          autoPlay: true,
                          autoPlayInterval: const Duration(seconds: 5),
                          enableInfiniteScroll: true,
                        ),
                        items: _recommendedTours.map((tour) {
                          return GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      TourDetailsScreen(tourId: tour.id),
                                ),
                              );
                            },
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 5),
                              decoration: AppTheme.cardDecoration,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Tour Image
                                  Container(
                                    height: 160,
                                    decoration: BoxDecoration(
                                      color: AppTheme.primaryColor.withOpacity(
                                        0.2,
                                      ),
                                      borderRadius: const BorderRadius.vertical(
                                        top: Radius.circular(16),
                                      ),
                                      image: DecorationImage(
                                        image: tour.mediaURL.isNotEmpty &&
                                                tour.mediaURL.first
                                                    .startsWith('http')
                                            ? NetworkImage(tour.mediaURL.first)
                                                as ImageProvider<Object>
                                            : const AssetImage(
                                                    'assets/images/default_tour.jpg')
                                                as ImageProvider<Object>,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                    child: Stack(
                                      children: [
                                        if (tour.mediaURL.isEmpty ||
                                            !tour.mediaURL.first
                                                .startsWith('http'))
                                          Center(
                                            child: Icon(
                                              Icons.image,
                                              size: 60,
                                              color: AppTheme.primaryColor
                                                  .withOpacity(0.5),
                                            ),
                                          ),
                                        Positioned(
                                          top: 12,
                                          right: 12,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Row(
                                              children: [
                                                const Icon(
                                                  Icons.star,
                                                  size: 16,
                                                  color: Colors.amber,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  tour.rating
                                                      .toStringAsFixed(1),
                                                  style: AppTheme.bodySmall
                                                      .copyWith(
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Tour Info
                                  Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          tour.title,
                                          style: AppTheme.bodyLarge.copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.location_on,
                                              size: 14,
                                              color: AppTheme.textSecondary,
                                            ),
                                            const SizedBox(width: 4),
                                            Expanded(
                                              child: Text(
                                                tour.meetingPoint,
                                                style: AppTheme.bodySmall,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              '₱${tour.price.toStringAsFixed(0)}/person',
                                              style:
                                                  AppTheme.bodyLarge.copyWith(
                                                color: AppTheme.primaryColor,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            Text(
                                              '${tour.duration} hours',
                                              style: AppTheme.bodySmall,
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
                        }).toList(),
                      ),
                const SizedBox(height: 24),
                // Categories
                Padding(
                  padding: const EdgeInsets.only(left: 16, bottom: 16),
                  child: AutoTranslatedText(
                    'Explore Categories',
                    style: AppTheme.headlineSmall,
                  ),
                ),
                SizedBox(
                  height: 100,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _categories.length,
                    itemBuilder: (context, index) {
                      final category = _categories[index];
                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CategoryBasedToursScreen(
                                category: category['name'],
                              ),
                            ),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.only(right: 16),
                          child: Column(
                            children: [
                              Container(
                                width: 64,
                                height: 64,
                                decoration: BoxDecoration(
                                  color: category['color'].withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Icon(
                                  category['icon'],
                                  color: category['color'],
                                  size: 32,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(category['name'], style: AppTheme.bodySmall),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 24),
                // Suggested Tours
                Padding(
                  padding: const EdgeInsets.only(left: 16, bottom: 16),
                  child: AutoTranslatedText(
                    'Suggested Tours',
                    style: AppTheme.headlineSmall,
                  ),
                ),
                _isLoadingSuggestedTours
                    ? const Center(child: CircularProgressIndicator())
                    : _suggestedTours.isEmpty
                        ? Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              'No tours match your interests. Try updating your profile categories.',
                              style: AppTheme.bodySmall,
                            ),
                          )
                        : Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Column(
                              children: _suggestedTours.map((tour) {
                                return GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            TourDetailsScreen(tourId: tour.id),
                                      ),
                                    );
                                  },
                                  child: Container(
                                    margin: const EdgeInsets.only(bottom: 16),
                                    decoration: AppTheme.cardDecoration,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        // Tour Image
                                        Container(
                                          height: 160,
                                          decoration: BoxDecoration(
                                            color: AppTheme.primaryColor
                                                .withOpacity(0.2),
                                            borderRadius:
                                                const BorderRadius.vertical(
                                              top: Radius.circular(16),
                                            ),
                                            image: DecorationImage(
                                              image: tour.mediaURL.isNotEmpty &&
                                                      tour.mediaURL.first
                                                          .startsWith('http')
                                                  ? NetworkImage(
                                                          tour.mediaURL.first)
                                                      as ImageProvider<Object>
                                                  : const AssetImage(
                                                          'assets/images/default_tour.jpg')
                                                      as ImageProvider<Object>,
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                          child: Stack(
                                            children: [
                                              if (tour.mediaURL.isEmpty ||
                                                  !tour.mediaURL.first
                                                      .startsWith('http'))
                                                Center(
                                                  child: Icon(
                                                    Icons.image,
                                                    size: 60,
                                                    color: AppTheme.primaryColor
                                                        .withOpacity(0.5),
                                                  ),
                                                ),
                                              Positioned(
                                                top: 12,
                                                right: 12,
                                                child: Container(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                    horizontal: 8,
                                                    vertical: 4,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: Colors.white,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            12),
                                                  ),
                                                  child: Row(
                                                    children: [
                                                      const Icon(
                                                        Icons.star,
                                                        size: 16,
                                                        color: Colors.amber,
                                                      ),
                                                      const SizedBox(width: 4),
                                                      Text(
                                                        tour.rating
                                                            .toStringAsFixed(1),
                                                        style: AppTheme
                                                            .bodySmall
                                                            .copyWith(
                                                          fontWeight:
                                                              FontWeight.w600,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        // Tour Info
                                        Padding(
                                          padding: const EdgeInsets.all(16),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                tour.title,
                                                style:
                                                    AppTheme.bodyLarge.copyWith(
                                                  fontWeight: FontWeight.w600,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(height: 4),
                                              Row(
                                                children: [
                                                  Icon(
                                                    Icons.location_on,
                                                    size: 14,
                                                    color:
                                                        AppTheme.textSecondary,
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Expanded(
                                                    child: Text(
                                                      tour.meetingPoint,
                                                      style: AppTheme.bodySmall,
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 8),
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  Text(
                                                    '₱${tour.price.toStringAsFixed(0)}/person',
                                                    style: AppTheme.bodyLarge
                                                        .copyWith(
                                                      color:
                                                          AppTheme.primaryColor,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                  Text(
                                                    '${tour.duration} hours',
                                                    style: AppTheme.bodySmall,
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
                              }).toList(),
                            ),
                          ),
                const SizedBox(height: 24),
                // Alternative Cebu Tours
                Padding(
                  padding: const EdgeInsets.only(left: 16, bottom: 16),
                  child: AutoTranslatedText(
                    'Alternative Cebu Tours',
                    style: AppTheme.headlineSmall,
                  ),
                ),
                SizedBox(
                  height: 200,
                  child: _isLoadingAlternativeTours
                      ? const Center(child: CircularProgressIndicator())
                      : _alternativeTours.isEmpty
                          ? const Center(
                              child: Text(
                                  'No alternative tours available at the moment.'))
                          : ListView(
                              scrollDirection: Axis.horizontal,
                              children: _alternativeTours
                                  .map(_buildAlternativeTourFromModel)
                                  .toList(),
                            ),
                ),
                const SizedBox(height: 80), // Space for FAB
              ],
            ),
          ),
        ],
      ),
    );
  }
}
