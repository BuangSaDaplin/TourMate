import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../utils/app_theme.dart';
import '../../services/itinerary_generator_service.dart';
import '../../services/itinerary_service.dart';
import '../../services/auth_service.dart';
import '../../data/tour_spot_model.dart';
import '../../data/mock_tour_spot_repository.dart';
import '../../models/itinerary_model.dart';

class AutoItineraryGeneratorScreen extends StatefulWidget {
  const AutoItineraryGeneratorScreen({super.key});

  @override
  State<AutoItineraryGeneratorScreen> createState() =>
      _AutoItineraryGeneratorScreenState();
}

class _AutoItineraryGeneratorScreenState
    extends State<AutoItineraryGeneratorScreen> {
  final ItineraryGeneratorService _generatorService =
      ItineraryGeneratorService();
  final ItineraryService _itineraryService = ItineraryService();
  final AuthService _authService = AuthService();

  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  DateTime _startDate = DateTime.now();
  TimeOfDay _startTime = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 17, minute: 0);
  double? _budget;
  final List<String> _selectedInterests = [];
  String _pace = 'moderate';

  bool _isGenerating = false;
  ItineraryModel? _generatedItinerary;

  final List<String> _availableInterests = [
    'Religious',
    'Historical',
    'Natural',
    'Beach',
    'Culture',
    'Adventure',
    'Food',
    'Shopping',
    'Viewpoint',
    'Entertainment'
  ];

  final List<String> _paceOptions = ['relaxed', 'moderate', 'packed'];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _startDate = picked;
      });
    }
  }

  Future<void> _selectStartTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _startTime,
    );
    if (picked != null) {
      setState(() {
        _startTime = picked;
      });
    }
  }

  Future<void> _selectEndTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _endTime,
    );
    if (picked != null) {
      setState(() {
        _endTime = picked;
      });
    }
  }

  Future<void> _generateItinerary() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isGenerating = true;
    });

    try {
      final user = _authService.getCurrentUser();
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Please log in to generate itineraries')),
        );
        return;
      }

      // Combine date and time
      final startDateTime = DateTime(
        _startDate.year,
        _startDate.month,
        _startDate.day,
        _startTime.hour,
        _startTime.minute,
      );

      final endDateTime = DateTime(
        _startDate.year,
        _startDate.month,
        _startDate.day,
        _endTime.hour,
        _endTime.minute,
      );

      // Initialize user context
      final userContext = _generatorService.initializeUserContext(
        startTime: startDateTime,
        endTime: endDateTime,
        budget: _budget,
        interests: _selectedInterests,
        pace: _pace,
      );

      // Get available tour spots (using mock repository)
      final repository = MockTourSpotRepository();
      final availableSpots = await repository.getAllSpots();

      // Generate itinerary
      final itinerary = await _generatorService.generateItinerary(
        availableSpots: availableSpots,
        context: userContext,
        userId: user.uid,
        title: _titleController.text.isNotEmpty ? _titleController.text : null,
        description: _descriptionController.text.isNotEmpty
            ? _descriptionController.text
            : null,
      );

      setState(() {
        _generatedItinerary = itinerary;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Itinerary generated successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to generate itinerary: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isGenerating = false;
      });
    }
  }

  Future<void> _saveItinerary() async {
    if (_generatedItinerary == null) return;

    try {
      await _itineraryService.createItinerary(_generatedItinerary!);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Itinerary saved successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save itinerary: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Auto Itinerary Generator'),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.primaryColor,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title and Description
              Text(
                'Itinerary Details',
                style: AppTheme.headlineSmall,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Itinerary Title (Optional)',
                  hintText: 'e.g., Cebu City Exploration',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Description (Optional)',
                  hintText: 'Brief description of your itinerary...',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),

              // Date and Time
              Text(
                'Schedule',
                style: AppTheme.headlineSmall,
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: _selectStartDate,
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Date',
                          border: OutlineInputBorder(),
                        ),
                        child:
                            Text(DateFormat('MMM dd, yyyy').format(_startDate)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: _selectStartTime,
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Start Time',
                          border: OutlineInputBorder(),
                        ),
                        child: Text(_startTime.format(context)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: InkWell(
                      onTap: _selectEndTime,
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'End Time',
                          border: OutlineInputBorder(),
                        ),
                        child: Text(_endTime.format(context)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Preferences
              Text(
                'Preferences',
                style: AppTheme.headlineSmall,
              ),
              const SizedBox(height: 16),

              // Budget
              TextFormField(
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Budget per person (Optional)',
                  hintText: '2500',
                  prefixText: '₱',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  _budget = double.tryParse(value);
                },
              ),
              const SizedBox(height: 16),

              // Interests
              Text(
                'Interests',
                style: AppTheme.bodyLarge.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _availableInterests.map((interest) {
                  final isSelected = _selectedInterests.contains(interest);
                  return FilterChip(
                    label: Text(interest),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedInterests.add(interest);
                        } else {
                          _selectedInterests.remove(interest);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // Pace
              Text(
                'Pace',
                style: AppTheme.bodyLarge.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _paceOptions.map((pace) {
                  return ChoiceChip(
                    label: Text(pace.capitalize()),
                    selected: _pace == pace,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _pace = pace;
                        });
                      }
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 32),

              // Generate Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isGenerating ? null : _generateItinerary,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isGenerating
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Generate Itinerary',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                ),
              ),

              // Generated Itinerary Display
              if (_generatedItinerary != null) ...[
                const SizedBox(height: 32),
                Text(
                  'Generated Itinerary',
                  style: AppTheme.headlineSmall,
                ),
                const SizedBox(height: 16),
                _buildItineraryPreview(),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _generateItinerary,
                        child: const Text('Regenerate'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _saveItinerary,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.successColor,
                        ),
                        child: const Text('Save Itinerary'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(context, _generatedItinerary);
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppTheme.primaryColor),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Use for Tour Creation',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildItineraryPreview() {
    if (_generatedItinerary == null) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _generatedItinerary!.title,
              style: AppTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              _generatedItinerary!.description,
              style: AppTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            Text(
              'Activities (${_generatedItinerary!.items.length})',
              style: AppTheme.bodyLarge.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            ..._generatedItinerary!.items.map((item) {
              final metadata = item.metadata;
              final travelTime = metadata?['travelTimeToNext'] ?? 0;
              final travelDistance = metadata?['travelDistanceToNext'] ?? 0.0;

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 60,
                      padding: const EdgeInsets.symmetric(
                          vertical: 4, horizontal: 8),
                      decoration: BoxDecoration(
                        color: item.typeColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        DateFormat('HH:mm').format(item.startTime),
                        style: AppTheme.bodySmall.copyWith(
                          fontWeight: FontWeight.w600,
                          color: item.typeColor,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.title,
                            style: AppTheme.bodyLarge
                                .copyWith(fontWeight: FontWeight.w600),
                          ),
                          Text(
                            item.description,
                            style: AppTheme.bodyMedium,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (travelTime > 0) ...[
                            const SizedBox(height: 4),
                            Text(
                              'Travel: ${travelTime}min (${travelDistance.toStringAsFixed(1)}km)',
                              style: AppTheme.bodySmall
                                  .copyWith(color: AppTheme.textSecondary),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}
