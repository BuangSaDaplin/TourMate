import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tourmate_app/models/user_model.dart';
import 'package:tourmate_app/screens/auth/login_screen.dart';
import 'package:tourmate_app/screens/auth/suspended_account_screen.dart';
import 'package:tourmate_app/screens/auth/email_verification_screen.dart';
import 'package:tourmate_app/screens/home/admin_dashboard.dart';
import 'package:tourmate_app/screens/home/tour_guide_main_dashboard.dart';
import 'package:tourmate_app/screens/home/main_dashboard.dart';
import 'package:tourmate_app/services/database_service.dart';

class RootScreen extends StatelessWidget {
  const RootScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return const Center(child: Text('Something went wrong!'));
        } else if (snapshot.hasData) {
          return FutureBuilder<UserModel?>(
            future: DatabaseService().getUser(snapshot.data!.uid),
            builder: (context, userSnapshot) {
              if (userSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (userSnapshot.hasError) {
                return const Center(child: Text('Something went wrong!'));
              } else if (userSnapshot.hasData) {
                final user = userSnapshot.data!;
                // Check if user account is suspended
                if (user.status == UserStatus.suspended ||
                    user.isActive == false) {
                  return const SuspendedAccountScreen();
                }
                switch (user.role) {
                  case 'admin':
                    return const AdminDashboard();
                  case 'guide':
                    return const TourGuideMainDashboard();
                  case 'tourist':
                  default:
                    return const MainDashboard();
                }
              } else {
                return const LoginScreen();
              }
            },
          );
        } else {
          return const LoginScreen();
        }
      },
    );
  }
}
