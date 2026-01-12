import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import '../../utils/app_theme.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../../services/itinerary_generator_service.dart';
import '../../data/mock_tour_spot_repository.dart';
import '../../data/tour_spot_model.dart';
import '../../models/tour_model.dart';
import '../../models/itinerary_model.dart';

class CreateTourScreen extends StatefulWidget {
  const CreateTourScreen({super.key});

  @override
  State<CreateTourScreen> createState() => _CreateTourScreenState();
}

class _CreateTourScreenState extends State<CreateTourScreen> {
  final AuthService _authService = AuthService();
  final DatabaseService _db = DatabaseService();
  final ItineraryGeneratorService _itineraryGeneratorService =
      ItineraryGeneratorService();
  final MockTourSpotRepository _tourSpotRepository = MockTourSpotRepository();
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _durationController = TextEditingController();
  final _maxParticipantsController = TextEditingController();
  DateTime _tourDate = DateTime.now(); // Automatically set to current date
  DateTime? _tourStartTime;
  int? _tourDuration; // Duration in hours
  ItineraryModel? _generatedItinerary;

  List<String> _selectedSpots = [];
  final List<String> _cebuCitySpots = [
    'Basilica del Santo Niño',
    'Magellan\'s Cross',
    'Fort San Pedro',
    'Colon Street',
    'Cebu Metropolitan Cathedral',
    'Heritage of Cebu Monument',
    'Cebu Taoist Temple',
    'Sirao Flower Garden',
    'Temple of Leah',
    'Tops Lookout',
    'Mountain Peak Viewpoint',
  ];

  final List<PlatformFile> _previewImages = [];

  List<String> _selectedCategories = [];
  final List<String> _categories = [
    'Adventure',
    'Culture',
    'Food',
    'Nature',
    'Beach',
    'City Tour',
    'Historical',
    'Religious'
  ];

  final List<String> _selectedLanguages = [];
  final List<String> _availableLanguages = [
    'English',
    'Cebuano',
    'Tagalog',
    'Japanese',
    'Korean',
    'Chinese'
  ];

  final List<String> _selectedSpecializations = [];
  final List<String> _availableSpecializations = [
    'Hiking',
    'Snorkeling',
    'Photography',
    'History',
    'Local Culture',
    'Wildlife',
    'Food & Dining',
    'Transportation'
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _durationController.dispose();
    _maxParticipantsController.dispose();
    super.dispose();
  }

  Future<void> _pickPreviewImages() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png'],
      allowMultiple: true,
      withData: true,
    );

    if (result != null && result.files.isNotEmpty) {
      for (final file in result.files) {
        // Validate file size (max 5MB)
        if (file.size > 5 * 1024 * 1024) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content:
                    Text('File size too large. Please select files under 5MB.'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }
      }

      setState(() {
        _previewImages.addAll(result.files);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Suggest New Tour'),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.primaryColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Basic Tour Information (Identity Layer)
              Text(
                'Basic Tour Information',
                style: AppTheme.headlineSmall,
              ),
              const SizedBox(height: 16),

              // Tour Title
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Tour Title',
                  hintText: 'e.g., Kawasan Falls Canyoneering Adventure',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a tour title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Description
              TextFormField(
                controller: _descriptionController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'Describe your tour experience...',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a description';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Tour Type / Category (optional)
              Text(
                'Category',
                style: AppTheme.bodyLarge.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _categories.map((category) {
                  final isSelected = _selectedCategories.contains(category);
                  return FilterChip(
                    label: Text(category),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedCategories.add(category);
                        } else {
                          _selectedCategories.remove(category);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // Maximum Number of Participants (optional)
              TextFormField(
                controller: _maxParticipantsController,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
                decoration: const InputDecoration(
                  labelText: 'Max Participants',
                  hintText: '10',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Enter max participants';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // 2. Tour Date Selection (Temporal Anchor)
              Text(
                'Tour Date',
                style: AppTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _tourDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (picked != null) {
                    setState(() {
                      _tourDate = picked;
                    });
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppTheme.dividerColor),
                    borderRadius: BorderRadius.circular(8),
                    color: AppTheme.backgroundColor,
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today, color: AppTheme.primaryColor),
                      const SizedBox(width: 12),
                      Text(
                        'Tour Date: ${_tourDate.day}/${_tourDate.month}/${_tourDate.year}',
                        style: AppTheme.bodyLarge.copyWith(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      Icon(Icons.arrow_drop_down, color: AppTheme.primaryColor),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // 3. Tour Time Configuration (Time Constraints)
              Text(
                'Tour Time Configuration',
                style: AppTheme.headlineSmall,
              ),
              const SizedBox(height: 16),

              // Tour Start Time
              InkWell(
                onTap: () async {
                  final picked = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.now(),
                  );
                  if (picked != null) {
                    setState(() {
                      _tourStartTime = DateTime(
                        _tourDate.year,
                        _tourDate.month,
                        _tourDate.day,
                        picked.hour,
                        picked.minute,
                      );
                    });
                  }
                },
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Tour Start Time',
                    border: OutlineInputBorder(),
                  ),
                  child: Text(
                    _tourStartTime != null
                        ? '${_tourStartTime!.hour.toString().padLeft(2, '0')}:${_tourStartTime!.minute.toString().padLeft(2, '0')}'
                        : 'Select start time',
                    style: TextStyle(
                      color: _tourStartTime != null
                          ? AppTheme.textPrimary
                          : AppTheme.textSecondary,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Tour Duration
              TextFormField(
                controller: _durationController,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
                decoration: const InputDecoration(
                  labelText: 'Tour Duration (hours)',
                  hintText: '8',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Enter duration';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // 4. Tour Location Selection (Spatial Data)
              Text(
                'Tour Location Selection',
                style: AppTheme.headlineSmall,
              ),
              const SizedBox(height: 16),

              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Locations (Select 1-3)',
                    style: AppTheme.bodyLarge.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppTheme.dividerColor),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_selectedSpots.isEmpty)
                          Text(
                            'No locations selected',
                            style: AppTheme.bodySmall.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                          )
                        else
                          Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            children: _selectedSpots.map((spot) {
                              return Chip(
                                label: Text(spot),
                                onDeleted: () {
                                  setState(() {
                                    _selectedSpots.remove(spot);
                                    _updateCategoriesBasedOnSpots();
                                  });
                                },
                              );
                            }).toList(),
                          ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _selectLocations,
                                icon: const Icon(Icons.add),
                                label: const Text('Select Locations'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppTheme.primaryColor,
                                  side: const BorderSide(
                                      color: AppTheme.primaryColor),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            SizedBox(
                              width: 120,
                              child: OutlinedButton.icon(
                                onPressed: _selectedSpots.isNotEmpty
                                    ? _autoGenerateTour
                                    : null,
                                icon: const Icon(Icons.auto_awesome),
                                label: const Text('Auto\nGenerate'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: _selectedSpots.isNotEmpty
                                      ? AppTheme.primaryColor
                                      : AppTheme.textSecondary,
                                  side: BorderSide(
                                      color: _selectedSpots.isNotEmpty
                                          ? AppTheme.primaryColor
                                          : AppTheme.textSecondary),
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Additional Tour Settings (Price, Languages, Specializations)
              Text(
                'Additional Tour Settings',
                style: AppTheme.headlineSmall,
              ),
              const SizedBox(height: 16),

              // Price
              TextFormField(
                controller: _priceController,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
                decoration: const InputDecoration(
                  labelText: 'Price per person',
                  hintText: '2500',
                  prefixText: '₱',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Enter price';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Languages
              Text(
                'Languages',
                style: AppTheme.bodyLarge.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _availableLanguages.map((language) {
                  final isSelected = _selectedLanguages.contains(language);
                  return FilterChip(
                    label: Text(language),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedLanguages.add(language);
                        } else {
                          _selectedLanguages.remove(language);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // Specializations
              Text(
                'Specializations',
                style: AppTheme.bodyLarge.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _availableSpecializations.map((spec) {
                  final isSelected = _selectedSpecializations.contains(spec);
                  return FilterChip(
                    label: Text(spec),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedSpecializations.add(spec);
                        } else {
                          _selectedSpecializations.remove(spec);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              // Tour Preview Image Upload
              Text(
                'Tour Preview Images',
                style: AppTheme.bodyLarge.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: AppTheme.dividerColor,
                    width: 2,
                    style: BorderStyle.solid,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  color: AppTheme.backgroundColor,
                ),
                child: Column(
                  children: [
                    if (_previewImages.isEmpty)
                      Container(
                        height: 200,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.cloud_upload_outlined,
                              size: 48,
                              color: AppTheme.primaryColor,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Upload Tour Preview Images',
                              style: AppTheme.bodyLarge.copyWith(
                                color: AppTheme.primaryColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Choose images that showcase your tour (JPG, PNG, max 5MB each)',
                              style: AppTheme.bodySmall.copyWith(
                                color: AppTheme.textSecondary,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 12),
                            OutlinedButton.icon(
                              onPressed: _pickPreviewImages,
                              icon: const Icon(Icons.photo_library),
                              label: const Text('Choose Images'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppTheme.primaryColor,
                                side: const BorderSide(
                                    color: AppTheme.primaryColor),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      Column(
                        children: [
                          Container(
                            height: 120,
                            padding: const EdgeInsets.all(16),
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: _previewImages.length,
                              itemBuilder: (context, index) {
                                final file = _previewImages[index];
                                return Container(
                                  width: 100,
                                  margin: const EdgeInsets.only(right: 8),
                                  child: Stack(
                                    children: [
                                      Container(
                                        width: 100,
                                        height: 100,
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          image: DecorationImage(
                                            image: kIsWeb
                                                ? MemoryImage(file.bytes!)
                                                : FileImage(File(file.path!))
                                                    as ImageProvider,
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                        top: 4,
                                        right: 4,
                                        child: GestureDetector(
                                          onTap: () {
                                            setState(() {
                                              _previewImages.removeAt(index);
                                            });
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.all(4),
                                            decoration: BoxDecoration(
                                              color:
                                                  Colors.black.withOpacity(0.6),
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                              Icons.close,
                                              color: Colors.white,
                                              size: 16,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                          const Divider(height: 1),
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    '${_previewImages.length} image${_previewImages.length == 1 ? '' : 's'} selected',
                                    style: AppTheme.bodySmall.copyWith(
                                      color: AppTheme.textSecondary,
                                    ),
                                  ),
                                ),
                                OutlinedButton.icon(
                                  onPressed: _pickPreviewImages,
                                  icon: const Icon(Icons.add),
                                  label: const Text('Add More'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppTheme.primaryColor,
                                    side: const BorderSide(
                                        color: AppTheme.primaryColor),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Itinerary Preview
              if (_generatedItinerary != null) ...[
                Text(
                  'Generated Itinerary Preview',
                  style: AppTheme.bodyLarge.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppTheme.dividerColor),
                    borderRadius: BorderRadius.circular(8),
                    color: AppTheme.backgroundColor,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _generatedItinerary!.title,
                        style: AppTheme.headlineSmall.copyWith(
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _generatedItinerary!.description,
                        style: AppTheme.bodyMedium,
                      ),
                      const SizedBox(height: 16),
                      ..._generatedItinerary!.items.map((item) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border: Border.all(color: AppTheme.dividerColor),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.location_on,
                                    size: 16,
                                    color: AppTheme.primaryColor,
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      item.title,
                                      style: AppTheme.bodyLarge.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                item.description,
                                style: AppTheme.bodySmall,
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(
                                    Icons.access_time,
                                    size: 14,
                                    color: AppTheme.textSecondary,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    item.startTime != null
                                        ? '${item.startTime!.hour.toString().padLeft(2, '0')}:${item.startTime!.minute.toString().padLeft(2, '0')} - ${item.endTime?.hour.toString().padLeft(2, '0')}:${item.endTime?.minute.toString().padLeft(2, '0')}'
                                        : 'Time TBD',
                                    style: AppTheme.bodySmall.copyWith(
                                      color: AppTheme.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              const SizedBox(height: 16),

              // Save Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _saveTour,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Suggest Tour',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _autoGenerateTour() async {
    if (_selectedSpots.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one location first'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Set default times if not set
    final startTime = _tourStartTime ??
        DateTime(_tourDate.year, _tourDate.month, _tourDate.day, 8, 0);
    final durationHours = int.tryParse(_durationController.text) ?? 8;
    final endTime = startTime.add(Duration(hours: durationHours));

    // 1. Resolve your selected strings to actual TourSpot objects first
    final List<TourSpot> selectedSpotObjects = await _tourSpotRepository
        .getAllSpots()
        .then((allSpots) => allSpots
            .where((spot) => _selectedSpots.contains(spot.name))
            .toList());

    // 2. Generate the itinerary
    final userContext = _itineraryGeneratorService.initializeUserContext(
      startTime: startTime,
      endTime: endTime,
      interests: [], // PASS EMPTY LIST to stop the service from filtering out your picks!
      pace: 'packed', // Use 'packed' to reduce the "buffer" time between spots
    );

    final user = _authService.getCurrentUser();
    if (user != null) {
      try {
        final result = await _itineraryGeneratorService.generateItinerary(
          availableSpots: selectedSpotObjects,
          context: userContext,
          userId: user.uid,
          title: _titleController.text.isNotEmpty
              ? _titleController.text
              : 'Auto-Generated Tour',
          description: _descriptionController.text.isNotEmpty
              ? _descriptionController.text
              : 'Explore selected locations',
        );

        setState(() {
          _generatedItinerary = result;
        });

        // Auto-populate form fields based on selected locations and generated itinerary
        setState(() {
          // Generate title based on locations
          if (_selectedSpots.length == 1) {
            _titleController.text = '${_selectedSpots.first} Tour';
          } else {
            _titleController.text = 'Cebu City Multi-Location Tour';
          }

          // Generate description
          _descriptionController.text =
              'Explore ${_selectedSpots.join(", ")} in this comprehensive tour of Cebu City.';

          // Set times
          _tourStartTime = startTime;

          // Estimate duration based on number of locations
          final estimatedHours =
              _selectedSpots.length * 2; // 2 hours per location
          _durationController.text = estimatedHours.toString();

          // Set max participants
          _maxParticipantsController.text = '10';

          // Set default price
          _priceController.text = '2500';

          // Auto-select relevant categories based on locations
          _selectedCategories = ['City Tour', 'Historical'];
          if (_selectedSpots.any(
              (spot) => spot.contains('Beach') || spot.contains('Mountain'))) {
            _selectedCategories.add('Nature');
          }
          if (_selectedSpots.any(
              (spot) => spot.contains('Temple') || spot.contains('Church'))) {
            _selectedCategories.add('Religious');
          }
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content:
                  Text('Tour form auto-populated with generated itinerary!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to generate itinerary: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _updateCategoriesBasedOnSpots() {
    final Set<String> newCategories = {'City Tour'}; // Default category

    for (final spot in _selectedSpots) {
      if (spot.contains('Basilica') ||
          spot.contains('Cathedral') ||
          spot.contains('Temple') ||
          spot.contains('Church') ||
          spot.contains('Cross')) {
        newCategories.add('Religious');
      }
      if (spot.contains('Fort') ||
          spot.contains('Heritage') ||
          spot.contains('Monument') ||
          spot.contains('Cross')) {
        newCategories.add('Historical');
      }
      if (spot.contains('Flower Garden') ||
          spot.contains('Lookout') ||
          spot.contains('Mountain') ||
          spot.contains('Peak')) {
        newCategories.add('Nature');
      }
      if (spot.contains('Colon Street')) {
        newCategories.add('Culture');
      }
    }

    setState(() {
      _selectedCategories = newCategories.toList();
    });
  }

  Future<List<TourSpot>> _mapSelectedSpotsToTourSpots() async {
    final allSpots = await _tourSpotRepository.getAllSpots();
    return allSpots
        .where((spot) => _selectedSpots.contains(spot.name))
        .toList();
  }

  void _selectLocations() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        List<String> tempSelected = List.from(_selectedSpots);
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Select Locations (1-3)'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: _cebuCitySpots.map((spot) {
                    return CheckboxListTile(
                      title: Text(spot),
                      value: tempSelected.contains(spot),
                      onChanged: (bool? value) {
                        setState(() {
                          if (value == true) {
                            if (tempSelected.length < 3) {
                              tempSelected.add(spot);
                            }
                          } else {
                            tempSelected.remove(spot);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: tempSelected.isNotEmpty
                      ? () {
                          this.setState(() {
                            _selectedSpots = tempSelected;
                            _updateCategoriesBasedOnSpots();
                          });
                          Navigator.pop(context);
                        }
                      : null,
                  child: const Text('Select'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _saveTour() async {
    if (_formKey.currentState!.validate() &&
        _selectedCategories.isNotEmpty &&
        _selectedSpots.isNotEmpty) {
      final user = _authService.getCurrentUser();
      if (user != null) {
        final durationText = _durationController.text.trim();
        final duration = int.tryParse(durationText);
        if (duration == null || duration <= 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please enter a valid duration greater than 0'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }

        // Generate tour ID once
        final tourId = DateTime.now().millisecondsSinceEpoch.toString();

        // Show loading indicator
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Uploading images...'),
              duration: Duration(seconds: 2),
            ),
          );
        }

        List<String> mediaURLs = [];
        try {
          // Upload each image and collect download URLs
          for (final file in _previewImages) {
            final downloadURL = await _db.uploadTourMedia(
              tourId,
              file,
            );
            mediaURLs.add(downloadURL);
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to upload images: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }

        // Map selected spots to TourSpot objects
        final tourSpots = await _mapSelectedSpotsToTourSpots();

        // Set default times if not set
        final startTime = _tourStartTime ??
            DateTime(_tourDate.year, _tourDate.month, _tourDate.day, 8, 0);
        final endTime = startTime.add(Duration(hours: duration));

        // Create user context for itinerary generation
        final userContext = UserContext(
          startTime: startTime,
          endTime: endTime,
          budget: double.parse(_priceController.text),
          interests: [], // PASS EMPTY LIST to stop the service from filtering out your picks!
          pace: 'packed',
        );

        // Generate optimized itinerary
        try {
          print('DEBUG: Generating itinerary with ${tourSpots.length} spots');
          print('DEBUG: Selected categories: $_selectedCategories');
          print('DEBUG: Start time: $startTime, End time: $endTime');

          final generatedItinerary =
              await _itineraryGeneratorService.generateItinerary(
            availableSpots: tourSpots,
            context: userContext,
            userId: user.uid,
            title: _titleController.text,
            description: _descriptionController.text,
          );

          print(
              'DEBUG: Generated itinerary has ${generatedItinerary.items.length} items');

          // Store the generated itinerary for preview
          setState(() {
            _generatedItinerary = generatedItinerary;
          });

          print("Generated Items: ${_generatedItinerary?.items.length}");
        } catch (e) {
          print('DEBUG: Itinerary generation failed: $e');
          // Fallback: set _generatedItinerary to null or handle accordingly
          setState(() {
            _generatedItinerary = null;
          });
        }

        // 1. Create the list of maps from your generated itinerary
        List<Map<String, String>> itineraryData = [];

        if (_generatedItinerary != null) {
          itineraryData = _generatedItinerary!.items.map((item) {
            return {
              'time':
                  "${item.startTime.hour.toString().padLeft(2, '0')}:${item.startTime.minute.toString().padLeft(2, '0')}",
              'activity': item.title,
              'location': item.location ?? 'Cebu City',
            };
          }).toList();
        }

        // 2. Pass this list into the TourModel
        final newTour = TourModel(
          id: tourId,
          title: _titleController.text,
          description: _descriptionController.text,
          price: double.parse(_priceController.text),
          category: _selectedCategories,
          maxParticipants: int.parse(_maxParticipantsController.text),
          currentParticipants: 0,
          startTime: startTime,
          endTime: endTime,
          meetingPoint:
              _selectedSpots.first, // Use first selected spot as meeting point
          mediaURL: mediaURLs,
          createdBy: user.uid,
          shared: false,
          itinerary: itineraryData, // This is the mapped list of 3 items
          status: 'pending',
          duration: duration,
          languages: _selectedLanguages,
          specializations: _selectedSpecializations,
          highlights: _selectedSpots,
        );

        print('DEBUG: Final itinerary has ${itineraryData.length} items');
        await _db.createTour(newTour);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tour suggested successfully!'),
            backgroundColor: AppTheme.successColor,
          ),
        );
        Navigator.pop(context);
      }
    } else {
      if (_selectedCategories.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select at least one category'),
            backgroundColor: Colors.red,
          ),
        );
      }
      if (_selectedSpots.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select at least one location'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
