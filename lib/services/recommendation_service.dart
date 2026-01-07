import 'package:tourmate_app/models/tour_model.dart';
import 'package:tourmate_app/models/user_model.dart';

class RecommendationService {
  /// THE STAR ALGORITHM IMPLEMENTATION
  /// Ranks tours based on:
  /// [S]core: Average Rating
  /// [T]rust: Guide Verification Status
  /// [A]ctivity: Popularity/Bookings
  /// [R]eliability: (Implicit in rating/verification)
  List<TourModel> getRecommendations(
    List<TourModel> allTours, {
    Map<String, UserModel>? guides,
  }) {
    if (allTours.isEmpty) return [];

    Map<String, double> tourScores = {};

    for (var tour in allTours) {
      double score = 0.0;

      // 1. TRUST (LGU Verification) - +50 Points
      bool isVerified = false;
      if (guides != null && guides.containsKey(tour.createdBy)) {
        isVerified = guides[tour.createdBy]?.isLGUVerified ?? false;
      }
      if (isVerified) score += 50.0;

      // 2. SCORE (Ratings) - Up to 25 Points
      score += (tour.rating ?? 0.0) * 5.0;

      // 3. ACTIVITY (Popularity) - Up to 15 Points
      int bookings = tour.currentParticipants ?? 0;
      score += (bookings > 30 ? 30 : bookings) * 0.5;

      tourScores[tour.id] = score;
    }

    // Sort by STAR Score Descending
    allTours.sort((a, b) {
      double scoreA = tourScores[a.id] ?? 0;
      double scoreB = tourScores[b.id] ?? 0;
      return scoreB.compareTo(scoreA);
    });

    return allTours.take(5).toList();
  }

  // Placeholder for LLM-based recommendation
  Future<List<TourModel>> callExternalLLM(String prompt, String apiKey) async {
    // In a real app, you would make an API call to a large language model
    // with the provided prompt and API key.
    // Integrate with OpenAI, Anthropic, or similar LLM service
    throw UnimplementedError('LLM integration not implemented');
  }
}
