// lib/models/user.dart

class UserModel {
  final String firstName;
  final String lastName;
  final String phone;
  final String email;
  final String profilePicture;
  final String gender;
  final DateTime? dob;
  final String city;
  final String zip;
  final String country;
  final String howwemet;
  final String role;
  final List<String> preferences;
  final List<String> favorites;

  UserModel({
    required this.firstName,
    required this.lastName,
    required this.phone,
    required this.email,
    required this.profilePicture,
    required this.gender,
    required this.dob,
    required this.city,
    required this.zip,
    required this.country,
    required this.howwemet,
    required this.role,
    required this.preferences,
    required this.favorites,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      phone: json['phone'] ?? '',
      email: json['email'] ?? '',
      profilePicture: json['profilePicture'] ?? '',
      gender: json['gender'] ?? '',
      dob: json['dob'] != null ? DateTime.parse(json['dob']) : null,
      city: json['city'] ?? '',
      zip: json['zip'] ?? '',
      country: json['country'] ?? '',
      howwemet: json['howwemet'] ?? '',
      role: json['role'] ?? '',
      preferences: List<String>.from(json['preferences'] ?? []),
      favorites: List<String>.from(json['favorites'] ?? []),
    );
  }
}

