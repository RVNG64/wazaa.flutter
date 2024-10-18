import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/poi.dart';
import 'event_cache.dart';

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
    final url = Uri.parse('$baseUrl/events/$eventId'); // Vérifiez le point de terminaison correct
    //print ("Appel API pour l'événement $eventId"); 
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      return POI.fromJson(data);
    } else {
      //print('Erreur lors de la récupération de l\'événement: ${response.statusCode} - ${response.body}');
      throw Exception('Erreur lors de la récupération de l\'événement');
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
}