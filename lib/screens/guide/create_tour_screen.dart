import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import '../../utils/app_theme.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../../models/tour_model.dart';

class CreateTourScreen extends StatefulWidget {
  const CreateTourScreen({super.key});

  @override
  State<CreateTourScreen> createState() => _CreateTourScreenState();
}

class _CreateTourScreenState extends State<CreateTourScreen> {
  final AuthService _authService = AuthService();
  final DatabaseService _db = DatabaseService();
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _priceController = TextEditingController();
  final _durationController = TextEditingController();
  final _maxParticipantsController = TextEditingController();

  List<PlatformFile> _previewImages = [];

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
    _locationController.dispose();
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
              // Tour Title
              Text(
                'Tour Details',
                style: AppTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
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

              // Location
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(
                  labelText: 'Location',
                  hintText: 'e.g., Badian, Cebu',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a location';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Tour Settings
              Text(
                'Tour Settings',
                style: AppTheme.headlineSmall,
              ),
              const SizedBox(height: 16),

              // Price and Duration Row
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
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
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _durationController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      decoration: const InputDecoration(
                        labelText: 'Duration (hours)',
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
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Max Participants
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

              // Category
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
              const SizedBox(height: 24),

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
              const SizedBox(height: 24),

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
              const SizedBox(height: 32),

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

  void _saveTour() async {
    if (_formKey.currentState!.validate() && _selectedCategories.isNotEmpty) {
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

        final newTour = TourModel(
          id: tourId,
          title: _titleController.text,
          description: _descriptionController.text,
          price: double.parse(_priceController.text),
          category: _selectedCategories,
          maxParticipants: int.parse(_maxParticipantsController.text),
          currentParticipants: 0,
          startTime: DateTime.now(),
          endTime: DateTime.now(),
          meetingPoint: _locationController.text,
          mediaURL: mediaURLs,
          createdBy: user.uid,
          shared: false,
          itinerary: [],
          status: 'pending',
          duration: duration,
          languages: _selectedLanguages,
          specializations: _selectedSpecializations,
          highlights: [],
        );
        await _db.createTour(newTour);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tour suggested successfully!'),
            backgroundColor: AppTheme.successColor,
          ),
        );
        Navigator.pop(context);
      }
    } else if (_selectedCategories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one category'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
