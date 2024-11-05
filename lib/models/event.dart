// lib/models/event.dart

class Event {
  final String id;
  final String name;
  final String? description;
  final String? photoUrl;
  final String? videoUrl;
  final String? website;
  final String? ticketLink;
  final String? category;
  final String? subcategory;
  final List<String>? tags;
  final String? audience;
  final String? startDate;
  final String? endDate;
  final String? startTime;
  final String? endTime;
  final double? latitude;
  final double? longitude;
  final bool isFinalized;
  final String status;
  final Map<String, dynamic>? priceOptions;
  final Map<String, String>? socialMedia;
  final Map<String, dynamic>? location;
  final int? capacity;
  final List<String>? accessibilityOptions;
  final List<String>? acceptedPayments; 

  Event({
    required this.id,
    required this.name,
    this.description,
    this.photoUrl,
    this.videoUrl,
    this.website,
    this.ticketLink,
    this.category,
    this.subcategory,
    this.tags,
    this.audience,
    this.startDate,
    this.endDate,
    this.startTime,
    this.endTime,
    this.latitude,
    this.longitude,
    required this.isFinalized,
    required this.status,
    this.priceOptions,
    this.socialMedia,
    this.location,
    this.capacity,
    this.accessibilityOptions,
    this.acceptedPayments,
  });

  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'],
      photoUrl: json['photoUrl'],
      videoUrl: json['videoUrl'],
      website: json['website'],
      ticketLink: json['ticketLink'],
      category: json['category'],
      subcategory: json['subcategory'],
      tags: json['tags'] != null ? List<String>.from(json['tags']) : null,
      audience: json['audience'],
      startDate: json['startDate'],
      endDate: json['endDate'],
      startTime: json['startTime'],
      endTime: json['endTime'],
      latitude: json['location'] != null ? (json['location']['latitude'] as num?)?.toDouble() : null,
      longitude: json['location'] != null ? (json['location']['longitude'] as num?)?.toDouble() : null,
      isFinalized: json['isFinalized'] ?? false,
      status: json['status'] ?? 'draft',
      priceOptions: json['priceOptions'] != null ? Map<String, dynamic>.from(json['priceOptions']) : null,
      socialMedia: json['socialMedia'] != null ? Map<String, String>.from(json['socialMedia']) : null,
      location: json['location'],
      capacity: json['capacity'],
      accessibilityOptions: json['accessibilityOptions'] != null ? List<String>.from(json['accessibilityOptions']) : null, 
      acceptedPayments: json['acceptedPayments'] != null ? List<String>.from(json['acceptedPayments']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'description': description,
      'photoUrl': photoUrl,
      'videoUrl': videoUrl,
      'website': website,
      'ticketLink': ticketLink,
      'category': category,
      'subcategory': subcategory,
      'tags': tags,
      'audience': audience,
      'startDate': startDate,
      'endDate': endDate,
      'startTime': startTime,
      'endTime': endTime,
      'location': location,
      'capacity': capacity,
      'isFinalized': isFinalized,
      'status': status,
      'socialMedia': socialMedia,
      'accessibilityOptions': accessibilityOptions, 
      'acceptedPayments': acceptedPayments,
    };
  }
}
