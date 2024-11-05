import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../models/poi.dart';
import '../models/event.dart';
import '../models/attendance.dart';
import 'event_cache.dart';
import 'dart:io';

class EventService {
  final String baseUrl;
  
  // Cache des requêtes récentes
  Map<String, EventCache> _cache = {};

  EventService(this.baseUrl);

  // Génère une clé de cache unique en fonction des bornes géographiques, dates, page et limite
  String _generateCacheKey({
    required double northEastLat,
    required double northEastLng,
    required double southWestLat,
    required double southWestLng,
    String? startDate,
    String? endDate,
    int? page,
    int? limit,
  }) {
    return "$northEastLat,$northEastLng,$southWestLat,$southWestLng|$startDate|$endDate|$page|$limit";
  }

  // Méthode pour vérifier si un cache est encore valide (ici, on considère qu'un cache est valide pendant 1 jour)
  bool _isCacheValid(EventCache cache) {
    final cacheExpirationDuration = Duration(days: 1);
    return DateTime.now().difference(cache.cacheDate) < cacheExpirationDuration;
  }

  // Méthode pour récupérer les événements dans les limites de la carte, par dates et avec pagination, avec utilisation du cache
  Future<List<POI>> fetchEventsInBounds({
    required double northEastLat,
    required double northEastLng,
    required double southWestLat,
    required double southWestLng,
    String? startDate,
    String? endDate,
    int page = 1,  // Pagination : page par défaut à 1
    int limit = 50,  // Pagination : 50 événements par page par défaut
  }) async {
    // Générer une clé de cache unique incluant la page et la limite
    final cacheKey = _generateCacheKey(
      northEastLat: northEastLat,
      northEastLng: northEastLng,
      southWestLat: southWestLat,
      southWestLng: southWestLng,
      startDate: startDate,
      endDate: endDate,
      page: page,
      limit: limit,
    );

    // Vérifier si les données sont en cache et encore valides
    if (_cache.containsKey(cacheKey) && _isCacheValid(_cache[cacheKey]!)) {
      print("Cache hit for key: $cacheKey");
      return _cache[cacheKey]!.events;
    }

    // Si pas de cache valide, effectuer un nouvel appel API
    final url = Uri.parse('$baseUrl/events');
    final queryParams = {
      'ne': '$northEastLat,$northEastLng',
      'sw': '$southWestLat,$southWestLng',
      'page': '$page',  // Ajout du paramètre de page
      'limit': '$limit',  // Ajout du paramètre de limite
    };

    if (startDate != null) {
      queryParams['startDate'] = startDate;
    }
    if (endDate != null) {
      queryParams['endDate'] = endDate;
    }

    final response = await http.get(url.replace(queryParameters: queryParams));

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);

      // Convertir la liste en List<POI>
      final List<POI> events = data.map((json) => POI.fromJson(json)).toList();

      // Stocker le résultat en cache avec la clé unique
      _cache[cacheKey] = EventCache(
        cacheKey: cacheKey,
        events: events,
        cacheDate: DateTime.now(),  // Date actuelle
      );

      return events;
    } else {
      throw Exception('Erreur lors de la récupération des événements');
    }
  }

  // Méthode pour récupérer un événement spécifique via son ID
  Future<POI> fetchEventById(String eventId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/events/$eventId'),
        headers: {'Content-Type': 'application/json'},
      );

      print('Fetching event with ID: $eventId, response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return POI.fromJson(data);
      } else {
        throw Exception('Failed to load event with ID $eventId');
      }
    } catch (e) {
      print('Erreur lors de la récupération de l\'événement avec ID $eventId : $e');
      rethrow;
    }
  }

  // Méthode pour récupérer tous les événements avec pagination
  Future<List<POI>> fetchEventsByPage(int page, int limit) async {
    final url = Uri.parse('$baseUrl/events');
    final queryParams = {
      'page': '$page',
      'limit': '$limit',
    };

    //print("Appel API pour récupérer les événements avec pagination - Page: $page, Limite: $limit");

    final response = await http.get(url.replace(queryParameters: queryParams));

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      print("Données reçues : ${response.body}");  // Ajoute ce log pour afficher les données reçues
      
      // Convertir la liste en List<POI> et ajouter le log demandé pour chaque événement
      final List<POI> events = data.map((json) {
        POI poi = POI.fromJson(json);
        // print('Event: ${poi.name}, Date de début/fin: ${poi.startDate}/${poi.endDate}'); 
        return poi;
      }).toList();

      return events;
    } else {
      print("Erreur lors de la récupération des événements : ${response.statusCode} - ${response.body}");  // Ajoute ce log pour afficher l'erreur
      throw Exception('Erreur lors de la récupération des événements');
    }
  }

  // Méthode pour créer un événement (finalisé ou brouillon)
  Future<void> createEvent(Map<String, dynamic> eventData, {bool isFinalized = false}) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      String? token = await user.getIdToken();

      // Ajouter le champ 'isFinalized' aux données de l'événement
      eventData['isFinalized'] = isFinalized;

      final response = await http.post(
        Uri.parse('$baseUrl/native-events'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(eventData),
      );

      if (response.statusCode == 201) {
        // Succès
        print('Événement créé avec succès');
      } else {
        // Gérer les erreurs
        print('Erreur lors de la création de l\'événement: ${response.body}');
        throw Exception('Erreur lors de la création de l\'événement');
      }
    } else {
      throw Exception('Utilisateur non connecté');
    }
  }

  // Méthode pour uploader une image sur Cloudinary
  Future<String> uploadImageToCloudinary(File imageFile) async {
    String cloudinaryUploadUrl = 'https://api.cloudinary.com/v1_1/${dotenv.env['CLOUDINARY_CLOUD_NAME']}/image/upload';
    String cloudinaryPreset = dotenv.env['CLOUDINARY_PRESET'] ?? '';

    var request = http.MultipartRequest('POST', Uri.parse(cloudinaryUploadUrl))
      ..fields['upload_preset'] = cloudinaryPreset
      ..files.add(await http.MultipartFile.fromPath('file', imageFile.path));

    var response = await request.send();
    if (response.statusCode == 200) {
      var responseData = await response.stream.bytesToString();
      var jsonResponse = json.decode(responseData);
      return jsonResponse['secure_url'];
    } else {
      throw Exception('Failed to upload image to Cloudinary');
    }
  }

  Future<List<Event>> fetchEventsOrganizedByUser() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      String? token = await user.getIdToken();
      final response = await http.get(
        Uri.parse('$baseUrl/native-events/organized'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        print('Response data: $responseData');

        if (responseData['events'] is List) {
          final List<dynamic> eventsData = responseData['events'];
          return eventsData.map((eventJson) => Event.fromJson(eventJson)).toList();
        } else {
          throw Exception('Structure inattendue dans la réponse');
        }
      } else {
        throw Exception('Erreur lors de la récupération des événements organisés');
      }
    } else {
      throw Exception('Utilisateur non connecté');
    }
  }

  Future<void> updateEvent(String eventId, Map<String, dynamic> eventData) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      String? token = await user.getIdToken();

      final response = await http.put(
        Uri.parse('$baseUrl/native-events/$eventId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(eventData),
      );

      if (response.statusCode == 200) {
        // Succès
        print('Événement mis à jour avec succès');
      } else {
        // Gérer les erreurs
        print('Erreur lors de la mise à jour de l\'événement: ${response.body}');
        throw Exception('Erreur lors de la mise à jour de l\'événement');
      }
    } else {
      throw Exception('Utilisateur non connecté');
    }
  }

  Future<void> deleteEvent(String eventId) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      String? token = await user.getIdToken();
      final response = await http.delete(
        Uri.parse('$baseUrl/native-events/$eventId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode != 200) {
        // Log pour plus de détails sur l'erreur
        print('Erreur de suppression : ${response.body}');
        throw Exception('Erreur lors de la suppression de l\'événement');
      }
    } else {
      throw Exception('Utilisateur non connecté');
    }
  }

  Future<String?> getUserAttendanceStatus(String eventId) async {
    String url = '$baseUrl/native-events/$eventId/attendance/status';
    print('GET Attendance Status URL: $url');
    String? token = await FirebaseAuth.instance.currentUser?.getIdToken();

    final response = await http.get(Uri.parse(url), headers: {
      'Authorization': 'Bearer $token',
    });

    print('GET Attendance Status Response: ${response.statusCode}');
    print('GET Attendance Status Response Body: ${response.body}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['status'];
    } else {
      // Gérer l'erreur
      print('Erreur GET /attendance/status: ${response.statusCode} - ${response.body}');
      throw Exception('Erreur lors de la récupération du statut de présence.');
    }
  }

  Future<bool> updateAttendanceStatus(String eventId, String status) async {
    String url = '$baseUrl/native-events/$eventId/attendance';
    String? token = await FirebaseAuth.instance.currentUser?.getIdToken();

    final response = await http.post(Uri.parse(url),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'status': status}),
    );

    return response.statusCode == 200;
  }

  Future<List<Attendance>> getAttendanceList(String eventId) async {
    String url = '$baseUrl/native-events/$eventId/attendance';
    String? token = await FirebaseAuth.instance.currentUser?.getIdToken();

    final response = await http.get(Uri.parse(url), headers: {
      'Authorization': 'Bearer $token',
    });

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      List<Attendance> attendanceList = (data['attendance'] as List)
          .map((att) => Attendance.fromJson(att))
          .toList();
      return attendanceList;
    } else {
      // Gérer l'erreur
      return [];
    }
  }

  Future<bool> removeUserAttendance(String eventId, String userId) async {
    String url = '$baseUrl/native-events/$eventId/attendance/$userId';
    String? token = await FirebaseAuth.instance.currentUser?.getIdToken();

    final response = await http.delete(Uri.parse(url), headers: {
      'Authorization': 'Bearer $token',
    });

    return response.statusCode == 200;
  }

  Future<bool> blockUser(String eventId, String userId) async {
    String url = '$baseUrl/native-events/$eventId/block/$userId';
    String? token = await FirebaseAuth.instance.currentUser?.getIdToken();

    final response = await http.post(Uri.parse(url), headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    });

    return response.statusCode == 200;
  }
}