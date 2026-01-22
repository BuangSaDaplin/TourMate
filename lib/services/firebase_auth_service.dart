  import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:tourmate_app/models/user_model.dart';
import 'package:tourmate_app/services/notification_service.dart';

class FirebaseAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  final NotificationService _notificationService = NotificationService();
  bool _googleInitialized = false;

  Future<void> _initializeGoogleSignIn() async {
    if (!_googleInitialized) {
      await _googleSignIn.initialize();
      _googleInitialized = true;
    }
  }

  Future<User?> signUp(
      {required String? name,
      required String email,
      required String password,
      required String role,
      String? phoneNumber,
      List<String>? category,
      List<String>? specializations,
      List<String>? availability}) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      final user = userCredential.user;
      if (user != null) {
        await _createUserDocument(
          user,
          role: role,
          phoneNumber: phoneNumber,
          displayName: name ?? '',
          category: category,
          specializations: specializations,
          availability: availability,
        );

        // Send email verification for Tourist role
        if (role == 'tourist') {
          await user.sendEmailVerification();
        }
      }
      return user;
    } on FirebaseAuthException catch (e) {
      debugPrint('Sign-up error: ${e.message}');
      rethrow;
    }
  }

  Future<User?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      // Send login alert notification
      if (userCredential.user != null) {
        final notification = _notificationService.createLoginAlertNotification(
          userId: userCredential.user!.uid,
        );
        await _notificationService.createNotification(notification);
      }

      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      debugPrint('Sign-in error: ${e.message}');
      rethrow;
    }
  }

  Future<User?> signInWithGoogle() async {
    try {
      if (kIsWeb) {
        final provider = GoogleAuthProvider();
        final userCredential = await _auth.signInWithPopup(provider);
        final user = userCredential.user;
        if (user != null) await _createUserDocument(user);
        return user;
      } else {
        await _initializeGoogleSignIn();
        final account = await _googleSignIn.authenticate();
        if (account == null) return null;
        final authorization = await account.authorizationClient.authorizeScopes(
          <String>['email', 'profile'],
        );
        final accessToken = authorization?.accessToken;
        final googleAuth = await account.authentication;
        final credential = GoogleAuthProvider.credential(
          idToken: googleAuth.idToken,
          accessToken: accessToken,
        );
        final userCredential = await _auth.signInWithCredential(credential);
        final user = userCredential.user;
        if (user != null) await _createUserDocument(user);
        return user;
      }
    } catch (e) {
      debugPrint('❌ Google Sign-In error: $e');
      rethrow;
    }
  }

  Future<User?> signInWithApple() async {
    debugPrint('Apple Sign-In not implemented.');
    return null;
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      debugPrint('Password reset error: ${e.message}');
      rethrow;
    }
  }

  User? getCurrentUser() => _auth.currentUser;

  Future<String?> getUserRole(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) return doc['role'] as String?;
    } catch (e) {
      debugPrint('Get role error: $e');
    }
    return null;
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
      if (!kIsWeb) await _googleSignIn.disconnect();
    } catch (e) {
      debugPrint('Sign-out error: $e');
    }
  }

  Future<void> _createUserDocument(User user,
      {String role = 'tourist',
      String displayName = '',
      String? phoneNumber,
      List<String>? category,
      List<String>? specializations,
      List<String>? availability}) async {
    final usersRef = _firestore.collection('users').doc(user.uid);
    final doc = await usersRef.get();

    if (!doc.exists) {
      // New user — create doc
      final newUser = UserModel(
        uid: user.uid,
        email: user.email ?? '',
        role: role,
        displayName: displayName.isNotEmpty
            ? displayName
            : user.displayName ?? 'New User',
        photoURL: user.photoURL,
        createdAt: DateTime.now(),
        phoneNumber: phoneNumber ?? '',
        languages: ['English'],
        toursCompleted: 0,
        averageRating: 0.0,
        category: category,
        specializations: specializations,
        availability: availability,
      );
      await usersRef.set(newUser.toMap());

      // Send successful registration notification
      final notification = _notificationService
          .createSuccessfulRegistrationNotification(userId: user.uid);
      await _notificationService.createNotification(notification);
    } else {
      // Existing user — ensure role is correct
      await usersRef.update({'role': role});
    }
  }
}
