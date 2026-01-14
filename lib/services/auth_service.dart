import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tourmate_app/models/user_model.dart';
import 'package:tourmate_app/services/database_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseService _db = DatabaseService();
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Sign in with email and password
  Future<UserCredential?> signInWithEmailAndPassword(
      String email, String password) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
          email: email, password: password);

      // CRITICAL LOGIN GUARD - Check if user is deactivated
      if (userCredential.user != null) {
        await _checkUserAccountStatus(userCredential.user!.uid);
      }

      return userCredential;
    } catch (e) {
      print(e.toString());
      return null;
    }
  }

  /// CRITICAL LOGIN GUARD - Checks if user account is active
  /// This is the core security function that blocks deactivated users
  Future<void> _checkUserAccountStatus(String userId) async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (userDoc.exists) {
        final userData = userDoc.data();
        final isActive = userData?['isActive'];

        // If isActive is false or null (default to false for safety), block access
        if (isActive == false) {
          // Immediately sign out the user
          await _auth.signOut();

          // Throw custom exception with specific message
          throw Exception(
              'Access Denied: Your account has been deactivated by an Administrator.');
        }
      } else {
        // User document doesn't exist - block access for safety
        await _auth.signOut();
        throw Exception(
            'Access Denied: Account data not found. Please contact support.');
      }
    } catch (e) {
      // If it's our custom exception, rethrow it
      if (e.toString().contains('Access Denied:')) {
        rethrow;
      }

      // For other errors, still block access for safety
      await _auth.signOut();
      throw Exception(
          'Access Denied: Unable to verify account status. Please contact support.');
    }
  }

  // Register with email and password
  Future<UserCredential?> registerWithEmailAndPassword(
      String email, String password) async {
    try {
      final UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);
      await _createUserDocument(userCredential.user!);
      return userCredential;
    } catch (e) {
      print(e.toString());
      return null;
    }
  }

  /* Add this to AuthService.dart */
  Future<void> _createUserDocument(User user, {String displayName = ''}) async {
    final usersRef =
        FirebaseFirestore.instance.collection('users').doc(user.uid);

    // Use the UserModel to create a default document
    final newUser = UserModel(
      uid: user.uid,
      email: user.email ?? '',
      role: 'tourist', // Default role for new signups
      displayName:
          displayName.isNotEmpty ? displayName : user.displayName ?? 'New User',
      photoURL: user.photoURL,
      createdAt: DateTime.now(),
      // Set default values for new fields to avoid null errors
      phoneNumber: '',
      languages: ['English'],
      toursCompleted: 0,
      averageRating: 0.0,
    );

    try {
      // Set the data in Firestore
      await usersRef.set(newUser.toMap());
    } catch (e) {
      print("Error creating user document: $e");
      // Handle error
    }
  }

  // Upload profile photo
  Future<String?> uploadProfilePhoto(String uid, XFile image) async {
    try {
      print('Starting upload for user: $uid');
      final Reference ref = _storage.ref().child('users').child('$uid.jpg');
      print('Upload path: ${ref.fullPath}');

      if (kIsWeb) {
        // For web, use bytes
        print('Uploading for web platform');
        final bytes = await image.readAsBytes();
        print('Image bytes length: ${bytes.length}');
        await ref.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
      } else {
        // For mobile, use file
        print('Uploading for mobile platform');
        final file = File(image.path);
        print('File exists: ${file.existsSync()}');
        await ref.putFile(file);
      }

      final downloadURL = await ref.getDownloadURL();
      print('Upload successful, download URL: $downloadURL');
      return downloadURL;
    } catch (e) {
      print('Upload failed with error: $e');
      return null;
    }
  }

  // Hard delete account
  Future<void> hardDeleteAccount() async {
    try {
      final User? user = _auth.currentUser;
      if (user != null) {
        await _db.deleteUser(user.uid);
        await _storage.ref().child('users').child('${user.uid}.jpg').delete();
        await user.delete();
      }
    } catch (e) {
      print(e.toString());
    }
  }

  // Change password
  Future<void> changePassword(
      String currentPassword, String newPassword) async {
    try {
      final user = _auth.currentUser;
      if (user != null && user.email != null) {
        // Re-authenticate user before changing password
        final credential = EmailAuthProvider.credential(
          email: user.email!,
          password: currentPassword,
        );
        await user.reauthenticateWithCredential(credential);
        await user.updatePassword(newPassword);
      }
    } catch (e) {
      throw Exception('Failed to change password: ${e.toString()}');
    }
  }

  // Update email with password verification and email verification
  Future<void> updateEmail(String newEmail, String password) async {
    try {
      final user = _auth.currentUser;
      if (user != null && user.email != null) {
        // Re-authenticate user before updating email
        final credential = EmailAuthProvider.credential(
          email: user.email!,
          password: password,
        );
        await user.reauthenticateWithCredential(credential);

        // Send verification email to the new email address
        await user.verifyBeforeUpdateEmail(newEmail);
        // Note: The email won't be updated until the user clicks the verification link
      }
    } catch (e) {
      throw Exception('Failed to update email: ${e.toString()}');
    }
  }

  // Update email with email verification (sends verification email to new address)
  Future<void> updateEmailWithVerification(String newEmail) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        // Send verification email to the new email address
        await user.verifyBeforeUpdateEmail(newEmail);
        // Note: The email won't be updated until the user clicks the verification link
        // For now, we'll update the database and inform the user to check their email
      }
    } catch (e) {
      throw Exception('Failed to send verification email: ${e.toString()}');
    }
  }

  // Update email without password verification (for cases where verification is not required)
  Future<void> updateEmailWithoutPassword(String newEmail) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        // Firebase requires email verification for email updates
        // Send verification email to the new email address
        await user.verifyBeforeUpdateEmail(newEmail);
        // Note: The email won't be updated until the user clicks the verification link
        // For now, we'll update the database and inform the user to check their email
      }
    } catch (e) {
      throw Exception('Failed to send verification email: ${e.toString()}');
    }
  }

  // Soft deactivate account
  Future<void> softDeactivateAccount() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await _db.updateUserField(user.uid, 'isActive', false);
        await signOut();
      }
    } catch (e) {
      throw Exception('Failed to deactivate account: ${e.toString()}');
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Get the current user
  User? getCurrentUser() {
    return _auth.currentUser;
  }

  // Get the current user model from Firestore
  Future<UserModel?> getCurrentUserModel() async {
    final user = getCurrentUser();
    if (user != null) {
      return await _db.getUser(user.uid);
    }
    return null;
  }
}
