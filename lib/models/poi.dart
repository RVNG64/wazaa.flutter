import 'package:wazaa_app/models/poi_infos/attendance_entry.dart';
import 'package:wazaa_app/models/poi_infos/location.dart';
import 'package:wazaa_app/models/poi_infos/price_options.dart';

class POI {
  final String eventID;
  final String name;
  final String? organizerName;
  final String startDate;
  final String endDate;
  final String? startTime;
  final String? endTime;
  final String? photoUrl;
  final String? videoUrl;
  final String? description;
  final String? userOrganizer;
  final String? professionalOrganizer;
  final String? eventWazaaURL;
  final String? website;
  final String? ticketLink;
  final String? category;
  final String? subcategory;
  final List<String>? tags;
  final String? audience;
  final Location? location;
  final bool? accessibleForDisabled;
  final PriceOptions? priceOptions;
  final List<String>? acceptedPayments;
  final int? capacity;
  final String type;
  final String validationStatus;
  final List<AttendanceEntry>? attendance;
  final int views;
  final int favoritesCount;
  final String? city; // Ajout de la propriété city

  POI({
    required this.eventID,
    required this.name,
    this.organizerName,
    required this.startDate,
    required this.endDate,
    this.startTime,
    this.endTime,
    this.photoUrl,
    this.videoUrl,
    this.description,
    this.userOrganizer,
    this.professionalOrganizer,
    this.eventWazaaURL,
    this.website,
    this.ticketLink,
    this.category,
    this.subcategory,
    this.tags,
    this.audience,
    this.location,
    this.accessibleForDisabled,
    this.priceOptions,
    this.acceptedPayments,
    this.capacity,
    required this.type,
    required this.validationStatus,
    this.attendance,
    this.views = 0,
    this.favoritesCount = 0,
    this.city, // Ajout de city dans le constructeur
  });

  // Méthode pour convertir un POI à partir d'un JSON (GCS ou API)
  factory POI.fromJson(Map<String, dynamic> json) {
    // Gestion de l'adresse pour éviter les erreurs de type
    Location? location;
    if (json['location'] != null) {
      var locationData = json['location'];
      var addressData = locationData['address'];

      String formattedAddress;
      if (addressData is List) {
        // Si 'address' est une liste, on joint les éléments en une seule chaîne
        formattedAddress = addressData.join(', ');
      } else {
        // Sinon, on utilise directement la chaîne
        formattedAddress = addressData ?? 'Adresse inconnue';
      }

      location = Location(
        address: formattedAddress,
        city: locationData['city'],
        postalCode: locationData['postalCode'],
        latitude: locationData['latitude'],
        longitude: locationData['longitude'],
      );
    }

    return POI(
      eventID: json['id'] ?? '',  // Utilisation directe de la clé 'id'
      name: json['name'] ?? '',   // Utilisation directe de la clé 'name'
      organizerName: json['organizerName'], 
      startDate: json['startDate'] ?? '',
      endDate: json['endDate'] ?? '',
      startTime: json['startTime'],
      endTime: json['endTime'],
      photoUrl: json['photoUrl'],  // Utilisation directe de 'photoUrl'
      videoUrl: json['videoUrl'],
      description: json['description'],
      userOrganizer: json['userOrganizer'],
      professionalOrganizer: json['professionalOrganizer'],
      eventWazaaURL: json['eventWazaaURL'],
      website: json['website'],
      ticketLink: json['ticketLink'],
      category: json['category'],
      subcategory: json['subcategory'],
      tags: (json['tags'] as List<dynamic>?)?.map((tag) => tag.toString()).toList(),
      audience: json['audience'],
      location: location,
      city: json['city'],  // Ajout de la clé 'city' dans le parsing
      accessibleForDisabled: json['accessibleForDisabled'] ?? false,
      priceOptions: json['priceOptions'] != null ? PriceOptions.fromJson(json['priceOptions']) : null,
      acceptedPayments: json['acceptedPayments'] != null 
        ? (json['acceptedPayments'] as List<dynamic>)
            .expand((element) => element is List ? element : [element])
            .map((payment) => payment.toString())
            .toList()
        : null,
      type: json['type'] ?? 'public',
      validationStatus: json['validationStatus'] ?? 'default',
      attendance: (json['attendance'] as List<dynamic>?)?.map((att) => AttendanceEntry.fromJson(att)).toList(),
      views: json['views'] ?? 0,
      favoritesCount: json['favoritesCount'] ?? 0,
    );
  }

  // Convertit le modèle POI en JSON pour les requêtes
  Map<String, dynamic> toJson() {
    return {
      'eventID': eventID,
      'name': name,
      'organizerName': organizerName,
      'startDate': startDate,
      'endDate': endDate,
      'startTime': startTime,
      'endTime': endTime,
      'photoUrl': photoUrl,
      'videoUrl': videoUrl,
      'description': description,
      'userOrganizer': userOrganizer,
      'professionalOrganizer': professionalOrganizer,
      'eventWazaaURL': eventWazaaURL,
      'website': website,
      'ticketLink': ticketLink,
      'category': category,
      'subcategory': subcategory,
      'tags': tags,
      'audience': audience,
      'location': location?.toJson(),
      'city': city,  // Ajout de city dans la conversion en JSON
      'accessibleForDisabled': accessibleForDisabled,
      'priceOptions': priceOptions?.toJson(),
      'acceptedPayments': acceptedPayments,
      'capacity': capacity,
      'type': type,
      'validationStatus': validationStatus,
      'attendance': attendance?.map((att) => att.toJson()).toList(),
      'views': views,
      'favoritesCount': favoritesCount,
    };
  }
}
