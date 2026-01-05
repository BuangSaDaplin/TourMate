import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/firebase_auth_service.dart';
import '../../utils/app_theme.dart';
import 'admin_access_control_screen.dart';

class AdminAccessWrapper extends StatelessWidget {
  final Widget child;
  final bool requireRealtimeCheck;

  const AdminAccessWrapper({
    super.key,
    required this.child,
    this.requireRealtimeCheck = true,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _checkAdminAccess(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error, size: 64, color: AppTheme.errorColor),
                  const SizedBox(height: 16),
                  Text('Error verifying admin access',
                      style: AppTheme.bodyLarge),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Go Back'),
                  ),
                ],
              ),
            ),
          );
        }

        if (snapshot.data == true) {
          return child;
        }

        return const AdminAccessControlScreen();
      },
    );
  }

  Future<bool> _checkAdminAccess() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return false;

    try {
      final authService = FirebaseAuthService();
      final role = await authService.getUserRole(currentUser.uid);
      return role == 'admin';
    } catch (e) {
      return false;
    }
  }
}
