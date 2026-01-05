import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../utils/app_theme.dart';
import '../../services/firebase_auth_service.dart';

class AdminAccessControlScreen extends StatefulWidget {
  const AdminAccessControlScreen({super.key});

  @override
  State<AdminAccessControlScreen> createState() =>
      _AdminAccessControlScreenState();
}

class _AdminAccessControlScreenState extends State<AdminAccessControlScreen> {
  final FirebaseAuthService _authService = FirebaseAuthService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final User? _currentUser = FirebaseAuth.instance.currentUser;

  bool _isAdmin = false;
  bool _isLoading = true;
  String _userRole = '';
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _checkAdminAccess();
  }

  Future<void> _checkAdminAccess() async {
    if (_currentUser == null) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'No user logged in';
      });
      return;
    }

    try {
      final role = await _authService.getUserRole(_currentUser!.uid);
      setState(() {
        _userRole = role ?? 'unknown';
        _isAdmin = role == 'admin';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error checking admin access: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage.isNotEmpty) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error, size: 64, color: AppTheme.errorColor),
              const SizedBox(height: 16),
              Text(_errorMessage, style: AppTheme.bodyLarge),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _checkAdminAccess,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (!_isAdmin) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.block, size: 64, color: AppTheme.errorColor),
              const SizedBox(height: 16),
              Text(
                'Access Denied',
                style:
                    AppTheme.headlineLarge.copyWith(color: AppTheme.errorColor),
              ),
              const SizedBox(height: 8),
              Text(
                'This area is restricted to administrators only.\nYour role: $_userRole',
                style: AppTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }

    return _buildAdminAccessContent();
  }

  Widget _buildAdminAccessContent() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Access Control'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Success Status
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.successColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border:
                    Border.all(color: AppTheme.successColor.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.verified_user, color: AppTheme.successColor),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Admin Access Confirmed',
                          style: AppTheme.bodyLarge.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppTheme.successColor,
                          ),
                        ),
                        Text(
                          'User: ${_currentUser?.email}',
                          style: AppTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Access Control Information
            Text(
              'Access Control Information',
              style: AppTheme.headlineMedium,
            ),
            const SizedBox(height: 16),
            Text(
              'This screen verifies admin access and prevents unauthorized access to admin features.',
              style: AppTheme.bodyMedium,
            ),
            const SizedBox(height: 24),

            // Current User Info
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Current User Information',
                      style: AppTheme.bodyLarge
                          .copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 12),
                    _buildInfoRow('Email', _currentUser?.email ?? 'N/A'),
                    _buildInfoRow('User ID', _currentUser?.uid ?? 'N/A'),
                    _buildInfoRow('Role', _userRole),
                    _buildInfoRow('Admin Status',
                        _isAdmin ? 'Verified Admin' : 'Not Admin'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Security Features
            Text(
              'Security Features',
              style: AppTheme.headlineMedium,
            ),
            const SizedBox(height: 16),
            _buildSecurityFeature(
              'Route Protection',
              'All admin routes check for admin role before allowing access',
              Icons.security,
            ),
            const SizedBox(height: 8),
            _buildSecurityFeature(
              'Real-time Validation',
              'Admin status is verified against Firestore on every access',
              Icons.refresh,
            ),
            const SizedBox(height: 8),
            _buildSecurityFeature(
              'Session Management',
              'Admin access is tied to authenticated Firebase sessions',
              Icons.supervised_user_circle,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: AppTheme.bodyMedium.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityFeature(
      String title, String description, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.dividerColor),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.primaryColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style:
                      AppTheme.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                ),
                Text(
                  description,
                  style: AppTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
