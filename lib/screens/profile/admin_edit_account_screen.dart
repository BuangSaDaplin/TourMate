import 'package:flutter/material.dart';
import 'package:tourmate_app/models/user_model.dart';
import 'package:tourmate_app/services/database_service.dart';
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
  final _phoneController = TextEditingController();
  final _departmentController = TextEditingController();

  final DatabaseService _db = DatabaseService();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadExistingData();
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _phoneController.dispose();
    _departmentController.dispose();
    super.dispose();
  }

  Future<void> _loadExistingData() async {
    // Load additional profile data from database
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        final updates = {
          'displayName': _displayNameController.text,
          'phone': _phoneController.text,
          'department': _departmentController.text,
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
      if (mounted) setState(() => _isLoading = false);
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
            onPressed: _isLoading ? null : _saveProfile,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save', style: TextStyle(color: AppTheme.primaryColor)),
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
              // Profile Picture Placeholder
              Center(
                child: CircleAvatar(
                  radius: 60,
                  backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                  child: const Icon(Icons.admin_panel_settings, size: 60, color: AppTheme.primaryColor),
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
                validator: (value) => value!.isEmpty ? 'Display name is required' : null,
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

              TextFormField(
                controller: _departmentController,
                decoration: const InputDecoration(
                  labelText: 'Department/Role',
                  prefixIcon: Icon(Icons.business),
                  hintText: 'e.g., System Administrator, Support Manager',
                ),
              ),
              const SizedBox(height: 32),

              // Info Text
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.primaryColor.withOpacity(0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.admin_panel_settings, color: AppTheme.primaryColor),
                        const SizedBox(width: 8),
                        Text('Administrator Access', style: AppTheme.bodyLarge.copyWith(fontWeight: FontWeight.w600)),
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