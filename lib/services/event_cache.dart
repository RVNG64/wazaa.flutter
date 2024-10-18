import '../models/poi.dart';  // Assure l'import de la classe POI

class EventCache {
  final List<POI> events;  // Liste des événements
  final String cacheKey;    // Clé de cache (basée sur les bornes géographiques et les dates)
  final DateTime cacheDate; // Date de création du cache

  EventCache({
    required this.cacheKey,
    required this.events,
    required this.cacheDate,  // Date actuelle de la création du cache
  });
}
