import 'package:flutter/material.dart';
import '../../utils/app_theme.dart';
import '../tour/tour_details_screen.dart';
import '../../widgets/auto_translated_text.dart';

class CategoryBasedToursScreen extends StatelessWidget {
  final String category;

  const CategoryBasedToursScreen({super.key, required this.category});

  // Sample tours data - in a real app, this would come from a service
  List<Map<String, dynamic>> get _toursForCategory {
    // This is a simplified version - in production, fetch from API or database
    final allTours = [
      {
        'id': 'kawasan_falls',
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
        'id': 'oslob_whale_shark',
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
        'id': 'moalboal_sardines',
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
      // Add more tours for other categories as needed
      {
        'id': 'cebu_city_tour',
        'title': 'Cebu City Historical Walking Tour',
        'location': 'Cebu City, Cebu',
        'price': 1500.0,
        'rating': 4.6,
        'image':
            'https://images.unsplash.com/photo-1469474968028-56623f02e42e?q=80&w=1000&auto=format&fit=crop',
        'duration': '6 hours',
        'guide': 'Ana Reyes',
        'description': 'Explore the rich history and culture of Cebu City.',
        'category': 'City',
      },
      {
        'id': 'magellan_cross',
        'title': 'Magellan\'s Cross and Basilica Tour',
        'location': 'Cebu City, Cebu',
        'price': 1200.0,
        'rating': 4.5,
        'image':
            'https://images.unsplash.com/photo-1549144511-f099e773c147?q=80&w=1000&auto=format&fit=crop',
        'duration': '4 hours',
        'guide': 'Carlos Santos',
        'description': 'Visit historical religious sites in Cebu.',
        'category': 'Historical',
      },
      {
        'id': 'santo_nino_basilica',
        'title': 'Santo Niño Basilica Pilgrimage',
        'location': 'Cebu City, Cebu',
        'price': 1000.0,
        'rating': 4.7,
        'image':
            'https://images.unsplash.com/photo-1549144511-f099e773c147?q=80&w=1000&auto=format&fit=crop',
        'duration': '3 hours',
        'guide': 'Maria Cruz',
        'description':
            'Experience the spiritual significance of Cebu\'s religious heritage.',
        'category': 'Religious',
      },
    ];

    return allTours.where((tour) => tour['category'] == category).toList();
  }

  @override
  Widget build(BuildContext context) {
    final tours = _toursForCategory;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: AutoTranslatedText(
          '$category Tours',
          style: AppTheme.headlineSmall.copyWith(
            color: AppTheme.primaryColor,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: tours.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.tour_outlined,
                    size: 64,
                    color: AppTheme.textSecondary,
                  ),
                  const SizedBox(height: 16),
                  AutoTranslatedText(
                    'No tours available for $category category yet.',
                    style: AppTheme.bodyLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  AutoTranslatedText(
                    'Check back soon for new adventures!',
                    style: AppTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: tours.length,
              itemBuilder: (context, index) {
                final tour = tours[index];
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
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: AppTheme.cardDecoration,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Tour Image
                        Container(
                          height: 160,
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withOpacity(0.2),
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(16),
                            ),
                            image: DecorationImage(
                              image: (tour['image'] as String)
                                      .startsWith('http')
                                  ? NetworkImage(tour['image'])
                                  : AssetImage('assets/images/${tour['image']}')
                                      as ImageProvider,
                              fit: BoxFit.cover,
                            ),
                          ),
                          child: Stack(
                            children: [
                              if (!(tour['image'] as String).startsWith('http'))
                                Center(
                                  child: Icon(
                                    Icons.image,
                                    size: 60,
                                    color:
                                        AppTheme.primaryColor.withOpacity(0.5),
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
                                    borderRadius: BorderRadius.circular(12),
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
              },
            ),
    );
  }
}
