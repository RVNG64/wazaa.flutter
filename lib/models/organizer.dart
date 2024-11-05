// lib/models/organizer.dart

class OrganizerModel {
  final String organizationName;
  final String firstName;
  final String lastName;
  final String email;
  final String phone;
  final String profilePicture;
  final String website;
  final String address;
  final String city;
  final String zip;
  final String country;
  final String howwemet;
  final Map<String, String> socialMedias;
  final List<String> preferences; 
  final String role;

  OrganizerModel({
    required this.organizationName,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    required this.profilePicture,
    required this.website,
    required this.address,
    required this.city,
    required this.zip,
    required this.country,
    required this.howwemet,
    required this.socialMedias,
    required this.preferences,
    required this.role,
  });

  factory OrganizerModel.fromJson(Map<String, dynamic> json) {
    return OrganizerModel(
      organizationName: json['organizationName'] ?? '',
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      profilePicture: json['profilePicture'] ?? '',
      website: json['website'] ?? '',
      address: json['address'] ?? '',
      city: json['city'] ?? '',
      zip: json['zip'] ?? '',
      country: json['country'] ?? '',
      howwemet: json['howwemet'] ?? '',
      socialMedias: Map<String, String>.from(json['socialMedias'] ?? {}),
      preferences: List<String>.from(json['preferences'] ?? []),
      role: json['role'] ?? '',
    );
  }
}
