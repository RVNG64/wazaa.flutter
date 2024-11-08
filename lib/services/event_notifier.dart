import 'package:flutter/material.dart';
import '../providers/auth_provider.dart';
import '../models/poi.dart';
import '../models/event.dart';
import '../services/event_service.dart';
import '../services/user_service.dart';

class EventNotifier extends ChangeNotifier {
  List<POI> _events = [];
  List<Event> _nativeEvents = [];
  List<POI> get events => _events;
  List<Event> get nativeEvents => _nativeEvents;

  // API URL de base
  final String apiUrl = "http://10.0.2.2:3000";

  // Services nécessaires
  final UserService _userService = UserService();
  final AuthProvider _authProvider = AuthProvider();

  // Ajout de la liste des événements favoris
  List<POI> _favoriteEvents = [];
  Set<String> _favoriteEventIds = {};

  int _currentPage = 1;
  final int _eventsPerPage = 50;

  bool _isLoading = false;
  bool _hasMoreEvents = true;
  // Indicateurs pour savoir si on est en train de charger ou s'il reste des événements
  bool get isLoading => _isLoading;
  bool get hasMoreEvents => _hasMoreEvents;

  bool _isLoadingFavorites = false;
  bool get isLoadingFavorites => _isLoadingFavorites;

  // Indicateur pour savoir si les événements ont déjà été chargés
  bool get hasEventsLoaded => _events.isNotEmpty || _nativeEvents.isNotEmpty;
  bool _areEventsPreloaded = false;  // Nouvel indicateur d'état
  bool get areEventsPreloaded => _areEventsPreloaded;  // Getter pour l'état

  // Liste des ID d'événements sponsorisés
  final List<String> sponsoredEventIDs = [
    'FMAAQU064V5BW1SJ',
    'FMAAQU064V5BTDT3',
    'FMAAQU064V5C0Q9T',
    'FMAAQU064V5B8X2D',
    'FMAAQU064V5C0LDQ',
  ];

  // Charger les événements depuis l'API uniquement si nécessaire
  Future<void> loadEventsIfNeeded() async {
    if (_areEventsPreloaded) {
      print("Les événements sont déjà préchargés.");
      return;
    }
    await fetchEventsFromApi();
  }

  // Méthode pour définir les événements préchargés (directement depuis l'API)
  void setPreloadedEvents(List<POI> events) {
    _events = events;
    _areEventsPreloaded = true;
    notifyListeners();
  }

  // Ajouter des événements à la liste existante
  void addEvents(List<POI> newEvents) {
    _events.addAll(newEvents);
    notifyListeners();
  }

  // Charger les événements depuis l'API
  Future<void> fetchEventsFromApi() async {
    if (_isLoading || !_hasMoreEvents) return;

    _isLoading = true;
    notifyListeners();

    try {
      // Récupération des événements paginés
      List<POI> apiEvents = await EventService('http://10.0.2.2:3000').fetchEventsByPage(_currentPage, _eventsPerPage);
      if (apiEvents.isNotEmpty) {
        _events.addAll(apiEvents);
        _currentPage++;
      } else {
        _hasMoreEvents = false;
      }

      // Vérifier les événements sponsorisés manquants
      Set<String> fetchedEventIDs = _events.map((e) => e.eventID).toSet();
      List<String> missingSponsoredEventIDs = sponsoredEventIDs.where((id) => !fetchedEventIDs.contains(id)).toList();

      // Récupérer les événements sponsorisés manquants
      for (String missingId in missingSponsoredEventIDs) {
        POI sponsoredEvent = await EventService('http://10.0.2.2:3000').fetchEventById(missingId);
        _events.add(sponsoredEvent);
      }

      print("Nombre total d'événements : ${_events.length}");
      notifyListeners();
    } catch (error) {
      print("Erreur lors de la récupération des événements : $error");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Charger les événements en fonction des bornes géographiques avec pagination
  Future<List<POI>> fetchEventsInBounds({
    required double northEastLat,
    required double northEastLng,
    required double southWestLat,
    required double southWestLng,
    String? startDate,
    String? endDate,
    int page = 1,
    int limit = 50,
  }) async {
    if (_isLoading || !_hasMoreEvents) return [];

    _isLoading = true;
    notifyListeners();

    try {
      List<POI> apiEvents = await EventService('http://10.0.2.2:3000').fetchEventsInBounds(
        northEastLat: northEastLat,
        northEastLng: northEastLng,
        southWestLat: southWestLat,
        southWestLng: southWestLng,
        startDate: startDate,
        endDate: endDate,
        page: page,
        limit: _eventsPerPage,
      );

      if (apiEvents.isNotEmpty) {
        _events.addAll(apiEvents);
        _currentPage++;
      } else {
        _hasMoreEvents = false;
      }
      print("Nombre total d'événements : ${_events.length}");
      print("Liste des événements : $_events");

      notifyListeners();
      return apiEvents;
    } catch (error) {
      print("Erreur lors de la récupération des événements dans les limites données : $error");
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Getter pour les événements favoris
  List<POI> get favoriteEvents => _favoriteEvents;

  // Vérifier si un événement est favori
  bool isFavorite(dynamic event) {
    String eventId = event is POI ? event.eventID : (event is Event ? event.id : '');
    return _favoriteEventIds.contains(eventId);
  }

  // Charger les favoris depuis le backend
  Future<void> loadFavorites() async {
    notifyListeners();

    String? token = await _authProvider.getIdToken();
    //print('Token obtenu : $token');

    if (token != null) {
      List<String>? favorites = await _userService.getUserFavorites(token);
      if (favorites != null) {
        _favoriteEventIds = favorites.toSet();
        _favoriteEvents.clear();

        List<String> failedEventIds = [];

        for (String eventId in _favoriteEventIds) {
          try {
            dynamic event = await EventService(apiUrl).fetchEventById(eventId);
            _favoriteEvents.add(event);
          } catch (e) {
            // Gérer les erreurs si nécessaire
            failedEventIds.add(eventId);
          }
        }
        notifyListeners();
      }
    }
  }

  // Ajouter un événement aux favoris
  Future<void> addToFavorites(dynamic event) async {
    String? token = await _authProvider.getIdToken();
    String eventId = event is POI ? event.eventID : (event is Event ? event.id : '');

    if (token != null && eventId.isNotEmpty) {
      bool success = await _userService.addEventToFavorites(token, eventId);
      if (success) {
        _favoriteEventIds.add(eventId);
        _favoriteEvents.add(event);
        notifyListeners();
      }
    }
  }

  // Ajouter un événement (Native Event) aux favoris
  Future<void> addEventToFavorites(Event event) async {
    String? token = await _authProvider.getIdToken();
    if (token != null && event.id.isNotEmpty) {
      bool success = await _userService.addEventToFavorites(token, event.id);
      if (success) {
        _favoriteEventIds.add(event.id);
        _favoriteEvents.add(POI(
          eventID: event.id,
          name: event.name,
          startDate: event.startDate ?? '',
          endDate: event.endDate ?? '',
          type: 'event',
          validationStatus: event.status,
        ));
        notifyListeners();
      }
    }
  }

  // Supprimer un événement des favoris
  Future<void> removeFromFavorites(dynamic event) async {
    String? token = await _authProvider.getIdToken();
    String eventId = event is POI ? event.eventID : (event is Event ? event.id : '');

    if (token != null && eventId.isNotEmpty) {
      bool success = await _userService.removeEventFromFavorites(token, eventId);
      if (success) {
        _favoriteEventIds.remove(eventId);
        _favoriteEvents.removeWhere((e) {
          if (e is Event) {
            return (e as Event).id == eventId; // Cast explicite ajouté ici
          } else if (e is POI) {
            return e.eventID == eventId;
          }
          return false;
        });

        notifyListeners();
      }
    }
  }

  // Supprimer un événement (Native Event) des favoris
  Future<void> removeEventFromFavorites(Event event) async {
    String? token = await _authProvider.getIdToken();
    if (token != null && event.id.isNotEmpty) {
      bool success = await _userService.removeEventFromFavorites(token, event.id);
      if (success) {
        _favoriteEventIds.remove(event.id);
        _favoriteEvents.removeWhere((e) => e is POI ? e.eventID == event.id : false);
        notifyListeners();
      }
    }
  }

  // Réinitialiser la pagination (utile après filtrage ou changement de vue)
  void resetPagination() {
    _currentPage = 1;
    _events = [];
    _nativeEvents = [];
    _hasMoreEvents = true;
    notifyListeners();
  }
}