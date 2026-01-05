import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Custom exception for admin access denied scenarios
class AdminAccessException implements Exception {
  final String message;
  AdminAccessException(this.message);

  @override
  String toString() => 'AdminAccessException: $message';
}

/// Admin Service for managing user accounts and guide verification
/// This service provides critical admin functions for user management and security
class AdminService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Toggle user account status (activate/deactivate)
  ///
  /// This is a critical function that immediately blocks users from logging in
  /// when deactivated. The login guard checks the isActive field.
  ///
  /// Parameters:
  /// - [userId]: The user's UID
  /// - [isActive]: true to activate, false to deactivate
  ///
  /// Throws:
  /// - [AdminAccessException]: If operation fails
  Future<void> toggleUserStatus(String userId, bool isActive) async {
    try {
      final userDoc = _firestore.collection('users').doc(userId);

      // Update the isActive field
      await userDoc.update({
        'isActive': isActive,
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': _auth.currentUser?.uid ?? 'system',
      });

      // If deactivating, also sign out the user if they're currently logged in
      if (!isActive) {
        try {
          // Note: This will only work if the user is currently authenticated
          // on this device. For remote deactivation, the login guard handles it.
          await _auth.signOut();
        } catch (e) {
          // Sign out might fail if user is not logged in on this device
          // This is expected and we don't need to throw an error
          print('Note: User was not signed in on this device: $e');
        }
      }

      print('User status updated: $userId -> isActive: $isActive');
    } catch (e) {
      throw AdminAccessException('Failed to toggle user status: $e.toString()');
    }
  }

  /// Verify or unverify a tour guide
  ///
  /// When verified (isVerified = true), also sets a verificationDate timestamp
  /// This triggers the STAR algorithm mentioned in the requirements.
  ///
  /// Parameters:
  /// - [guideId]: The guide's UID
  /// - [isVerified]: true to verify, false to unverify
  ///
  /// Throws:
  /// - [AdminAccessException]: If operation fails
  Future<void> verifyGuide(String guideId, bool isVerified) async {
    try {
      final guideDoc = _firestore.collection('users').doc(guideId);

      // Verify the guide exists and has the correct role
      final guideSnapshot = await guideDoc.get();
      if (!guideSnapshot.exists) {
        throw AdminAccessException('Guide not found: $guideId');
      }

      final guideData = guideSnapshot.data();
      if (guideData?['role'] != 'guide') {
        throw AdminAccessException('User is not a guide: $guideId');
      }

      // Update verification status
      final updateData = {
        'isLGUVerified': isVerified,
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': _auth.currentUser?.uid ?? 'system',
      };

      // If verifying, add the verification date
      if (isVerified) {
        updateData['verificationDate'] = FieldValue.serverTimestamp();
      }

      await guideDoc.update(updateData);

      print(
          'Guide verification updated: $guideId -> isLGUVerified: $isVerified');
    } catch (e) {
      if (e is AdminAccessException) rethrow;
      throw AdminAccessException('Failed to verify guide: $e.toString()');
    }
  }

  /// Delete a user permanently (soft delete)
  ///
  /// Marks the user as deleted rather than permanently removing the document
  /// This preserves data integrity and allows for recovery if needed.
  ///
  /// Parameters:
  /// - [userId]: The user's UID to delete
  ///
  /// Throws:
  /// - [AdminAccessException]: If operation fails
  Future<void> deleteUser(String userId) async {
    try {
      final userDoc = _firestore.collection('users').doc(userId);

      // Soft delete - mark as deleted rather than removing document
      await userDoc.update({
        'isDeleted': true,
        'deletedAt': FieldValue.serverTimestamp(),
        'deletedBy': _auth.currentUser?.uid ?? 'system',
        'isActive': false, // Also deactivate the account
      });

      // Sign out the user if they're currently logged in
      try {
        await _auth.signOut();
      } catch (e) {
        // User might not be logged in on this device
        print('Note: User was not signed in on this device: $e');
      }

      print('User marked as deleted: $userId');
    } catch (e) {
      throw AdminAccessException('Failed to delete user: $e.toString()');
    }
  }

  /// Permanently delete user document (hard delete)
  ///
  /// WARNING: This completely removes the user document from Firestore.
  /// Use with extreme caution as this action cannot be undone.
  ///
  /// Parameters:
  /// - [userId]: The user's UID to permanently delete
  ///
  /// Throws:
  /// - [AdminAccessException]: If operation fails
  Future<void> hardDeleteUser(String userId) async {
    try {
      final userDoc = _firestore.collection('users').doc(userId);

      // Verify the document exists before deletion
      final docSnapshot = await userDoc.get();
      if (!docSnapshot.exists) {
        throw AdminAccessException('User document not found: $userId');
      }

      // Permanently delete the document
      await userDoc.delete();

      // Sign out the user if they're currently logged in
      try {
        await _auth.signOut();
      } catch (e) {
        print('Note: User was not signed in on this device: $e');
      }

      print('User document permanently deleted: $userId');
    } catch (e) {
      throw AdminAccessException(
          'Failed to permanently delete user: $e.toString()');
    }
  }

  /// Get user document data
  ///
  /// Retrieves the complete user document for admin review
  ///
  /// Parameters:
  /// - [userId]: The user's UID
  ///
  /// Returns:
  /// - [Map<String, dynamic>]: User document data
  ///
  /// Throws:
  /// - [AdminAccessException]: If user not found
  Future<Map<String, dynamic>> getUserData(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();

      if (!userDoc.exists) {
        throw AdminAccessException('User not found: $userId');
      }

      return userDoc.data()!;
    } catch (e) {
      if (e is AdminAccessException) rethrow;
      throw AdminAccessException('Failed to get user data: $e.toString()');
    }
  }

  /// Bulk update user statuses
  ///
  /// Efficiently update multiple users' active status at once
  ///
  /// Parameters:
  /// - [userIds]: List of user IDs to update
  /// - [isActive]: true to activate, false to deactivate
  ///
  /// Returns:
  /// - [int]: Number of users successfully updated
  ///
  /// Throws:
  /// - [AdminAccessException]: If operation fails
  Future<int> bulkToggleUserStatus(List<String> userIds, bool isActive) async {
    try {
      int successCount = 0;
      final batch = _firestore.batch();

      for (String userId in userIds) {
        try {
          final userDoc = _firestore.collection('users').doc(userId);
          batch.update(userDoc, {
            'isActive': isActive,
            'updatedAt': FieldValue.serverTimestamp(),
            'updatedBy': _auth.currentUser?.uid ?? 'system',
          });
          successCount++;
        } catch (e) {
          print('Failed to update user $userId: $e');
          // Continue with other users even if one fails
        }
      }

      // Commit the batch
      await batch.commit();

      print(
          'Bulk update completed: $successCount/${userIds.length} users updated');
      return successCount;
    } catch (e) {
      throw AdminAccessException(
          'Failed to bulk update user statuses: $e.toString()');
    }
  }

  /// Check if current user has admin privileges
  ///
  /// Verifies that the currently authenticated user has admin role
  ///
  /// Returns:
  /// - [bool]: true if current user is an admin
  Future<bool> isCurrentUserAdmin() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return false;

      final userDoc =
          await _firestore.collection('users').doc(currentUser.uid).get();
      if (!userDoc.exists) return false;

      final userData = userDoc.data();
      return userData?['role'] == 'admin';
    } catch (e) {
      print('Error checking admin status: $e');
      return false;
    }
  }
}
