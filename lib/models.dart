import 'package:flutter/material.dart';

class Profile {
  final String id;
  String name, city, education, occupation, subCommunity, maritalStatus, about;
  String gender;
  int age, heightCm, minAge, maxAge;
  List<String> photos, preferredCities;
  String preferredEducation, preferredOccupation, status, role;
  bool verified;

  Profile({required this.id, required this.name, required this.gender, required this.age, required this.city, this.education = '', this.occupation = '', this.subCommunity = 'Lingayat', this.maritalStatus = 'Never Married', this.heightCm = 160, this.about = '', this.photos = const [], this.minAge = 21, this.maxAge = 45, this.preferredCities = const [], this.preferredEducation = 'Any', this.preferredOccupation = 'Any', this.status = 'pending', this.role = 'user', this.verified = false});

  factory Profile.fromMap(Map<String, dynamic> m) => Profile(id: m['id'] as String, name: m['name'] as String? ?? '', gender: m['gender'] as String? ?? 'bride', age: (m['age'] as num?)?.toInt() ?? 18, city: m['city'] as String? ?? '', education: m['education'] as String? ?? '', occupation: m['occupation'] as String? ?? '', subCommunity: m['sub_community'] as String? ?? 'Lingayat', maritalStatus: m['marital_status'] as String? ?? 'Never Married', heightCm: (m['height_cm'] as num?)?.toInt() ?? 160, about: m['about'] as String? ?? '', photos: List<String>.from(m['photos'] ?? const []), minAge: (m['min_age'] as num?)?.toInt() ?? 21, maxAge: (m['max_age'] as num?)?.toInt() ?? 45, preferredCities: List<String>.from(m['preferred_cities'] ?? const []), preferredEducation: m['preferred_education'] as String? ?? 'Any', preferredOccupation: m['preferred_occupation'] as String? ?? 'Any', status: m['status'] as String? ?? 'pending', role: m['role'] as String? ?? 'user', verified: m['verified'] as bool? ?? false);

  Map<String, dynamic> toMap() => {'id': id, 'name': name, 'gender': gender, 'age': age, 'city': city, 'education': education, 'occupation': occupation, 'sub_community': subCommunity, 'marital_status': maritalStatus, 'height_cm': heightCm, 'about': about, 'photos': photos, 'min_age': minAge, 'max_age': maxAge, 'preferred_cities': preferredCities, 'preferred_education': preferredEducation, 'preferred_occupation': preferredOccupation};
}

class MatchResult { final Profile profile; final int score; final List<String> reasons; const MatchResult(this.profile, this.score, this.reasons); }

class AppThemeConfig {
  final Color seed; final bool dark;
  const AppThemeConfig({this.seed = const Color(0xFF7A1F3D), this.dark = false});
  ThemeData get data => ThemeData(useMaterial3: true, colorScheme: ColorScheme.fromSeed(seedColor: seed, brightness: dark ? Brightness.dark : Brightness.light), inputDecorationTheme: const InputDecorationTheme(border: OutlineInputBorder()), cardTheme: const CardThemeData(margin: EdgeInsets.symmetric(vertical: 6)));
}
