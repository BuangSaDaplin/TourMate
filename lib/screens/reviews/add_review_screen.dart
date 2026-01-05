import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:tourmate_app/services/auth_service.dart';
import 'package:tourmate_app/services/database_service.dart';
import 'package:tourmate_app/models/review_model.dart';
import '../../utils/app_theme.dart';

class AddReviewScreen extends StatefulWidget {
  final String targetId;
  final ReviewType reviewType;

  const AddReviewScreen({
    super.key,
    required this.targetId,
    required this.reviewType,
  });

  @override
  State<AddReviewScreen> createState() => _AddReviewScreenState();
}

class _AddReviewScreenState extends State<AddReviewScreen> {
  final AuthService _authService = AuthService();
  final DatabaseService _db = DatabaseService();

  final _titleController = TextEditingController();
  final _reviewController = TextEditingController();

  double _overallRating = 0;
  bool _isLoading = false;

  // Detailed criteria ratings
  double _communicationRating = 0;
  double _knowledgeRating = 0;
  double _punctualityRating = 0;
  double _valueRating = 0;
  double _safetyRating = 0;

  @override
  void dispose() {
    _titleController.dispose();
    _reviewController.dispose();
    super.dispose();
  }

  List<ReviewCriteria> _getCriteriaForType() {
    switch (widget.reviewType) {
      case ReviewType.tour:
        return [
          ReviewCriteria(name: 'Overall Experience', rating: _overallRating),
          ReviewCriteria(name: 'Value for Money', rating: _valueRating),
          ReviewCriteria(name: 'Safety', rating: _safetyRating),
        ];
      case ReviewType.guide:
        return [
          ReviewCriteria(name: 'Communication', rating: _communicationRating),
          ReviewCriteria(name: 'Local Knowledge', rating: _knowledgeRating),
          ReviewCriteria(name: 'Punctuality', rating: _punctualityRating),
          ReviewCriteria(name: 'Professionalism', rating: _valueRating),
        ];
      case ReviewType.booking:
        return [
          ReviewCriteria(name: 'Booking Process', rating: _communicationRating),
          ReviewCriteria(name: 'Response Time', rating: _punctualityRating),
          ReviewCriteria(name: 'Accuracy', rating: _knowledgeRating),
        ];
    }
  }

  Widget _buildCriteriaRating(String label, double rating, Function(double) onRatingUpdate) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: AppTheme.bodyMedium,
            ),
          ),
          RatingBar.builder(
            initialRating: rating,
            minRating: 1,
            direction: Axis.horizontal,
            allowHalfRating: true,
            itemCount: 5,
            itemSize: 20,
            itemPadding: const EdgeInsets.symmetric(horizontal: 1.0),
            itemBuilder: (context, _) => const Icon(
              Icons.star,
              color: Colors.amber,
            ),
            onRatingUpdate: onRatingUpdate,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final criteria = _getCriteriaForType();

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text('Write ${widget.reviewType.name.toUpperCase()} Review'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Overall Rating
            Text(
              'Overall Rating',
              style: AppTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Center(
              child: RatingBar.builder(
                initialRating: _overallRating,
                minRating: 1,
                direction: Axis.horizontal,
                allowHalfRating: true,
                itemCount: 5,
                itemSize: 40,
                itemPadding: const EdgeInsets.symmetric(horizontal: 4.0),
                itemBuilder: (context, _) => const Icon(
                  Icons.star,
                  color: Colors.amber,
                ),
                onRatingUpdate: (rating) {
                  setState(() {
                    _overallRating = rating;
                  });
                },
              ),
            ),
            const SizedBox(height: 24),

            // Detailed Criteria
            if (criteria.length > 1) ...[
              Text(
                'Detailed Ratings',
                style: AppTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      if (widget.reviewType == ReviewType.guide) ...[
                        _buildCriteriaRating('Communication', _communicationRating,
                            (rating) => setState(() => _communicationRating = rating)),
                        _buildCriteriaRating('Local Knowledge', _knowledgeRating,
                            (rating) => setState(() => _knowledgeRating = rating)),
                        _buildCriteriaRating('Punctuality', _punctualityRating,
                            (rating) => setState(() => _punctualityRating = rating)),
                        _buildCriteriaRating('Professionalism', _valueRating,
                            (rating) => setState(() => _valueRating = rating)),
                      ] else if (widget.reviewType == ReviewType.tour) ...[
                        _buildCriteriaRating('Value for Money', _valueRating,
                            (rating) => setState(() => _valueRating = rating)),
                        _buildCriteriaRating('Safety', _safetyRating,
                            (rating) => setState(() => _safetyRating = rating)),
                      ] else ...[
                        _buildCriteriaRating('Booking Process', _communicationRating,
                            (rating) => setState(() => _communicationRating = rating)),
                        _buildCriteriaRating('Response Time', _punctualityRating,
                            (rating) => setState(() => _punctualityRating = rating)),
                        _buildCriteriaRating('Accuracy', _knowledgeRating,
                            (rating) => setState(() => _knowledgeRating = rating)),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Review Title
            Text(
              'Review Title',
              style: AppTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                hintText: 'Summarize your experience...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 16),

            // Review Content
            Text(
              'Your Review',
              style: AppTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _reviewController,
              decoration: InputDecoration(
                hintText: 'Share details of your experience...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              maxLines: 6,
            ),
            const SizedBox(height: 24),

            // Verification Badge
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.verified, color: Colors.green),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This review will be verified once your booking is confirmed.',
                      style: AppTheme.bodySmall.copyWith(color: Colors.green[700]),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Submit Button
            SizedBox(
              width: double.infinity,
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _overallRating > 0 ? _submitReview : null,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Submit Review',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _submitReview() async {
    if (_overallRating == 0 || _titleController.text.isEmpty || _reviewController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all required fields')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = _authService.getCurrentUser();
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please log in to submit a review')),
        );
        return;
      }

      final newReview = ReviewModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        type: widget.reviewType,
        targetId: widget.targetId,
        reviewerId: user.uid,
        reviewerName: 'Current User', // Would be populated from user profile
        overallRating: _overallRating,
        criteria: _getCriteriaForType(),
        title: _titleController.text,
        content: _reviewController.text,
        createdAt: DateTime.now(),
        status: ReviewStatus.pending, // Reviews need moderation
      );

      await _db.createReview(newReview);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Review submitted successfully! It will be published after moderation.')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to submit review: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
