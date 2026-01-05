import 'package:flutter/material.dart';
import '../../models/tour_guide_model.dart';
import '../../utils/app_theme.dart';

class TourGuideEditAccountScreen extends StatefulWidget {
  final TourGuideModel tourGuide;

  const TourGuideEditAccountScreen({
    super.key,
    required this.tourGuide,
  });

  @override
  State<TourGuideEditAccountScreen> createState() =>
      _TourGuideEditAccountScreenState();
}

class _TourGuideEditAccountScreenState
    extends State<TourGuideEditAccountScreen> {
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _experienceController;

  // Multi-select states
  late List<String> _selectedLanguages;
  late List<String> _selectedSpecializations;

  // Password change states
  late TextEditingController _currentPasswordController;
  late TextEditingController _newPasswordController;
  late TextEditingController _confirmPasswordController;
  bool _showPasswordSection = false;

  // Available options
  final List<String> _availableLanguages = [
    'English',
    'Tagalog',
    'Cebuano',
    'Ilocano',
    'Bicolano',
    'Waray',
    'Hiligaynon',
    'Kapampangan',
    'Pangasinense',
    'Chavacano'
  ];

  final List<String> _availableSpecializations = [
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
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.tourGuide.name);
    _emailController = TextEditingController(text: widget.tourGuide.email);
    _phoneController = TextEditingController(text: widget.tourGuide.phone);
    _experienceController =
        TextEditingController(text: widget.tourGuide.experience);

    _selectedLanguages = List.from(widget.tourGuide.languages);
    _selectedSpecializations = List.from(widget.tourGuide.specializations);

    _currentPasswordController = TextEditingController();
    _newPasswordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _experienceController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Edit Account'),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.primaryColor),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: () {
              // TODO: Implement save functionality
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Account updated successfully!'),
                  backgroundColor: AppTheme.successColor,
                ),
              );
            },
            child: const Text(
              'Save',
              style: TextStyle(
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Picture Section
            Center(
              child: Column(
                children: [
                  Stack(
                    children: [
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: AppTheme.primaryGradient,
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primaryColor.withOpacity(0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.person,
                          size: 60,
                          color: Colors.white,
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white,
                              width: 3,
                            ),
                          ),
                          child: IconButton(
                            onPressed: () {
                              // TODO: Implement image picker
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                      'Profile picture update coming soon!'),
                                ),
                              );
                            },
                            icon: const Icon(
                              Icons.camera_alt,
                              size: 20,
                              color: Colors.white,
                            ),
                            padding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Tap to change profile picture',
                    style: AppTheme.bodySmall.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Basic Information Section
            Text('Basic Information', style: AppTheme.headlineSmall),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _nameController,
              label: 'Full Name',
              icon: Icons.person,
              hintText: 'Enter your full name',
              readOnly: true,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _emailController,
              label: 'Email',
              icon: Icons.email,
              hintText: 'Enter your email',
              keyboardType: TextInputType.emailAddress,
              readOnly: true,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _phoneController,
              label: 'Phone',
              icon: Icons.phone,
              hintText: 'Enter your phone number',
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _experienceController,
              label: 'Experience',
              icon: Icons.work,
              hintText: 'e.g., 5 years',
            ),
            const SizedBox(height: 32),

            // Languages Section
            Text('Languages', style: AppTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(
              'Select all languages you speak',
              style: AppTheme.bodySmall.copyWith(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 16),
            _buildMultiSelectChips(
              items: _availableLanguages,
              selectedItems: _selectedLanguages,
              onSelectionChanged: (selected) {
                setState(() {
                  _selectedLanguages = selected;
                });
              },
            ),
            const SizedBox(height: 32),

            // Specializations Section
            Text('Specializations', style: AppTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(
              'Select your areas of expertise',
              style: AppTheme.bodySmall.copyWith(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 16),
            _buildMultiSelectChips(
              items: _availableSpecializations,
              selectedItems: _selectedSpecializations,
              onSelectionChanged: (selected) {
                setState(() {
                  _selectedSpecializations = selected;
                });
              },
            ),
            const SizedBox(height: 32),

            // Change Password Section
            Container(
              decoration: AppTheme.cardDecoration,
              child: Column(
                children: [
                  ListTile(
                    onTap: () {
                      setState(() {
                        _showPasswordSection = !_showPasswordSection;
                      });
                    },
                    title:
                        Text('Change Password', style: AppTheme.headlineSmall),
                    trailing: Icon(
                      _showPasswordSection
                          ? Icons.expand_less
                          : Icons.expand_more,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  if (_showPasswordSection) ...[
                    const Divider(height: 1),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          _buildPasswordField(
                            controller: _currentPasswordController,
                            label: 'Current Password',
                            hintText: 'Enter current password',
                          ),
                          const SizedBox(height: 16),
                          _buildPasswordField(
                            controller: _newPasswordController,
                            label: 'New Password',
                            hintText: 'Enter new password',
                          ),
                          const SizedBox(height: 16),
                          _buildPasswordField(
                            controller: _confirmPasswordController,
                            label: 'Confirm New Password',
                            hintText: 'Confirm new password',
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () {
                                // TODO: Implement password change
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content:
                                        Text('Password updated successfully!'),
                                    backgroundColor: AppTheme.successColor,
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryColor,
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text('Update Password'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Save Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // TODO: Implement save functionality
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Account updated successfully!'),
                      backgroundColor: AppTheme.successColor,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Save Changes'),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String hintText,
    TextInputType? keyboardType,
    bool readOnly = false,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      readOnly: readOnly,
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        prefixIcon: Icon(icon, color: AppTheme.primaryColor),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppTheme.dividerColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2),
        ),
        filled: readOnly,
        fillColor: readOnly ? AppTheme.dividerColor.withOpacity(0.1) : null,
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required String hintText,
  }) {
    return TextField(
      controller: controller,
      obscureText: true,
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        prefixIcon: const Icon(Icons.lock, color: AppTheme.primaryColor),
        suffixIcon:
            const Icon(Icons.visibility_off, color: AppTheme.textSecondary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppTheme.dividerColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2),
        ),
      ),
    );
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
          backgroundColor: AppTheme.backgroundColor,
          selectedColor: AppTheme.primaryColor.withOpacity(0.1),
          checkmarkColor: AppTheme.primaryColor,
          labelStyle: TextStyle(
            color: isSelected ? AppTheme.primaryColor : AppTheme.textSecondary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: isSelected ? AppTheme.primaryColor : AppTheme.dividerColor,
              width: 1,
            ),
          ),
        );
      }).toList(),
    );
  }
}
