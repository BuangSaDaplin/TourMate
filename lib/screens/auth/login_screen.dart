import 'package:flutter/material.dart';
import 'package:tourmate_app/screens/auth/signup_screen.dart';
import 'package:tourmate_app/services/firebase_auth_service.dart';
import 'package:tourmate_app/services/database_service.dart';
import 'package:tourmate_app/models/user_model.dart';
import '../../utils/app_theme.dart';
import '../home/main_dashboard.dart';
import '../home/tour_guide_main_dashboard.dart';
import '../home/admin_dashboard.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'suspended_account_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final FirebaseAuthService _authService = FirebaseAuthService();
  final DatabaseService _databaseService = DatabaseService();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _rememberMe = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _showForgotPasswordDialog() async {
    final emailController = TextEditingController(text: _emailController.text);
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Reset Password'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                TextFormField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    hintText: 'Enter your email',
                  ),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Send Link'),
              onPressed: () async {
                try {
                  await _authService.sendPasswordResetEmail(
                    emailController.text,
                  );
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Password reset link sent! Check your email',
                        ),
                      ),
                    );
                    Navigator.of(context).pop();
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: ${e.toString()}')),
                    );
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _navigateBasedOnUserStatusAndRole(
    String uid,
    String? role,
  ) async {
    print(
      'Navigating based on user status and role for UID: $uid, Role: $role',
    );
    // First, check if the user account is suspended
    final user = await _databaseService.getUser(uid);
    print('User status: ${user?.status}');
    print('User activeStatus: ${user?.activeStatus}');
    print('User isActive: ${user?.isActive}');
    if (user != null &&
        (user.status == UserStatus.suspended || user.isActive == false)) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const SuspendedAccountScreen()),
      );
      return;
    }

    // If not suspended, navigate based on role
    Widget destination;
    switch (role) {
      case 'admin':
        destination = const AdminDashboard();
        break;
      case 'guide':
        destination = const TourGuideMainDashboard();
        break;
      case 'tourist':
      default:
        destination = const MainDashboard();
        break;
    }

    Navigator.of(
      context,
    ).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => destination),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),
              // Logo and Title
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        gradient: AppTheme.primaryGradient,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryColor.withOpacity(0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.explore,
                        size: 40,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text('Welcome Back!', style: AppTheme.headlineMedium),
                    const SizedBox(height: 8),
                    Text(
                      'Sign in to continue your journey',
                      style: AppTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 48),
              // Email Field
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'Email',
                  hintText: 'Enter your email',
                  prefixIcon: const Icon(Icons.email_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Password Field
              TextFormField(
                controller: _passwordController,
                obscureText: !_isPasswordVisible,
                decoration: InputDecoration(
                  labelText: 'Password',
                  hintText: 'Enter your password',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isPasswordVisible
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() {
                        _isPasswordVisible = !_isPasswordVisible;
                      });
                    },
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Remember Me and Forgot Password
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Checkbox(
                        value: _rememberMe,
                        onChanged: (value) {
                          setState(() {
                            _rememberMe = value ?? false;
                          });
                        },
                        activeColor: AppTheme.primaryColor,
                      ),
                      Text('Remember me', style: AppTheme.bodyMedium),
                    ],
                  ),
                  TextButton(
                    onPressed: () {
                      _showForgotPasswordDialog();
                    },
                    child: Text(
                      'Forgot Password?',
                      style: AppTheme.bodyMedium.copyWith(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Sign In Button
              ElevatedButton(
                onPressed: _isLoading
                    ? null
                    : () async {
                        if (_emailController.text.isEmpty ||
                            _passwordController.text.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Please fill in all fields'),
                            ),
                          );
                          return;
                        }

                        setState(() => _isLoading = true);

                        try {
                          await _authService.signIn(
                            email: _emailController.text.trim(),
                            password: _passwordController.text,
                          );

                          // ✅ Check if user is actually signed in
                          final firebaseUser =
                              FirebaseAuth.instance.currentUser;
                          if (firebaseUser == null) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'User not signed in. Please try again.',
                                  ),
                                ),
                              );
                            }
                            return;
                          }

                          // ✅ Proceed only if the user exists
                          final user = _authService.getCurrentUser();
                          print(
                            'Current user after email sign in: ${user?.uid}',
                          );
                          if (user != null) {
                            final role = await _authService.getUserRole(
                              user.uid,
                            );
                            print('User role from email: $role');
                            if (role != null) {
                              await _navigateBasedOnUserStatusAndRole(
                                user.uid,
                                role,
                              );
                            } else {
                              await _navigateBasedOnUserStatusAndRole(
                                user.uid,
                                'tourist',
                              );
                            }
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Sign in failed: ${e.toString()}',
                                ),
                              ),
                            );
                          }
                        } finally {
                          if (mounted) {
                            setState(() => _isLoading = false);
                          }
                        }
                      },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text(
                        'Sign In',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
              const SizedBox(height: 24),
              // OR Divider
              Row(
                children: [
                  Expanded(
                    child: Container(height: 1, color: AppTheme.dividerColor),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text('OR', style: AppTheme.bodyMedium),
                  ),
                  Expanded(
                    child: Container(height: 1, color: AppTheme.dividerColor),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Social Login Buttons
              OutlinedButton.icon(
                onPressed: _isLoading
                    ? null
                    : () async {
                        setState(() => _isLoading = true);

                        try {
                          await _authService.signInWithGoogle();

                          // Get user role and navigate
                          final user = _authService.getCurrentUser();
                          print(
                            'Current user after Google sign in: ${user?.uid}',
                          );
                          if (user != null) {
                            final role = await _authService.getUserRole(
                              user.uid,
                            );
                            print('User role from Google: $role');
                            if (role != null) {
                              await _navigateBasedOnUserStatusAndRole(
                                user.uid,
                                role,
                              );
                            } else {
                              // Fallback to tourist dashboard if role is null
                              await _navigateBasedOnUserStatusAndRole(
                                user.uid,
                                'tourist',
                              );
                            }
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Google sign in failed: ${e.toString()}',
                                ),
                              ),
                            );
                          }
                        } finally {
                          if (mounted) {
                            setState(() => _isLoading = false);
                          }
                        }
                      },
                icon: const Icon(Icons.g_mobiledata, size: 24),
                label: const Text('Continue with Google'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  side: const BorderSide(color: AppTheme.dividerColor),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _isLoading
                    ? null
                    : () async {
                        setState(() => _isLoading = true);

                        try {
                          await _authService.signInWithApple();

                          // Get user role and navigate
                          final user = _authService.getCurrentUser();
                          if (user != null) {
                            final role = await _authService.getUserRole(
                              user.uid,
                            );
                            if (role != null) {
                              await _navigateBasedOnUserStatusAndRole(
                                user.uid,
                                role,
                              );
                            } else {
                              // Fallback to tourist dashboard if role is null
                              await _navigateBasedOnUserStatusAndRole(
                                user.uid,
                                'tourist',
                              );
                            }
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Apple sign in failed: ${e.toString()}',
                                ),
                              ),
                            );
                          }
                        } finally {
                          if (mounted) {
                            setState(() => _isLoading = false);
                          }
                        }
                      },
                icon: const Icon(Icons.apple, size: 24),
                label: const Text('Continue with Apple'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  side: const BorderSide(color: AppTheme.dividerColor),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Sign Up Button
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const SignUpScreen(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppTheme.primaryColor,
                  side: const BorderSide(color: AppTheme.primaryColor),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Sign Up',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
