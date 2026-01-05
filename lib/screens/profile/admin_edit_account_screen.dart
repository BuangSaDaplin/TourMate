import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:tourmate_app/models/user_model.dart';
import 'package:tourmate_app/services/database_service.dart';
import 'package:tourmate_app/services/auth_service.dart';
import 'package:tourmate_app/services/user_profile_service.dart';
import 'package:flutter/foundation.dart';
import '../../utils/app_theme.dart';

class AdminEditAccountScreen extends StatefulWidget {
  final UserModel user;

  const AdminEditAccountScreen({super.key, required this.user});

  @override
  State<AdminEditAccountScreen> createState() => _AdminEditAccountScreenState();
}

class _AdminEditAccountScreenState extends State<AdminEditAccountScreen> {
  final _formKey = GlobalKey<FormState>();
  final _displayNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  // Password change states
  late TextEditingController _currentPasswordController;
  late TextEditingController _newPasswordController;
  late TextEditingController _confirmPasswordController;
  bool _showPasswordSection = false;
  bool _isChangingPassword = false;

  final DatabaseService _db = DatabaseService();
  final AuthService _authService = AuthService();
  final ImagePicker _imagePicker = ImagePicker();

  bool _isSaving = false;
  XFile? _selectedImage;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _loadExistingData();
  }

  void _initializeControllers() {
    _currentPasswordController = TextEditingController();
    _newPasswordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _loadExistingData() async {
    _displayNameController.text = widget.user.displayName ?? '';
    _emailController.text = widget.user.email;
    _phoneController.text = widget.user.phoneNumber ?? '';
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isSaving = true);
      try {
        // Upload profile picture if selected
        String? photoURL = widget.user.photoURL;
        if (_selectedImage != null) {
          photoURL = await _authService.uploadProfilePhoto(
              widget.user.uid, _selectedImage!);
        }

        final updates = {
          'displayName': _displayNameController.text.trim(),
          'phoneNumber': _phoneController.text.trim(),
          'photoURL': photoURL,
          'updatedAt': DateTime.now().toIso8601String(),
        };

        await _db.updateUserProfile(widget.user.uid, updates);

        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Admin profile updated successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error updating profile: ${e.toString()}')),
          );
        }
      }
      if (mounted) setState(() => _isSaving = false);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Edit Admin Profile'),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _saveProfile,
            child: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save',
                    style: TextStyle(color: AppTheme.primaryColor)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
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
                          child: _selectedImage != null
                              ? ClipOval(
                                  child: kIsWeb
                                      ? Image.network(
                                          _selectedImage!.path,
                                          width: 120,
                                          height: 120,
                                          fit: BoxFit.cover,
                                        )
                                      : Image.file(
                                          File(_selectedImage!.path),
                                          width: 120,
                                          height: 120,
                                          fit: BoxFit.cover,
                                        ),
                                )
                              : (widget.user.photoURL != null
                                  ? ClipOval(
                                      child: Image.network(
                                        widget.user.photoURL!,
                                        width: 120,
                                        height: 120,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) =>
                                            const Icon(
                                          Icons.admin_panel_settings,
                                          size: 60,
                                          color: Colors.white,
                                        ),
                                      ),
                                    )
                                  : const Icon(
                                      Icons.admin_panel_settings,
                                      size: 60,
                                      color: Colors.white,
                                    )),
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

              // Basic Information
              Text('Administrator Profile', style: AppTheme.headlineSmall),
              const SizedBox(height: 16),

              TextFormField(
                controller: _displayNameController,
                decoration: const InputDecoration(
                  labelText: 'Display Name',
                  prefixIcon: Icon(Icons.person),
                  hintText: 'Your administrative display name',
                ),
                validator: (value) =>
                    value!.isEmpty ? 'Display name is required' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email),
                  hintText: 'Your email address',
                ),
                readOnly: true,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  prefixIcon: Icon(Icons.phone),
                  hintText: '+63 912 345 6789',
                ),
              ),
              const SizedBox(height: 16),

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
                      title: Text('Change Password',
                          style: AppTheme.headlineSmall),
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
                                onPressed: _isChangingPassword
                                    ? null
                                    : _changePassword,
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

              // Info Text
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border:
                      Border.all(color: AppTheme.primaryColor.withOpacity(0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.admin_panel_settings,
                            color: AppTheme.primaryColor),
                        const SizedBox(width: 8),
                        Text('Administrator Access',
                            style: AppTheme.bodyLarge
                                .copyWith(fontWeight: FontWeight.w600)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'As an administrator, you have access to user management, system configuration, and platform oversight tools.',
                      style: AppTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
