import '../data/tour_spot_model.dart';

/// Service for generating highlight templates based on tour spots.
///
/// This service provides standardized highlight descriptions for different
/// types of tourist attractions in Cebu, ensuring consistent and engaging
/// tour descriptions.
class HighlightsTemplateService {
  /// Private constructor for singleton pattern
  HighlightsTemplateService._();

  /// Singleton instance
  static final HighlightsTemplateService _instance =
      HighlightsTemplateService._();

  /// Factory constructor to return singleton instance
  factory HighlightsTemplateService() => _instance;

  /// Generates highlights for a list of tour spots.
  ///
  /// Combines highlights from individual spots and adds contextual highlights
  /// based on the combination of selected spots.
  List<String> generateHighlightsForSpots(List<TourSpot> spots) {
    final Set<String> allHighlights = {};

    // Add highlights from individual spots
    for (final spot in spots) {
      final spotHighlights = _getHighlightsForSpot(spot);
      allHighlights.addAll(spotHighlights);
    }

    // Add contextual highlights based on spot combinations
    final contextualHighlights = _getContextualHighlights(spots);
    allHighlights.addAll(contextualHighlights);

    return allHighlights.toList();
  }

  /// Gets highlights for a single tour spot.
  List<String> _getHighlightsForSpot(TourSpot spot) {
    // Return existing highlights if available
    if (spot.highlights != null && spot.highlights!.isNotEmpty) {
      return spot.highlights!;
    }

    // Generate highlights based on spot category and properties
    switch (spot.category) {
      case TourSpotCategory.religious:
        return _getReligiousHighlights(spot);
      case TourSpotCategory.historical:
        return _getHistoricalHighlights(spot);
      case TourSpotCategory.natural:
        return _getNaturalHighlights(spot);
      case TourSpotCategory.viewpoint:
        return _getViewpointHighlights(spot);
      case TourSpotCategory.beach:
        return _getBeachHighlights(spot);
      case TourSpotCategory.entertainment:
        return _getEntertainmentHighlights(spot);
      case TourSpotCategory.food:
        return _getFoodHighlights(spot);
      case TourSpotCategory.mountain:
        return _getMountainHighlights(spot);
      default:
        return _getGeneralHighlights(spot);
    }
  }

  List<String> _getReligiousHighlights(TourSpot spot) {
    final highlights = <String>[];

    if (spot.name.contains('Basilica')) {
      highlights.addAll([
        'Visit the oldest Roman Catholic church in the Philippines',
        'See the revered image of the Santo Niño de Cebu',
        'Experience centuries of Filipino Catholic heritage',
        'Beautiful colonial architecture and religious artifacts',
      ]);
    } else if (spot.name.contains('Cathedral')) {
      highlights.addAll([
        'Marvel at stunning Gothic architecture',
        'Learn about Cebu\'s religious history as the seat of the Archdiocese',
        'Experience peaceful prayer and reflection spaces',
        'Historic religious ceremonies and traditions',
      ]);
    } else if (spot.name.contains('Temple')) {
      highlights.addAll([
        'Explore unique Taoist architecture and gardens',
        'Experience cultural diversity in Cebu\'s religious landscape',
        'Peaceful meditation and spiritual atmosphere',
        'Traditional ceremonies and cultural practices',
      ]);
    } else if (spot.name.contains('Cross')) {
      highlights.addAll([
        'Stand at the site where Christianity first arrived in the Philippines',
        'Historical cross planted by Ferdinand Magellan in 1521',
        'Symbol of Cebu\'s pivotal role in Philippine history',
        'Sacred site for religious pilgrims and history enthusiasts',
      ]);
    } else {
      highlights.addAll([
        'Experience Cebu\'s rich religious heritage',
        'Visit historic places of worship',
        'Learn about local religious traditions and customs',
        'Peaceful spiritual atmosphere and beautiful architecture',
      ]);
    }

    return highlights;
  }

  List<String> _getHistoricalHighlights(TourSpot spot) {
    final highlights = <String>[];

    if (spot.name.contains('Fort')) {
      highlights.addAll([
        'Explore Cebu\'s oldest triangular bastion fort built in 1565',
        'Interactive museum showcasing colonial military history',
        'Walk the ramparts with panoramic city views',
        'Authentic Spanish colonial fortification architecture',
      ]);
    } else if (spot.name.contains('Street') || spot.name.contains('Colon')) {
      highlights.addAll([
        'Walk the oldest street in the Philippines',
        'Historic buildings and local markets',
        'Experience Cebu\'s vibrant commercial heritage',
        'Blend of colonial architecture and modern life',
      ]);
    } else if (spot.name.contains('Monument')) {
      highlights.addAll([
        'See life-sized sculptures depicting Cebuano history',
        'Interactive tableaux of significant historical events',
        'Learn about Cebu\'s role in Philippine independence',
        'Beautiful outdoor historical museum experience',
      ]);
    } else {
      highlights.addAll([
        'Discover Cebu\'s rich historical heritage',
        'Explore colonial-era buildings and landmarks',
        'Learn about pivotal moments in Philippine history',
        'Well-preserved historical sites and monuments',
      ]);
    }

    return highlights;
  }

  List<String> _getNaturalHighlights(TourSpot spot) {
    final highlights = <String>[];

    if (spot.name.contains('Whale') || spot.name.contains('Shark')) {
      highlights.addAll([
        'Swim with gentle whale sharks in their natural habitat',
        'Snorkel in crystal clear waters with professional guides',
        'Safety briefing and marine conservation education',
        'Morning activity for optimal viewing conditions',
      ]);
    } else if (spot.name.contains('Sardine')) {
      highlights.addAll([
        'Snorkel with millions of sardines in the famous sardine run',
        'Witness one of nature\'s most spectacular phenomena',
        'Crystal clear waters perfect for underwater photography',
        'Guided snorkeling experience with marine experts',
      ]);
    } else if (spot.name.contains('Canyoneering') ||
        spot.name.contains('Falls')) {
      highlights.addAll([
        'Thrilling canyoneering adventure through Kawasan Falls',
        'Jump, swim, and trek through stunning natural landscapes',
        'Professional guides and safety equipment provided',
        'Adrenaline-pumping natural water slides and pools',
      ]);
    } else if (spot.name.contains('Flower') || spot.name.contains('Garden')) {
      highlights.addAll([
        'Stroll through vibrant flower gardens and landscapes',
        'Known as Cebu\'s "Little Amsterdam" for colorful blooms',
        'Peaceful nature walks and photography opportunities',
        'Seasonal flower displays and garden tours',
      ]);
    } else {
      highlights.addAll([
        'Experience Cebu\'s diverse natural beauty',
        'Explore pristine natural landscapes and ecosystems',
        'Guided nature walks and wildlife observation',
        'Sustainable eco-tourism experiences',
      ]);
    }

    return highlights;
  }

  List<String> _getViewpointHighlights(TourSpot spot) {
    final highlights = <String>[];

    if (spot.name.contains('Tops') || spot.name.contains('Lookout')) {
      highlights.addAll([
        'Breathtaking 360-degree panoramic views of Cebu City',
        'Hilltop vantage point overlooking mountains and sea',
        'Perfect for sunrise and sunset photography',
        'Scenic viewpoints and photo opportunities',
      ]);
    } else if (spot.name.contains('Mountain') || spot.name.contains('Peak')) {
      highlights.addAll([
        'Elevated viewpoint with stunning mountain landscapes',
        'Popular destination for sunrise and sunset viewing',
        'Hiking trails and nature observation points',
        'Peaceful mountain atmosphere and fresh air',
      ]);
    } else if (spot.name.contains('Bridge')) {
      highlights.addAll([
        'Iconic bridge with turquoise water views',
        'Scenic highway viewpoints along the coast',
        'Perfect photo stops during coastal drives',
        'Dramatic ocean and mountain vistas',
      ]);
    } else {
      highlights.addAll([
        'Stunning panoramic views of Cebu\'s landscapes',
        'Strategic viewpoints for city and nature photography',
        'Peaceful observation decks and scenic overlooks',
        'Breathtaking vistas at different times of day',
      ]);
    }

    return highlights;
  }

  List<String> _getBeachHighlights(TourSpot spot) {
    final highlights = <String>[];

    if (spot.name.contains('Sumilon')) {
      highlights.addAll([
        'Pristine white sand beach with crystal clear waters',
        'Island paradise accessible by boat',
        'Snorkeling and swimming in protected marine areas',
        'Relaxing beachside atmosphere and water activities',
      ]);
    } else if (spot.name.contains('Bantayan')) {
      highlights.addAll([
        'Pristine white sand beaches and turquoise waters',
        'Relaxed island atmosphere perfect for unwinding',
        'Swimming, sunbathing, and beachcombing activities',
        'Local seafood dining and island culture experience',
      ]);
    } else {
      highlights.addAll([
        'Beautiful beachfront locations with clear waters',
        'Swimming, sunbathing, and water sports activities',
        'Relaxing coastal atmosphere and scenic views',
        'Beachside dining and local culture experiences',
      ]);
    }

    return highlights;
  }

  List<String> _getEntertainmentHighlights(TourSpot spot) {
    return [
      'Modern entertainment venues and attractions',
      'Family-friendly activities and shows',
      'Interactive experiences and entertainment options',
      'Fun-filled activities for all ages',
    ];
  }

  List<String> _getFoodHighlights(TourSpot spot) {
    return [
      'Authentic Cebuano cuisine and local delicacies',
      'Fresh seafood and traditional Filipino dishes',
      'Local markets and food districts',
      'Culinary experiences and food tours',
    ];
  }

  List<String> _getMountainHighlights(TourSpot spot) {
    return [
      'Scenic mountain landscapes and hiking trails',
      'Fresh mountain air and nature exploration',
      'Adventure activities and outdoor recreation',
      'Panoramic mountain views and photography',
    ];
  }

  List<String> _getGeneralHighlights(TourSpot spot) {
    return [
      'Explore Cebu\'s diverse attractions and landmarks',
      'Guided tours with local experts and knowledge',
      'Cultural immersion and authentic local experiences',
      'Memorable adventures and sightseeing opportunities',
    ];
  }

  /// Generates contextual highlights based on combinations of spots.
  List<String> _getContextualHighlights(List<TourSpot> spots) {
    final highlights = <String>[];
    final categories = spots.map((spot) => spot.category).toSet();

    // Multi-category highlights
    if (categories.length > 1) {
      highlights.add('Comprehensive tour covering multiple attraction types');
      highlights
          .add('Diverse experiences combining culture, nature, and history');
    }

    // Religious + Historical combination
    if (categories.contains(TourSpotCategory.religious) &&
        categories.contains(TourSpotCategory.historical)) {
      highlights.add('Journey through Cebu\'s religious and colonial history');
      highlights.add('Explore the intersection of faith and historical events');
    }

    // Nature + Viewpoint combination
    if (categories.contains(TourSpotCategory.natural) &&
        categories.contains(TourSpotCategory.viewpoint)) {
      highlights
          .add('Experience Cebu\'s natural beauty from stunning viewpoints');
      highlights.add('Combine adventure with breathtaking scenic views');
    }

    // Downtown cluster (Basilica, Fort, Cathedral, etc.)
    final downtownSpots = spots
        .where((spot) =>
            spot.coordinate.latitude >= 10.29 &&
            spot.coordinate.latitude <= 10.30 &&
            spot.coordinate.longitude >= 123.88 &&
            spot.coordinate.longitude <= 123.89)
        .toList();

    if (downtownSpots.length >= 3) {
      highlights.add('Complete downtown Cebu historical walking tour');
      highlights.add('Explore Cebu\'s colonial heart and major landmarks');
    }

    // La Hills cluster
    final laHillsSpots = spots
        .where((spot) =>
            spot.coordinate.latitude >= 10.33 &&
            spot.coordinate.latitude <= 10.35)
        .toList();

    if (laHillsSpots.length >= 2) {
      highlights.add('Scenic La Hills mountain experience');
      highlights.add('Explore Cebu\'s elevated viewpoints and gardens');
    }

    return highlights;
  }
}
