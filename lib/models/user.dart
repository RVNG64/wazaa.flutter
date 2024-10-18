// lib/models/user.dart

class UserModel {
  final String firstName;
  final String lastName;
  final String phone;
  final String email;
  final String profilePicture;
  final List<String> preferences;
  final List<String> favorites;

  UserModel({
    required this.firstName,
    required this.lastName,
    required this.phone,
    required this.email,
    required this.profilePicture,
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
      preferences: List<String>.from(json['preferences'] ?? []),
      favorites: List<String>.from(json['favorites'] ?? []),
    );
  }
}
