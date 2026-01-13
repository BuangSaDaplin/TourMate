import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tourmate_app/models/tour_model.dart';
import '../../utils/app_theme.dart';
import 'tour_details_screen.dart';

class TourBrowseScreen extends StatefulWidget {
  const TourBrowseScreen({super.key});

  @override
  State<TourBrowseScreen> createState() => _TourBrowseScreenState();
}

class _TourBrowseScreenState extends State<TourBrowseScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'All';
  String _selectedSort = 'Rating';
  RangeValues _priceRange = const RangeValues(0, 10000);
  double _minRating = 0.0;
  bool _showFilters = false;

  final List<String> _categories = [
    'All',
    'Adventure',
    'Culture',
    'Nature',
    'City',
    'Historical',
    'Religious'
  ];

  final List<String> _sortOptions = [
    'Rating',
    'Price: Low to High',
    'Price: High to Low',
    'Duration',
    'Popularity'
  ];

  // Mock tour data - replace with actual data fetching
  final List<TourModel> _allTours = [
    TourModel(
      id: '1',
      title: 'Kawasan Falls Canyoneering Adventure',
      description:
          'Experience the thrill of jumping, swimming, and trekking through the stunning Kawasan Falls canyon in Badian, Cebu.',
      price: 2500.0,
      category: ['Adventure'],
      maxParticipants: 12,
      currentParticipants: 8,
      startTime: DateTime.now().add(const Duration(days: 7)),
      endTime: DateTime.now().add(const Duration(days: 7, hours: 8)),
      meetingPoint: 'Badian Town Center',
      mediaURL: ['kawasan1.jpg', 'kawasan2.jpg', 'kawasan3.jpg'],
      createdBy: 'guide_001',
      shared: true,
      itinerary: [
        {'time': '08:00', 'activity': 'Meet at Badian Town Center'},
        {'time': '09:00', 'activity': 'Safety briefing and equipment'},
        {'time': '10:00', 'activity': 'Begin canyoneering adventure'},
        {'time': '16:00', 'activity': 'Return and farewell'}
      ],
      status: 'active',
      duration: 8,
      languages: ['English'],
      highlights: [
        'Jump from heights up to 10 meters',
        'Swim in natural pools',
        'Trek through tropical canyon',
        'Professional guide and safety equipment',
        'Lunch included',
      ],
    ),
    TourModel(
      id: '2',
      title: 'Cebu City Historical Walking Tour',
      description:
          'Explore the rich history of Cebu City, from Magellan\'s Cross to Fort San Pedro.',
      price: 1200.0,
      category: ['Historical'],
      maxParticipants: 15,
      currentParticipants: 5,
      startTime: DateTime.now().add(const Duration(days: 3)),
      endTime: DateTime.now().add(const Duration(days: 3, hours: 4)),
      meetingPoint: 'Magellan\'s Cross',
      mediaURL: ['cebu_history1.jpg', 'cebu_history2.jpg'],
      createdBy: 'guide_002',
      shared: true,
      itinerary: [
        {'time': '09:00', 'activity': 'Start at Magellan\'s Cross'},
        {'time': '10:00', 'activity': 'Visit Fort San Pedro'},
        {'time': '11:00', 'activity': 'Explore Basilica del Santo Niño'},
        {'time': '12:00', 'activity': 'Tour ends'}
      ],
      status: 'active',
      duration: 4,
      languages: ['English', 'Cebuano'],
      highlights: [
        'Visit Magellan\'s Cross',
        'Explore Fort San Pedro',
        'Discover Basilica del Santo Niño',
        'Learn about Cebu\'s rich history',
        'Professional guide included',
      ],
    ),
    TourModel(
      id: '3',
      title: 'Moalboal Sardine Run & Beach Tour',
      description:
          'Snorkel with millions of sardines and relax on pristine beaches in Moalboal.',
      price: 1800.0,
      category: ['Beach'],
      maxParticipants: 10,
      currentParticipants: 10,
      startTime: DateTime.now().add(const Duration(days: 5)),
      endTime: DateTime.now().add(const Duration(days: 5, hours: 6)),
      meetingPoint: 'Moalboal Pier',
      mediaURL: ['moalboal1.jpg', 'moalboal2.jpg', 'moalboal3.jpg'],
      createdBy: 'guide_003',
      shared: true,
      itinerary: [
        {'time': '08:00', 'activity': 'Meet at Moalboal Pier'},
        {'time': '09:00', 'activity': 'Sardine Run snorkeling'},
        {'time': '12:00', 'activity': 'Beach relaxation and lunch'},
        {'time': '14:00', 'activity': 'Tour ends'}
      ],
      status: 'active',
      duration: 6,
      languages: ['English'],
      highlights: [
        'Snorkel with millions of sardines',
        'Explore vibrant coral reefs',
        'Relax on pristine beaches',
        'Professional snorkeling guide',
        'Lunch and equipment included',
      ],
    ),
  ];

  List<TourModel> get _filteredTours {
    List<TourModel> filtered = _allTours.where((tour) {
      final matchesCategory = _selectedCategory == 'All' ||
          tour.category.contains(_selectedCategory);
      final matchesPrice =
          tour.price >= _priceRange.start && tour.price <= _priceRange.end;
      final matchesSearch = _searchController.text.isEmpty ||
          tour.title
              .toLowerCase()
              .contains(_searchController.text.toLowerCase()) ||
          tour.description
              .toLowerCase()
              .contains(_searchController.text.toLowerCase());
      final matchesRating =
          true; // Mock rating filter - implement when ratings are available.

      return matchesCategory && matchesPrice && matchesSearch && matchesRating;
    }).toList();

    filtered.sort((a, b) {
      switch (_selectedSort) {
        case 'Price: Low to High':
          return a.price.compareTo(b.price);
        case 'Price: High to Low':
          return b.price.compareTo(a.price);
        case 'Duration':
          final aDuration = a.endTime.difference(a.startTime);
          final bDuration = b.endTime.difference(b.startTime);
          return aDuration.compareTo(bDuration);
        case 'Rating':
        default:
          return b.title.compareTo(a.title); // Alphabetical fallback
      }
    });
    return filtered;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Browse Tours'),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon:
                Icon(_showFilters ? Icons.filter_list_off : Icons.filter_list),
            onPressed: () => setState(() => _showFilters = !_showFilters),
            tooltip: 'Toggle Filters',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search tours...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              onChanged: (value) => setState(() {}),
            ),
          ),

          // Filters Panel
          if (_showFilters) _buildFiltersPanel(),

          // Results Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text(
                  '${_filteredTours.length} tours found',
                  style:
                      AppTheme.bodyLarge.copyWith(fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                DropdownButton<String>(
                  value: _selectedSort,
                  underline: Container(),
                  items: _sortOptions.map((option) {
                    return DropdownMenuItem(
                      value: option,
                      child: Text(option, style: AppTheme.bodyMedium),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedSort = value);
                    }
                  },
                ),
              ],
            ),
          ),

          // Tours Grid
          Expanded(
            child: _filteredTours.isEmpty
                ? _buildEmptyState()
                : GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 0.75,
                    ),
                    itemCount: _filteredTours.length,
                    itemBuilder: (context, index) {
                      return _buildTourCard(_filteredTours[index]);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltersPanel() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Filters', style: AppTheme.headlineSmall),
              const Spacer(),
              TextButton(
                onPressed: () {
                  setState(() {
                    _selectedCategory = 'All';
                    _priceRange = const RangeValues(0, 10000);
                    _minRating = 0.0;
                  });
                },
                child: const Text('Reset'),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Category Filter
          Text('Category',
              style: AppTheme.bodyLarge.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: _categories.map((category) {
              return FilterChip(
                label: Text(category),
                selected: _selectedCategory == category,
                onSelected: (selected) {
                  setState(() => _selectedCategory = category);
                },
                backgroundColor: Colors.grey[100],
                selectedColor: AppTheme.primaryColor.withOpacity(0.2),
                checkmarkColor: AppTheme.primaryColor,
              );
            }).toList(),
          ),

          const SizedBox(height: 16),

          // Price Range
          Text('Price Range (₱)',
              style: AppTheme.bodyLarge.copyWith(fontWeight: FontWeight.w600)),
          RangeSlider(
            values: _priceRange,
            min: 0,
            max: 10000,
            divisions: 20,
            labels: RangeLabels(
              '₱${_priceRange.start.round()}',
              '₱${_priceRange.end.round()}',
            ),
            onChanged: (values) => setState(() => _priceRange = values),
          ),

          // Rating Filter
          Text('Minimum Rating',
              style: AppTheme.bodyLarge.copyWith(fontWeight: FontWeight.w600)),
          Slider(
            value: _minRating,
            min: 0,
            max: 5,
            divisions: 10,
            label: _minRating.toStringAsFixed(1),
            onChanged: (value) => setState(() => _minRating = value),
          ),
        ],
      ),
    );
  }

  Widget _buildTourCard(TourModel tour) {
    final hours = tour.duration;
    final minutes = 0; // Since duration is stored in hours, no minutes needed

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TourDetailsScreen(tourId: tour.id),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tour Image
            Container(
              height: 120,
              decoration: BoxDecoration(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(12)),
                image: DecorationImage(
                  image: AssetImage(
                      'assets/images/${tour.mediaURL.isNotEmpty ? tour.mediaURL[0] : 'default_tour.jpg'}'),
                  fit: BoxFit.cover,
                ),
              ),
            ),

            // Tour Details
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tour.title,
                    style: AppTheme.bodyLarge
                        .copyWith(fontWeight: FontWeight.w600),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),

                  // Category and Duration
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          tour.category.isNotEmpty
                              ? tour.category[0]
                              : 'No Category',
                          style: AppTheme.bodySmall.copyWith(
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(Icons.access_time,
                          size: 14, color: AppTheme.textSecondary),
                      const SizedBox(width: 2),
                      Text(
                        '${hours}h ${minutes}m',
                        style: AppTheme.bodySmall
                            .copyWith(color: AppTheme.textSecondary),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Price and Rating
                  Row(
                    children: [
                      Text(
                        '₱${tour.price.toStringAsFixed(0)}',
                        style: AppTheme.headlineSmall.copyWith(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          const Icon(Icons.star, size: 14, color: Colors.amber),
                          const SizedBox(width: 2),
                          Text(
                            '4.5', // Mock rating
                            style: AppTheme.bodySmall
                                .copyWith(fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 4),

                  // Availability
                  Text(
                    '${tour.maxParticipants - tour.currentParticipants} spots left',
                    style: AppTheme.bodySmall.copyWith(
                      color: tour.maxParticipants - tour.currentParticipants > 0
                          ? AppTheme.successColor
                          : AppTheme.errorColor,
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

  Widget _buildEmptyState() {
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
            'No tours found',
            style:
                AppTheme.headlineMedium.copyWith(color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your filters or search terms',
            style: AppTheme.bodyMedium.copyWith(color: AppTheme.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _searchController.clear();
                _selectedCategory = 'All';
                _priceRange = const RangeValues(0, 10000);
                _minRating = 0.0;
              });
            },
            child: const Text('Clear Filters'),
          ),
        ],
      ),
    );
  }
}
