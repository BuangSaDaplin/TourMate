import 'package:cloud_firestore/cloud_firestore.dart';

enum UserStatus {
  pending, // 0
  approved, // 1
  rejected, // 2
  suspended, // 3
}

class UserModel {
  final String uid;
  final String email;
  final String role;
  final String? displayName;
  final String? phoneNumber; // NEW
  final List<String>? languages; // NEW
  final int? toursCompleted; // NEW
  final double? averageRating; // NEW
  final String? photoURL;
  final DateTime? createdAt;
  final int? activeStatus; // NEW: 1 for online/active, 0 for offline/inactive
  final String? favoriteDestination; // NEW: User's favorite destination
  final List<String>? specializations; // NEW: Tour guide specializations
  final UserStatus? status;
  final bool?
      isActive; // Admin: Account active status (true = can login, false = blocked)
  final bool?
      isLGUVerified; // Admin: Guide verification status (for tour guides only)

  // 1. Constructor
  UserModel({
    required this.uid,
    required this.email,
    required this.role,
    this.displayName,
    this.phoneNumber, // Include new fields
    this.languages,
    this.toursCompleted,
    this.averageRating,
    this.photoURL,
    this.createdAt,
    this.activeStatus,
    this.favoriteDestination,
    this.specializations,
    UserStatus? status,
    this.isActive,
    this.isLGUVerified,
    String? experience,
    List<String>? certificationsURL,
    List<String>? lguDocumentsURL,
  }) : this.status = status ??
            (role == 'tourist' ? UserStatus.approved : UserStatus.pending);

  // 2. Factory Constructor for Firestore mapping
  factory UserModel.fromFirestore(Map<String, dynamic> data) {
    return UserModel(
      uid: data['uid'] as String,
      email: data['email'] as String,
      role: data['role'] as String,
      displayName: data['displayName'] as String?,
      phoneNumber: data['phoneNumber'] as String?, // Map new field
      languages: (data['languages'] as List?)?.map((e) => e as String).toList(),
      toursCompleted: data['toursCompleted'] as int?,
      averageRating: (data['averageRating'] as num?)?.toDouble(),
      photoURL: data['photoURL'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      activeStatus: data['activeStatus'] as int?,
      favoriteDestination: data['favoriteDestination'] as String?,
      specializations:
          (data['specializations'] as List?)?.map((e) => e as String).toList(),
      status: data['status'] != null
          ? UserStatus.values[data['status'] as int]
          : null,
      experience: data['experience'] as String?,
      certificationsURL: (data['certificationsURL'] as List?)
          ?.map((e) => e as String)
          .toList(),
      lguDocumentsURL:
          (data['lguDocumentsURL'] as List?)?.map((e) => e as String).toList(),
      isActive: data['isActive'] as bool?,
      isLGUVerified: data['isLGUVerified'] as bool?,
    );
  }

  // 3. toMap method for updating/creating documents
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'role': role,
      'displayName': displayName,
      'phoneNumber': phoneNumber,
      'languages': languages,
      'toursCompleted': toursCompleted,
      'averageRating': averageRating,
      'photoURL': photoURL,
      'createdAt': createdAt,
      'activeStatus': activeStatus,
      'favoriteDestination': favoriteDestination,
      'specializations': specializations,
      'status': status?.index,
      'isActive': isActive,
      'isLGUVerified': isLGUVerified,
    };
  }
}
