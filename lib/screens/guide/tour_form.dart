import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tourmate_app/services/auth_service.dart';
import 'package:tourmate_app/services/database_service.dart';
import 'package:tourmate_app/models/tour_model.dart';

class TourForm extends StatefulWidget {
  const TourForm({super.key});

  @override
  State<TourForm> createState() => _TourFormState();
}

class _TourFormState extends State<TourForm> {
  final AuthService _authService = AuthService();
  final DatabaseService _db = DatabaseService();
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _maxParticipantsController = TextEditingController();
  final _scheduleController = TextEditingController();
  final _meetingPointController = TextEditingController();
  List<String> _selectedCategories = [];
  List<XFile> _images = [];
  bool _isShared = false;
  bool _isLoading = false;

  final List<String> _availableCategories = [
    'Adventure',
    'Culture',
    'Nature',
    'History',
    'Food',
    'Shopping',
    'Photography',
    'Hiking',
    'Beach',
    'City Tour',
    'Religious',
    'Eco-tourism',
    'Medical Tourism',
    'Educational'
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _maxParticipantsController.dispose();
    _scheduleController.dispose();
    _meetingPointController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final ImagePicker picker = ImagePicker();
    final List<XFile> images = await picker.pickMultiImage();
    setState(() {
      _images = images;
    });
  }

  Widget _buildMultiSelectChips({
    required List<String> items,
    required List<String> selectedItems,
    required Function(List<String>) onSelectionChanged,
  }) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: items.map((item) {
        final isSelected = selectedItems.contains(item);
        return FilterChip(
          label: Text(item),
          selected: isSelected,
          onSelected: (selected) {
            final newSelection = List<String>.from(selectedItems);
            if (selected) {
              newSelection.add(item);
            } else {
              newSelection.remove(item);
            }
            onSelectionChanged(newSelection);
          },
          backgroundColor: Theme.of(context).colorScheme.surface,
          selectedColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
          checkmarkColor: Theme.of(context).colorScheme.primary,
          labelStyle: TextStyle(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.onSurface,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.outline,
              width: 1,
            ),
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Suggest Tour'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Title'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a description';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(labelText: 'Price'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a price';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Text('Categories',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Text(
                'Select all categories that apply to your tour',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.color
                          ?.withOpacity(0.7),
                    ),
              ),
              const SizedBox(height: 16),
              _buildMultiSelectChips(
                items: _availableCategories,
                selectedItems: _selectedCategories,
                onSelectionChanged: (selected) {
                  setState(() {
                    _selectedCategories = selected;
                  });
                },
              ),
              TextFormField(
                controller: _maxParticipantsController,
                decoration:
                    const InputDecoration(labelText: 'Max Participants'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the max number of participants';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _scheduleController,
                decoration: const InputDecoration(labelText: 'Schedule'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a schedule';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _meetingPointController,
                decoration: const InputDecoration(labelText: 'Meeting Point'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a meeting point';
                  }
                  return null;
                },
              ),
              SwitchListTile(
                title: const Text('Shared Tour'),
                value: _isShared,
                onChanged: (value) {
                  setState(() {
                    _isShared = value;
                  });
                },
              ),
              ElevatedButton(
                onPressed: _pickImages,
                child: const Text('Upload Images'),
              ),
              if (_images.isNotEmpty)
                SizedBox(
                  height: 100,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _images.length,
                    itemBuilder: (context, index) {
                      return Image.file(
                        File(_images[index].path),
                        width: 100,
                        height: 100,
                      );
                    },
                  ),
                ),
              const SizedBox(height: 20),
              _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: () async {
                        if (_formKey.currentState!.validate() &&
                            _selectedCategories.isNotEmpty) {
                          setState(() {
                            _isLoading = true;
                          });
                          final user = _authService.getCurrentUser();
                          if (user != null) {
                            final imageUrls = <String>[];
                            for (final image in _images) {
                              final imageUrl = await _authService
                                  .uploadProfilePhoto(user.uid, image);
                              if (imageUrl != null) {
                                imageUrls.add(imageUrl);
                              }
                            }
                            final newTour = TourModel(
                              id: DateTime.now()
                                  .millisecondsSinceEpoch
                                  .toString(),
                              title: _titleController.text,
                              description: _descriptionController.text,
                              price: double.parse(_priceController.text),
                              category: _selectedCategories,
                              maxParticipants:
                                  int.parse(_maxParticipantsController.text),
                              currentParticipants: 0,
                              startTime: DateTime.now(),
                              endTime: DateTime.now(),
                              meetingPoint: _meetingPointController.text,
                              mediaURL: imageUrls,
                              createdBy: user.uid,
                              shared: _isShared,
                              itinerary: [],
                              status: 'published',
                              duration: '4',
                              languages: ['English'],
                              highlights: [],
                            );
                            await _db.createTour(newTour);
                          }
                          setState(() {
                            _isLoading = false;
                          });
                          Navigator.pop(context);
                        }
                      },
                      child: const Text('Suggest Tour'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
