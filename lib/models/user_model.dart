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
  final String? firstName; // NEW: First name
  final String? lastName; // NEW: Last name
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
  final List<String>? category; // NEW: User category
  final List<String>? certifications; // NEW: List of certifications
  final List<String>? lguDocuments; // NEW: List of LGU documents
  final List<String>? availability; // NEW: Availability days for tour guides
  final double? eWallet; // NEW: E-Wallet balance

  // 1. Constructor
  UserModel({
    required this.uid,
    required this.email,
    required this.role,
    this.displayName,
    this.firstName, // NEW: First name
    this.lastName, // NEW: Last name
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
    this.category, // NEW: User category
    this.certifications, // NEW: List of certifications
    this.lguDocuments, // NEW: List of LGU documents
    this.availability, // NEW: Availability days for tour guides
    this.eWallet = 0.0, // NEW: E-Wallet balance with default value
    String? experience,
    List<String>? certificationsURL,
    List<String>? lguDocumentsURL,
  }) : this.status = status ??
            (role == 'tourist' ? UserStatus.pending : UserStatus.pending);

  // 2. Factory Constructor for Firestore mapping
  factory UserModel.fromFirestore(Map<String, dynamic> data) {
    return UserModel(
      uid: data['uid'] as String,
      email: data['email'] as String,
      role: data['role'] as String,
      displayName: data['displayName'] as String?,
      firstName: data['firstName'] as String?, // NEW: First name
      lastName: data['lastName'] as String?, // NEW: Last name
      phoneNumber: data['phoneNumber'] as String?, // Map new field
      languages: (data['languages'] as List?)?.map((e) => e as String).toList(),
      toursCompleted: data['toursCompleted'] as int?,
      averageRating: data['averageRating'] != null
          ? ((data['averageRating'] is double)
              ? data['averageRating']
              : (data['averageRating'] is int)
                  ? data['averageRating'].toDouble()
                  : double.tryParse(data['averageRating'].toString()) ?? 0.0)
          : null,
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
      category: (data['category'] as List?)
          ?.map((e) => e as String)
          .toList(), // NEW: User category
      certifications: (data['certifications'] as List?)
          ?.map((e) => e as String)
          .toList(), // NEW: List of certifications
      lguDocuments: (data['lguDocuments'] as List?)
          ?.map((e) => e as String)
          .toList(), // NEW: List of LGU documents
      availability: (data['availability'] as List?)
          ?.map((e) => e as String)
          .toList(), // NEW: Availability days for tour guides
      eWallet: data['eWallet'] != null
          ? ((data['eWallet'] is double)
              ? data['eWallet']
              : (data['eWallet'] is int)
                  ? data['eWallet'].toDouble()
                  : double.tryParse(data['eWallet'].toString()) ?? 0.0)
          : 0.0, // NEW: E-Wallet balance
    );
  }

  // 3. toMap method for updating/creating documents
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'role': role,
      'displayName': displayName,
      'firstName': firstName, // NEW: First name
      'lastName': lastName, // NEW: Last name
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
      'category': category, // NEW: User category
      'certifications': certifications, // NEW: List of certifications
      'lguDocuments': lguDocuments, // NEW: List of LGU documents
      'availability': availability, // NEW: Availability days for tour guides
      'eWallet': eWallet, // NEW: E-Wallet balance
    };
  }
}
