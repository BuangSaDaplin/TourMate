class TourGuideModel {
  final String uid;
  final String name;
  final String email;
  final String phone;
  final String experience;
  final List<String> languages;
  final List<String> specializations;
  final List<String> certifications;
  final List<String> lguDocuments;

  TourGuideModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.phone,
    required this.experience,
    required this.languages,
    required this.specializations,
    required this.certifications,
    required this.lguDocuments,
  });

  factory TourGuideModel.fromMap(Map<String, dynamic> data) {
    return TourGuideModel(
      uid: data['uid'] ?? '',
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      phone: data['phone'] ?? '',
      experience: data['experience'] ?? '',
      languages: List<String>.from(data['languages'] ?? []),
      specializations: List<String>.from(data['specializations'] ?? []),
      certifications: List<String>.from(data['certifications'] ?? []),
      lguDocuments: List<String>.from(data['lguDocuments'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'phone': phone,
      'experience': experience,
      'languages': languages,
      'specializations': specializations,
      'certifications': certifications,
      'lguDocuments': lguDocuments,
    };
  }

  TourGuideModel copyWith({
    String? uid,
    String? name,
    String? email,
    String? phone,
    String? experience,
    List<String>? languages,
    List<String>? specializations,
    List<String>? certifications,
    List<String>? lguDocuments,
  }) {
    return TourGuideModel(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      experience: experience ?? this.experience,
      languages: languages ?? this.languages,
      specializations: specializations ?? this.specializations,
      certifications: certifications ?? this.certifications,
      lguDocuments: lguDocuments ?? this.lguDocuments,
    );
  }
}
