import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../utils/app_theme.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../../services/user_profile_service.dart';
import '../../models/user_model.dart';
import 'package:flutter/foundation.dart';

class GuideEditAccountScreen extends StatefulWidget {
  const GuideEditAccountScreen({super.key});

  @override
  State<GuideEditAccountScreen> createState() => _GuideEditAccountScreenState();
}

class _GuideEditAccountScreenState extends State<GuideEditAccountScreen> {
  final AuthService _authService = AuthService();
  final DatabaseService _dbService = DatabaseService();
  final UserProfileService _profileService = UserProfileService();
  final ImagePicker _imagePicker = ImagePicker();

  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;

  // Multi-select states
  late List<String> _selectedLanguages;

  // Specializations multi-select
  late List<String> _selectedSpecializations;

  // Availability multi-select
  late List<String> _selectedAvailability;

  // Available specializations
  final List<String> _availableSpecializations = [
    'Basilica del Santo Niño',
    'Magellan\'s Cross',
    'Fort San Pedro',
    'Colon Street',
    'Cebu Metropolitan Cathedral',
    'Heritage of Cebu Monument',
    'Cebu Taoist Temple',
    'Sirao Flower Garden',
    'Temple of Leah',
    'Tops Lookout'
  ];

  final List<String> _availableAvailability = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  // Password change states
  late TextEditingController _currentPasswordController;
  late TextEditingController _newPasswordController;
  late TextEditingController _confirmPasswordController;
  bool _showPasswordSection = false;

  // Email update states
  late TextEditingController _emailPasswordController;
  bool _showEmailPasswordDialog = false;
  String? _originalEmail;

  // Loading states
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isChangingPassword = false;

  // User data
  UserModel? _currentUser;
  XFile? _selectedImage;

  // Available languages
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

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _loadUserProfile();
  }

  void _initializeControllers() {
    _nameController = TextEditingController();
    _emailController = TextEditingController();
    _phoneController = TextEditingController();
    _selectedLanguages = [];
    _selectedSpecializations = [];
    _selectedAvailability = [];

    _currentPasswordController = TextEditingController();
    _newPasswordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
    _emailPasswordController = TextEditingController();
  }

  Future<void> _loadUserProfile() async {
    try {
      final user = _authService.getCurrentUser();
      if (user != null) {
        final userProfile =
            await _profileService.getCompleteUserProfile(user.uid);
        if (userProfile != null) {
          setState(() {
            _currentUser = userProfile;
            _nameController.text = userProfile.displayName ?? '';
            _emailController.text = userProfile.email;
            _originalEmail = userProfile.email;
            _phoneController.text = userProfile.phoneNumber ?? '';
            _selectedLanguages = userProfile.languages ?? ['English'];
            _selectedSpecializations = userProfile.specializations ?? [];
            _selectedAvailability = userProfile.availability ?? [];
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      print('Error loading user profile: $e');
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to load profile data'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _emailPasswordController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (_currentUser == null) return;

    // Validate phone number
    final phoneNumber = _phoneController.text.trim();
    if (phoneNumber.isNotEmpty && phoneNumber.length != 11) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Phone number must be exactly 11 digits'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      // Check if email has changed
      final newEmail = _emailController.text.trim();
      final emailChanged = newEmail != _originalEmail;

      if (emailChanged) {
        // Show password dialog for email update
        final password = await _showEmailUpdatePasswordDialog();
        if (password == null) {
          setState(() {
            _isSaving = false;
          });
          return;
        }

        // Update email in Firebase Auth with password verification
        await _authService.updateEmail(newEmail, password);

        // Show message that verification email has been sent
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Email update initiated. Please check your email for verification link.'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }

      // Upload profile picture if selected
      String? photoURL = _currentUser!.photoURL;
      if (_selectedImage != null) {
        photoURL = await _authService.uploadProfilePhoto(
            _currentUser!.uid, _selectedImage!);
      }

      // Update user profile
      final updates = {
        'displayName': _nameController.text.trim(),
        'email': newEmail,
        'phoneNumber': _phoneController.text.trim(),
        'photoURL': photoURL,
        'languages': _selectedLanguages,
        'specializations': _selectedSpecializations,
        'availability': _selectedAvailability,
      };

      await _dbService.updateUserProfile(_currentUser!.uid, updates);

      // Reload user profile to get updated data
      final updatedUserProfile =
          await _profileService.getCompleteUserProfile(_currentUser!.uid);
      if (updatedUserProfile != null) {
        setState(() {
          _currentUser = updatedUserProfile;
          _selectedImage = null;
          _originalEmail = updatedUserProfile.email;
          _isSaving = false;
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully!'),
          backgroundColor: AppTheme.successColor,
        ),
      );

      // Navigate back to profile page
      Navigator.pop(context);
    } catch (e) {
      print('Error saving profile: $e');
      setState(() {
        _isSaving = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to update profile'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  Future<void> _changePassword() async {
    if (_newPasswordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Passwords do not match'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    setState(() {
      _isChangingPassword = true;
    });

    try {
      await _authService.changePassword(
        _currentPasswordController.text,
        _newPasswordController.text,
      );

      setState(() {
        _isChangingPassword = false;
        _showPasswordSection = false;
        _currentPasswordController.clear();
        _newPasswordController.clear();
        _confirmPasswordController.clear();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password updated successfully!'),
          backgroundColor: AppTheme.successColor,
        ),
      );
    } catch (e) {
      print('Error changing password: $e');
      setState(() {
        _isChangingPassword = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to update password'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  Future<void> _pickImage() async {
    try {
      final ImageSource? source = await showDialog<ImageSource>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Select Image Source'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.camera_alt),
                  title: const Text('Camera'),
                  onTap: () => Navigator.of(context).pop(ImageSource.camera),
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library),
                  title: const Text('Gallery'),
                  onTap: () => Navigator.of(context).pop(ImageSource.gallery),
                ),
              ],
            ),
          );
        },
      );

      if (source != null) {
        final XFile? image = await _imagePicker.pickImage(source: source);
        if (image != null) {
          setState(() {
            _selectedImage = image;
          });
        }
      }
    } catch (e) {
      print('Error picking image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to pick image'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
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
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

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
            onPressed: _isSaving ? null : _saveProfile,
            child: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                    ),
                  )
                : const Text(
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
                      CircleAvatar(
                        radius: 50, // same as Tourist profile
                        backgroundColor: Colors.grey.shade200,
                        backgroundImage: (_currentUser?.photoURL != null &&
                                _currentUser!.photoURL!.isNotEmpty)
                            ? NetworkImage(_currentUser!.photoURL!)
                            : null,
                        child: (_currentUser?.photoURL == null ||
                                _currentUser!.photoURL!.isEmpty)
                            ? const Icon(Icons.person,
                                size: 50, color: Colors.grey)
                            : null,
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
                            onPressed: _pickImage,
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
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _emailController,
              label: 'Email',
              icon: Icons.email,
              hintText: 'Enter your email',
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _phoneController,
              label: 'Phone',
              icon: Icons.phone,
              hintText: 'Enter your phone number',
              keyboardType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(11),
              ],
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

            // Availability Section
            Text('Availability', style: AppTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(
              'Select the days you are available for tours',
              style: AppTheme.bodySmall.copyWith(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 16),
            _buildMultiSelectChips(
              items: _availableAvailability,
              selectedItems: _selectedAvailability,
              onSelectionChanged: (selected) {
                setState(() {
                  _selectedAvailability = selected;
                });
              },
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
                              onPressed:
                                  _isChangingPassword ? null : _changePassword,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryColor,
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: _isChangingPassword
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                                Colors.white),
                                      ),
                                    )
                                  : const Text('Update Password'),
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
                onPressed: _isSaving ? null : _saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text('Save Changes'),
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
    List<TextInputFormatter>? inputFormatters,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      readOnly: readOnly,
      inputFormatters: inputFormatters,
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

  Widget _buildDropdownField({
    required String? value,
    required String label,
    required IconData icon,
    required String hintText,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
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
      ),
      items: items.map((String item) {
        return DropdownMenuItem<String>(
          value: item,
          child: Text(item),
        );
      }).toList(),
      onChanged: onChanged,
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

  Future<String?> _showEmailUpdatePasswordDialog() async {
    _emailPasswordController.clear();
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Email Change'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'To update your email address, please enter your current password for security verification.',
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _emailPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Current Password',
                  hintText: 'Enter your password',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final password = _emailPasswordController.text.trim();
                if (password.isNotEmpty) {
                  Navigator.of(context).pop(password);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
              ),
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );
  }
}
