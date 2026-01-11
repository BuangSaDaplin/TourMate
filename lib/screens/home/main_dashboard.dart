import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart' as carousel;
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

class MainDashboard extends StatefulWidget {
  const MainDashboard({super.key});

  @override
  State<MainDashboard> createState() => _MainDashboardState();
}

class _MainDashboardState extends State<MainDashboard> {
  int _selectedIndex = 0;
  final _searchController = TextEditingController();
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      _homePage,
      const BookingsScreen(),
      const TouristMessagesScreen(),
      const FavoritesScreen(),
      const ProfileScreen(),
    ];
  }

  // Cebu-specific recommended tours with Real Network Images
  final List<Map<String, dynamic>> _recommendedTours = [
    {
      'id': 'kawasan_falls', // Matches cebu_graph_data.dart
      'title': 'Kawasan Falls Canyoneering',
      'location': 'Badian, Cebu',
      'price': 2500.0,
      'rating': 4.9,
      'image':
          'https://images.unsplash.com/photo-1518509562904-e7ef99cdcc86?q=80&w=1000&auto=format&fit=crop',
      'duration': '8 hours',
      'guide': 'Juan dela Cruz',
      'description':
          'Experience the thrill of jumping, swimming, and trekking.',
      'category': 'Adventure',
    },
    {
      'id': 'oslob_whale_shark', // Matches cebu_graph_data.dart
      'title': 'Oslob Whale Shark Encounter',
      'location': 'Oslob, Cebu',
      'price': 3500.0,
      'rating': 4.8,
      'image':
          'https://images.unsplash.com/photo-1582967788606-a171f1080ca8?q=80&w=1000&auto=format&fit=crop',
      'duration': '10 hours',
      'guide': 'Maria Santos',
      'description': 'Swim with gentle whale sharks in crystal-clear waters.',
      'category': 'Beach',
    },
    {
      'id': 'moalboal_sardines', // Matches cebu_graph_data.dart
      'title': 'Moalboal Sardine Run',
      'location': 'Moalboal, Cebu',
      'price': 1800.0,
      'rating': 4.7,
      'image':
          'https://images.unsplash.com/photo-1544551763-46a013bb70d5?q=80&w=1000&auto=format&fit=crop',
      'duration': '4 hours',
      'guide': 'Pedro Penduko',
      'description': 'Snorkel with millions of sardines.',
      'category': 'Beach',
    },
  ];

  // Cebu-specific categories
  final List<Map<String, dynamic>> _categories = [
    {'name': 'Adventure', 'icon': Icons.terrain, 'color': Colors.orange},
    {'name': 'Culture', 'icon': Icons.museum, 'color': Colors.purple},
    {'name': 'Food', 'icon': Icons.restaurant, 'color': Colors.red},
    {'name': 'Nature', 'icon': Icons.park, 'color': Colors.green},
    {'name': 'Beach', 'icon': Icons.beach_access, 'color': Colors.blue},
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

  // Alternative Cebu destinations
  final List<Map<String, dynamic>> _alternativeDestinations = [
    {
      'name': 'Sumilon Island',
      'description': 'Pristine sandbar and marine sanctuary',
      'tours': 6,
    },
    {
      'name': 'Tumalog Falls',
      'description': 'Enchanting waterfall with misty cascades',
      'tours': 5,
    },
    {
      'name': 'Bojo River Cruise',
      'description': 'Peaceful river cruise through mangroves',
      'tours': 4,
    },
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
      body: _pages[_selectedIndex],
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
                carousel.CarouselSlider(
                  options: carousel.CarouselOptions(
                    height: 280,
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
                                TourDetailsScreen(tourId: tour['id']),
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
                                  // Logic: If string starts with http, use NetworkImage, else use AssetImage
                                  image: (tour['image'] as String)
                                          .startsWith('http')
                                      ? NetworkImage(tour['image'])
                                      : AssetImage(
                                              'assets/images/${tour['image']}')
                                          as ImageProvider,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              child: Stack(
                                children: [
                                  // Only show icon if using asset image (no network URL)
                                  if (!(tour['image'] as String)
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
                                        borderRadius: BorderRadius.circular(
                                          12,
                                        ),
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
                                            tour['rating'].toString(),
                                            style: AppTheme.bodySmall.copyWith(
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
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    tour['title'],
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
                                          tour['location'],
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
                                        '₱${tour['price'].toStringAsFixed(0)}/person',
                                        style: AppTheme.bodyLarge.copyWith(
                                          color: AppTheme.primaryColor,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        tour['duration'],
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
                // Nearby Destinations
                Padding(
                  padding: const EdgeInsets.only(left: 16, bottom: 16),
                  child: AutoTranslatedText(
                    'Nearby Cebu Destinations',
                    style: AppTheme.headlineSmall,
                  ),
                ),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _nearbyDestinations.length,
                  itemBuilder: (context, index) {
                    final destination = _nearbyDestinations[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: AppTheme.cardDecoration,
                      child: Row(
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.place,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  destination['name'],
                                  style: AppTheme.bodyLarge.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
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
                                    Text(
                                      destination['distance'],
                                      style: AppTheme.bodySmall,
                                    ),
                                    const SizedBox(width: 16),
                                    Icon(
                                      Icons.tour,
                                      size: 14,
                                      color: AppTheme.textSecondary,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${destination['tours']} tours',
                                      style: AppTheme.bodySmall,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                            color: AppTheme.textSecondary,
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),
                // Alternative Destinations
                Padding(
                  padding: const EdgeInsets.only(left: 16, bottom: 16),
                  child: AutoTranslatedText(
                    'Alternative Cebu Destinations',
                    style: AppTheme.headlineSmall,
                  ),
                ),
                SizedBox(
                  height: 120,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _alternativeDestinations.length,
                    itemBuilder: (context, index) {
                      final destination = _alternativeDestinations[index];
                      return Container(
                        width: 200,
                        margin: const EdgeInsets.only(right: 16),
                        padding: const EdgeInsets.all(16),
                        decoration: AppTheme.cardDecoration,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              destination['name'],
                              style: AppTheme.bodyLarge.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              destination['description'],
                              style: AppTheme.bodySmall,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const Spacer(),
                            Row(
                              children: [
                                Icon(
                                  Icons.tour,
                                  size: 14,
                                  color: AppTheme.textSecondary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${destination['tours']} tours available',
                                  style: AppTheme.bodySmall.copyWith(
                                    color: AppTheme.primaryColor,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
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
