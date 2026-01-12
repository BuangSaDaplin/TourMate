import 'package:flutter/material.dart';
import '../../utils/app_theme.dart';
import '../tour/tour_details_screen.dart';
import '../../widgets/auto_translated_text.dart';
import '../../services/database_service.dart';
import '../../models/tour_model.dart';

class CategoryBasedToursScreen extends StatefulWidget {
  final String category;

  const CategoryBasedToursScreen({super.key, required this.category});

  @override
  State<CategoryBasedToursScreen> createState() =>
      _CategoryBasedToursScreenState();
}

class _CategoryBasedToursScreenState extends State<CategoryBasedToursScreen> {
  List<TourModel> _tours = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadTours();
  }

  Future<void> _loadTours() async {
    try {
      final db = DatabaseService();
      final approvedTours = await db.getApprovedTours();
      final filteredTours = approvedTours
          .where((tour) => tour.category.contains(widget.category))
          .toList();

      setState(() {
        _tours = filteredTours;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: AutoTranslatedText(
            '${widget.category} Tours',
            style: AppTheme.headlineSmall.copyWith(
              color: AppTheme.primaryColor,
            ),
          ),
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

    if (_error != null) {
      return Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: AutoTranslatedText(
            '${widget.category} Tours',
            style: AppTheme.headlineSmall.copyWith(
              color: AppTheme.primaryColor,
            ),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: AppTheme.errorColor,
              ),
              const SizedBox(height: 16),
              Text(
                'Failed to load tours',
                style: AppTheme.bodyLarge,
              ),
              const SizedBox(height: 8),
              Text(
                _error!,
                style: AppTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: AutoTranslatedText(
          '${widget.category} Tours',
          style: AppTheme.headlineSmall.copyWith(
            color: AppTheme.primaryColor,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _tours.isEmpty
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
                    'No tours available for ${widget.category} category yet.',
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
              itemCount: _tours.length,
              itemBuilder: (context, index) {
                final tour = _tours[index];
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
                              image: tour.mediaURL.isNotEmpty
                                  ? (tour.mediaURL.first.startsWith('http')
                                      ? NetworkImage(tour.mediaURL.first)
                                      : AssetImage(
                                              'assets/images/${tour.mediaURL.first}')
                                          as ImageProvider)
                                  : const AssetImage(
                                      'assets/images/default_tour.jpg'),
                              fit: BoxFit.cover,
                            ),
                          ),
                          child: Stack(
                            children: [
                              if (tour.mediaURL.isEmpty ||
                                  !tour.mediaURL.first.startsWith('http'))
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
                                        tour.rating.toStringAsFixed(1),
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
                                    style: AppTheme.bodyLarge.copyWith(
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
              },
            ),
    );
  }
}
