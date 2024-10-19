import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_popup/flutter_map_marker_popup.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:latlong2/latlong.dart';
import 'package:wazaa_app/services/event_service.dart';
import 'package:wazaa_app/models/poi.dart';
import 'package:wazaa_app/pages/event_page.dart';
import 'package:wazaa_app/widgets/map_datePicker.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:collection/collection.dart'; 
import 'package:intl/intl.dart';
import '../services/event_notifier.dart';
import './favorites_page.dart';
import './profile_page.dart';
import './faq_page.dart';
import './event_swiper_page.dart';
import './advanced_search_page.dart';
import 'dart:async';

class MapWithMarkersPage extends StatefulWidget {
  const MapWithMarkersPage({Key? key}) : super(key: key);

  @override
  _MapWithMarkersPageState createState() => _MapWithMarkersPageState();
}

class _MapWithMarkersPageState extends State<MapWithMarkersPage> with TickerProviderStateMixin {
  LatLng? _currentCenter;
  DateTimeRange? selectedDateRange;
  Timer? _debounce;
  Map<Marker, POI> _markerEventMap = {};
  POI? _selectedEvent;
  late EventNotifier eventNotifier;

  final MapController _mapController = MapController();
  final Completer<void> _mapReadyCompleter = Completer<void>();

  // Ajout des variables pour stocker les dates par défaut
  late String defaultStartDate;
  late String defaultEndDate;

  double currentZoom = 12.0; // Zoom par défaut
  
  // Utilisation de ValueNotifier pour réduire les rendus inutiles
  ValueNotifier<List<Marker>> _markers = ValueNotifier<List<Marker>>([]);
  ValueNotifier<List<POI>> visibleEvents = ValueNotifier<List<POI>>([]);
  ValueNotifier<List<POI>> filteredEvents = ValueNotifier<List<POI>>([]);
    // Variable pour gérer l'état du texte affiché du toggle (résultats ou filtres de dates)
  ValueNotifier<bool> showResults = ValueNotifier<bool>(true);
  late Timer _toggleTimer;  // Timer pour alterner l'affichage

  List<POI> events = [];
  String activeCategory = 'all';
  String _sortOrder = 'chronological'; // 'chronological' ou 'alphabetical'

  bool _isListViewVisible = false;
  bool _isLoading = false;  // Ajout pour éviter les appels multiples
  
  int _currentPage = 1;  // Page actuelle pour la pagination
  final int _pageLimit = 50;  // Limite des événements par page

  // Ajout de l'index de navigation pour la barre de navigation
  int _currentIndex = 0;

  final List<Map<String, dynamic>> categories = [
    {'id': 'all', 'label': 'Tous', 'icon': Icons.all_inclusive, 'keywords': []},
    {'id': 'art', 'label': 'Art', 'icon': Icons.palette, 'keywords': ['art', 'culture', 'exposition', 'musée', 'théâtre', 'cinéma', 'concert', 'spectacle']},
    {'id': 'family', 'label': 'Famille', 'icon': Icons.child_friendly, 'keywords': ['famille', 'enfant', 'parc', 'jeux', 'jouet', 'fête']},
    {'id': 'sports', 'label': 'Sport', 'icon': Icons.sports_soccer, 'keywords': ['sport', 'football', 'rugby', 'basket', 'tennis', 'vélo', 'compétition']},
    {'id': 'food', 'label': 'Food', 'icon': Icons.restaurant, 'keywords': ['food', 'cuisine', 'restaurant', 'gastronomie', 'repas', 'dégustation']},
    {'id': 'music', 'label': 'Musique', 'icon': Icons.music_note, 'keywords': ['musique', 'concert', 'festival', 'rock', 'pop', 'jazz']},
    {'id': 'nature', 'label': 'Nature', 'icon': Icons.nature, 'keywords': ['nature', 'jardin', 'plage', 'montagne', 'balade', 'randonnée']},
    {'id': 'professionnal', 'label': 'Pro', 'icon': Icons.business_center, 'keywords': ['pro', 'conférence', 'séminaire', 'business', 'networking']},
    {'id': 'tourism', 'label': 'Tourisme', 'icon': Icons.airplanemode_active, 'keywords': ['tourisme', 'voyage', 'patrimoine', 'visite', 'hôtel']},
  ];

  // Charge les événements filtrés et crée les marqueurs
  void _loadEventsFromNotifier() {
    final eventNotifier = Provider.of<EventNotifier>(context, listen: false);

    // Log pour vérifier si des événements sont récupérés
    print('Chargement des événements depuis le Notifier. Nombre d\'événements: ${eventNotifier.events.length}');
    
    events = eventNotifier.events; // Assigner les événements à la variable globale

    if (events.isEmpty) {
      print('Aucun événement récupéré.');
      return;
    }

    List<Marker> markers = [];

    List<POI> filteredByDateEvents = events.where((event) {
      DateTime eventStartDate = DateTime.parse(event.startDate);
      DateTime eventEndDate = DateTime.parse(event.endDate);

      // Utiliser les dates par défaut (J -> J+6)
      DateTime startDate = DateTime.parse(defaultStartDate);
      DateTime endDate = DateTime.parse(defaultEndDate);

      return eventStartDate.isBefore(endDate) && eventEndDate.isAfter(startDate);
    }).toList();

    for (var event in filteredByDateEvents) {
      if (event.location != null) {
        print('Création d\'un marker pour l\'événement : ${event.name} (ID: ${event.eventID}) '
              'à la localisation: ${event.location!.latitude}, ${event.location!.longitude}');

        Marker marker = Marker(
          point: LatLng(event.location!.latitude!, event.location!.longitude!),
          width: 40,
          height: 40,
          child: GestureDetector(
            onTap: () {
              print('Marker cliqué, événement associé: ${event.name}');
              _showEventPopup(event);  
            },
            child: const Icon(
              Icons.location_on,
              color: Colors.red,
              size: 40,
            ),
          ),
        );

        markers.add(marker);
        _markerEventMap[marker] = event;
      }
    }

    _markers.value = markers;
  }

  // Méthode pour afficher les détails d'un événement dans une popup
  void _showEventPopup(POI event) {
    // Déplacer la carte de manière fluide vers le marker
    animatedMapMove(
      LatLng(event.location!.latitude!, event.location!.longitude!), 
      currentZoom
    );

    setState(() {
      _selectedEvent = event;  // Met à jour l'événement sélectionné pour afficher la popup
    });
  }

  // Charge les événements sans filtrer par bounds une seule fois
  @override
  void initState() {
    super.initState();

    // Initialisation de eventNotifier
    eventNotifier = Provider.of<EventNotifier>(context, listen: false);
    
    // Initialisation des dates par défaut
    defaultStartDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
    defaultEndDate = DateFormat('yyyy-MM-dd').format(DateTime.now().add(Duration(days: 6)));

    // Charger les événements et démarrer le Timer une fois les événements chargés
    Future.microtask(() async {
      final eventNotifier = Provider.of<EventNotifier>(context, listen: false);

      // Vérification si les événements sont déjà chargés ou non
      print('Initialisation: événements dans le notifier = ${eventNotifier.events.length}');

      // Charger les événements asynchrones
      await eventNotifier.loadEventsIfNeeded();

      // Une fois les événements chargés, les ajouter sur la carte
      if (eventNotifier.events.isNotEmpty) {
        events = eventNotifier.events; // Assigner les événements à la variable globale

        // Appliquer les filtres par défaut pour mettre à jour filteredEvents.value
        _filterEvents(activeCategory); // activeCategory est initialisé à 'all'
      } else {
        print('Aucun événement n\'a été récupéré.');
      }

      // Démarrer le timer d'alterner après que les événements soient chargés
      _startToggleTimer();
    });

    // Écouter les changements de filteredEvents
    filteredEvents.addListener(() {
      _updateVisibleEvents();
    });
  }

  // Annule le timer lors de la destruction du widget
  @override
  void dispose() {
    _toggleTimer.cancel();
    super.dispose();
  }

  // Ajoutez une méthode pour initialiser et alterner l'affichage
  void _startToggleTimer() {
    _toggleTimer = Timer.periodic(Duration(seconds: 4), (timer) {
      showResults.value = !showResults.value;
    });
  }

  // Fonction debounce pour retarder les appels API
  void _debouncedUpdateMarkers() {
    if (_debounce?.isActive ?? false) {
      _debounce!.cancel();
    }

    _debounce = Timer(const Duration(milliseconds: 300), () {
      setState(() {
        _currentPage = 1;  // Réinitialiser la pagination lors de l'interaction avec la carte
      });
      _updateMarkers();  // Recharger les marqueurs avec la nouvelle pagination
    });
  }

  // Filtrer les événements par catégorie
  void _filterEvents(String category) {
    setState(() {
      _isLoading = true;  // Commence le chargement
      activeCategory = category;
      _currentPage = 1;  // Réinitialiser la pagination
    });

    Future.microtask(() {
      // Utiliser la plage de dates sélectionnée ou la plage par défaut
      DateTimeRange dateRange = selectedDateRange ??
          DateTimeRange(
            start: DateTime.parse(defaultStartDate), 
            end: DateTime.parse(defaultEndDate),
          );

      // Applique le filtre en fonction de la catégorie uniquement sur les événements filtrés par date
      List<String>? keywords = category == 'all'
          ? null
          : categories.firstWhere((cat) => cat['id'] == category)['keywords'];

      // Filtrage par dates
      List<POI> filteredByDateEvents = events.where((event) {
        DateTime eventStartDate = DateTime.parse(event.startDate);
        DateTime eventEndDate = DateTime.parse(event.endDate);

        bool isSponsored = eventNotifier.sponsoredEventIDs.contains(event.eventID);

        return (eventStartDate.isBefore(dateRange.end) && eventEndDate.isAfter(dateRange.start)) || isSponsored;
      }).toList();

      // Filtrage par catégorie
      filteredEvents.value = filteredByDateEvents.where((event) {
        bool matchesCategory = keywords == null || _matchesCategory(event, keywords);
        return matchesCategory;
      }).toList();

      // Logique de débogage pour vérifier le nombre d'événements filtrés
      print('${filteredEvents.value.length} événements après filtrage par catégorie "$category"');

      // Mise à jour des marqueurs avec les événements filtrés
      _loadMarkersFromEvents(filteredEvents.value);

      // Tri des événements après filtrage
      _sortEvents();

      // Fin du chargement
      setState(() {
        _isLoading = false;
      });
    });
  }

  // Animation de déplacement de la carte
  void animatedMapMove(LatLng destLocation, double destZoom) {
    // Récupérer la caméra actuelle (centre et zoom)
    final currentCamera = _mapController.camera;

    final latTween = Tween<double>(begin: currentCamera.center.latitude, end: destLocation.latitude);
    final lngTween = Tween<double>(begin: currentCamera.center.longitude, end: destLocation.longitude);
    final zoomTween = Tween<double>(begin: currentCamera.zoom, end: destZoom);

    final controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this, // Ceci nécessite que la classe implémente TickerProviderStateMixin
    );

    Animation<double> animation = CurvedAnimation(parent: controller, curve: Curves.easeInOut);

    controller.addListener(() {
      _mapController.move(
        LatLng(latTween.evaluate(animation), lngTween.evaluate(animation)),
        zoomTween.evaluate(animation),
      );
    });

    animation.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        controller.dispose();
      }
    });

    controller.forward();
  }

  // Vérifie si un événement correspond aux mots-clés de la catégorie
  bool _matchesCategory(POI event, List<String>? keywords) {
    if (keywords == null || keywords.isEmpty) return true;

    final lowerCaseName = event.name.toLowerCase();
    final lowerCaseDescription = (event.description ?? '').toLowerCase();
    final lowerCaseTags = event.tags?.map((tag) => tag.toLowerCase()).toList() ?? [];

    // Ajoute un print pour vérifier les correspondances
    print('Vérification des mots-clés pour l\'événement: ${event.name}');
    
    bool match = keywords.any((keyword) =>
        lowerCaseName.contains(keyword) ||
        lowerCaseDescription.contains(keyword) ||
        lowerCaseTags.any((tag) => tag.contains(keyword)));
    
    print('Correspondance: $match');
    return match;
  }

  // Vérifie si un événement est dans la plage de dates sélectionnée
  bool _isWithinSelectedDateRange(POI event) {
    if (selectedDateRange == null) {
      // Si aucune plage de dates n'est sélectionnée, considérer l'événement valide
      return true;
    }

    DateTime eventStartDate = DateTime.parse(event.startDate);
    DateTime eventEndDate = DateTime.parse(event.endDate);

    // Vérifie si l'événement commence avant la fin de la plage sélectionnée
    // et s'il finit après le début de la plage sélectionnée
    return eventStartDate.isBefore(selectedDateRange!.end) && eventEndDate.isAfter(selectedDateRange!.start);
  }

  // Mise à jour des marqueurs en fonction de la position de la carte
  Future<void> _updateMarkers() async {
    // Utiliser les événements filtrés par date et catégorie
    if (filteredEvents.value.isNotEmpty) {
      _loadMarkersFromEvents(filteredEvents.value);
    }
  }

  // Fonction pour charger les marqueurs depuis les événements filtrés
  void _loadMarkersFromEvents(List<POI> events) {
    // Vider le mappeur de marqueurs à événements
    _markerEventMap.clear();

    // Réinitialiser les marqueurs à une liste vide
    List<Marker> markers = [];

    for (var event in events) {
      if (event.location != null) {
        Marker marker = Marker(
          point: LatLng(event.location!.latitude!, event.location!.longitude!),
          width: 40,
          height: 40,
          child: GestureDetector(
            onTap: () {
              _showEventPopup(event);
            },
            child: const Icon(
              Icons.location_on,
              color: Colors.red,
              size: 40,
            ),
          ),
        );

        // Associer chaque marker à un événement
        _markerEventMap[marker] = event;
        markers.add(marker);

        // Log pour vérifier l'association correcte
        //print('Association : marker point ${marker.point} <-> événement ${event.name}');
      }
    }

    // Mettre à jour les marqueurs visibles sur la carte
    _markers.value = markers;
  }

  // Afficher la popup de sélection de date
  void _showCustomDatePicker() async {
    final result = await showDialog<DateTimeRange>(
      context: context,
      builder: (BuildContext context) {
        return CustomDateRangePicker();
      },
    );

    if (result != null) {
      setState(() {
        selectedDateRange = result;
        _filterEventsByDateRange(selectedDateRange);
      });
    }
  }

  // Filtrer les événements par plage de dates
  void _filterEventsByDateRange(DateTimeRange? dateRange) {
    if (dateRange == null) return;

    print('Filtrage des événements pour la plage de dates : du ${dateRange.start} au ${dateRange.end}');

    // Si aucun événement n'est disponible, arrêter le filtrage
    if (events.isEmpty) {
      print('Aucun événement disponible à filtrer.');
      return;
    }

    setState(() {
      // Réinitialiser la liste des événements filtrés par dates uniquement
      List<POI> filteredByDateEvents = events.where((event) {
        DateTime eventStartDate = DateTime.parse(event.startDate);
        DateTime eventEndDate = DateTime.parse(event.endDate);

        bool isWithinRange = eventStartDate.isBefore(dateRange.end) && eventEndDate.isAfter(dateRange.start);

        if (isWithinRange) {
          print('Événement ${event.name} est dans la plage sélectionnée.');
        } else {
          print('Événement ${event.name} est hors de la plage sélectionnée.');
        }

        return isWithinRange;
      }).toList();

      // Appliquer ensuite le filtre de catégorie actif sur les événements déjà filtrés par dates
      _filterEvents(activeCategory);  // Réutiliser la méthode _filterEvents pour réappliquer les catégories
    });
  }

  // Méthode pour trier les événements par ordre alphabétique ou chronologique
  void _sortEvents() {
    List<POI> events = filteredEvents.value;

    // Séparer les événements sponsorisés et non sponsorisés
    List<POI> sponsoredEvents = events.where((event) => eventNotifier.sponsoredEventIDs.contains(event.eventID)).toList();
    List<POI> nonSponsoredEvents = events.where((event) => !eventNotifier.sponsoredEventIDs.contains(event.eventID)).toList();

    // Trier chaque liste individuellement
    if (_sortOrder == 'chronological') {
      sponsoredEvents.sort((a, b) => DateTime.parse(a.startDate).compareTo(DateTime.parse(b.startDate)));
      nonSponsoredEvents.sort((a, b) => DateTime.parse(a.startDate).compareTo(DateTime.parse(b.startDate)));
    } else {
      sponsoredEvents.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      nonSponsoredEvents.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    }

    // Combiner les listes en gardant les sponsorisés en premier
    filteredEvents.value = sponsoredEvents + nonSponsoredEvents;
  }

  // Méthode pour mettre à jour les événements visibles sur la carte
  void _updateVisibleEvents() async {
    await _mapReadyCompleter.future; // Attendre que la carte soit prête
    final bounds = _mapController.camera.visibleBounds;
    if (bounds != null) {
      List<POI> eventsInView = filteredEvents.value.where((event) {
        if (event.location != null) {
          double lat = event.location!.latitude!;
          double lng = event.location!.longitude!;
          return bounds.contains(LatLng(lat, lng));
        }
        return false;
      }).toList();

      visibleEvents.value = eventsInView;
    } else {
      visibleEvents.value = [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Si la vue liste est visible, la fermer et ne pas quitter l'application
        if (_isListViewVisible) {
          setState(() {
            _isListViewVisible = false;  // Masque la vue liste
          });
          return false;  // Ne pas quitter l'application
        }

        bool shouldExit = await showDialog(
          context: context,
          builder: (context) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    decoration: const BoxDecoration(
                      gradient: RadialGradient(
                        center: Alignment.center,
                        radius: 1.2,
                        colors: [
                          Color(0xFF205893),  // Couleur principale bleue
                          Color(0xFF16141E),  // Couleur de fond sombre
                        ],
                      ),
                      borderRadius: BorderRadius.all(Radius.circular(20)),
                    ),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "Quitter WAZAA ?",
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Sora',
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "Voulez-vous vraiment quitter l'application ?",
                          style: TextStyle(
                            fontSize: 16,
                            fontFamily: 'Poppins',
                            color: Colors.white70,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            TextButton(
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 30,
                                  vertical: 12,
                                ),
                                backgroundColor: Colors.white.withOpacity(0.2),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              onPressed: () => Navigator.of(context).pop(true),
                              child: Text(
                                'Oui',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                            ),
                            TextButton(
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 30,
                                  vertical: 12,
                                ),
                                backgroundColor: Colors.white.withOpacity(0.3),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              onPressed: () => Navigator.of(context).pop(false),
                              child: Text(
                                'Non',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
        return shouldExit ?? false;
      },
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            // Ajout de PopupScope autour de FlutterMap pour gérer l'état des popups
            PopupScope(
              child: FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: LatLng(43.4833, -1.4833),
                  initialZoom: currentZoom,  // Utilisation du zoom initial
                  onPositionChanged: (MapCamera position, bool hasGesture) {
                    if (position.zoom != null) {
                      setState(() {
                        currentZoom = position.zoom;  // Met à jour le zoom actuel
                      });
                    }
                    _updateMarkers(); 
                    _updateVisibleEvents(); 
                  },
                  onTap: (_, __) {
                    setState(() {
                      _selectedEvent = null;  // Fermer la popup lorsqu'on clique en dehors
                    });
                  },
                  onMapReady: () {
                    _mapReadyCompleter.complete();
                  },
                ),
                children: [
                  TileLayer(
                    urlTemplate: "https://api.mapbox.com/styles/v1/hervemake/clu1zgvkj00p601qsgono9buy/tiles/{z}/{x}/{y}?access_token={accessToken}",
                    additionalOptions: {
                      'accessToken': 'sk.eyJ1IjoiaGVydmVtYWtlIiwiYSI6ImNtMTUzeHBudjA1c3YydnM4NWozYmk3a2YifQ.8DsYqi5sX_-G7__icEAmjA',
                    },
                  ),
                  // Ajout du clustering des marqueurs avec la gestion des popups
                  ValueListenableBuilder<List<Marker>>(
                    valueListenable: _markers,
                    builder: (context, markers, child) {
                      return MarkerClusterLayerWidget(
                        options: MarkerClusterLayerOptions(
                          markers: markers,
                          zoomToBoundsOnClick: true,  // Zoomer sur le cluster lorsqu'on clique
                          animationsOptions: const AnimationsOptions(
                            zoom: Duration(milliseconds: 500),  // Durée de l'animation de zoom
                            centerMarker: Duration(milliseconds: 500),  // Durée de l'animation pour centrer le marqueur
                          ),
                          showPolygon: false,  // Désactiver les polygones de groupe
                          maxClusterRadius: 50,  // Rayon de clustering
                          size: const Size(40, 40),  // Taille des clusters
                          builder: (context, markers) {
                            return Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                color: Colors.blue.withOpacity(0.7),
                              ),
                              child: Center(
                                child: Text(
                                  markers.length.toString(),
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                            );
                          },
                          popupOptions: PopupOptions(
                            popupController: PopupController(),
                            popupBuilder: (context, marker) {
                              final POI? event = _markerEventMap[marker];
                              if (event != null) {
                                return _buildPopup(event, context);
                              } else {
                                return const SizedBox.shrink();
                              }
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            // Tous les autres éléments de l'interface
            Column(
              children: [
                // Header ou barre de navigation ou tout autre contenu de votre choix
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.only(left: 20, right: 20, top: 40, bottom: 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Icône de recherche
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              spreadRadius: 2,
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: IconButton(
                          iconSize: 23,
                          icon: const Icon(Icons.question_answer, color: Colors.black),
                          tooltip: 'Aide / FAQ',
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => FAQPage()),
                            );
                          },
                        ),
                      ),
                      const Text(
                        'WAZAA',
                        style: TextStyle(
                          fontFamily: 'Sora',
                          fontSize: 30,
                          fontWeight: FontWeight.w900,
                          color: Colors.black,
                        ),
                      ),
                      // Bouton d'ajout d'événements
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [Colors.blue, Colors.purple],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              spreadRadius: 3,
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: IconButton(
                          iconSize: 25,
                          icon: const Icon(Icons.add, color: Colors.white),
                          onPressed: () {
                            // Logique pour ajouter un événement
                            showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return Dialog(
                                  insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40), // Ajout d'espacement par rapport aux bords
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30), // Bords très arrondis pour un effet moderne
                                  ),
                                  child: Stack(
                                    clipBehavior: Clip.none, // Permet à l'icône de dépasser de la boîte de dialogue
                                    children: [
                                      // Boîte de dialogue principale
                                      Container(
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.85), // Couleur légèrement transparente pour l'effet "glassmorphism"
                                          borderRadius: BorderRadius.circular(30),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(0.15),
                                              blurRadius: 20,
                                              spreadRadius: 5,
                                            ),
                                          ],
                                        ),
                                        padding: const EdgeInsets.all(20),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const SizedBox(height: 60), // Espace réservé à l'icône en haut

                                            // Titre de la modale
                                            const Text(
                                              "Bientôt disponible !",
                                              style: TextStyle(
                                                fontFamily: 'Sora',
                                                fontSize: 24,
                                                fontWeight: FontWeight.w900,
                                                color: Colors.black87,
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                            const SizedBox(height: 15),

                                            // Contenu
                                            const Text(
                                              "Il sera bientôt possible de créer vos propres événements.\n\n"
                                              "En attendant, contactez-nous si vous souhaitez ajouter un événement via la page contact ou par email : contact@wazaa.app.",
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontFamily: 'Poppins',
                                                color: Colors.black54,
                                                height: 1.5,
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                            const SizedBox(height: 25),

                                            // Bouton avec effet de gradient animé
                                            TextButton(
                                              style: TextButton.styleFrom(
                                                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                                                backgroundColor: Colors.transparent, // Pas de couleur, géré par le gradient
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(50),
                                                ),
                                              ),
                                              onPressed: () {
                                                Navigator.of(context).pop(); // Ferme la boîte de dialogue
                                              },
                                              child: Ink(
                                                decoration: BoxDecoration(
                                                  gradient: const LinearGradient(
                                                    colors: [Color(0xFF6DD5FA), Color(0xFF2980B9)],
                                                    begin: Alignment.topLeft,
                                                    end: Alignment.bottomRight,
                                                  ),
                                                  borderRadius: BorderRadius.circular(50),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: Colors.blue.withOpacity(0.3),
                                                      blurRadius: 10,
                                                      offset: Offset(0, 5), // Ombre douce sous le bouton
                                                    ),
                                                  ],
                                                ),
                                                child: Container(
                                                  alignment: Alignment.center,
                                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                                  child: const Text(
                                                    "OK !",
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 18,
                                                      fontWeight: FontWeight.w700,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),

                                      // Icône flottante
                                      Positioned(
                                        top: -40, // Positionner l'icône au-dessus de la boîte de dialogue
                                        left: 0,
                                        right: 0,
                                        child: CircleAvatar(
                                          backgroundColor: Colors.blueAccent,
                                          radius: 40,
                                          child: const Icon(
                                            Icons.info_outline,
                                            color: Colors.white,
                                            size: 40,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                // Barre de navigation thématique avec fond blanc
                Container(
                  color: Colors.white, // Fond blanc pour la barre thématique
                  height: 65,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: categories.map((category) {
                        return GestureDetector(
                          onTap: () => _filterEvents(category['id']),
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 10),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: activeCategory == category['id'] ? Colors.black : Colors.white,
                              borderRadius: BorderRadius.circular(50),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  spreadRadius: 1,
                                  blurRadius: 5,
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  category['icon'],
                                  color: activeCategory == category['id'] ? Colors.white : Colors.black,
                                  size: 18,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  category['label'],
                                  style: TextStyle(
                                    color: activeCategory == category['id'] ? Colors.white : Colors.black,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),

            // Bouton flottant pour afficher le nombre de résultats ou la plage de dates
          Positioned(
            bottom: 90, // Positionnement au-dessus de la barre de navigation
            left: 0,
            right: 0,
            child: Center(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _isListViewVisible = !_isListViewVisible;
                  });
                },
                child: Container(
                  // Adapte la largeur à l'espace disponible
                  width: MediaQuery.of(context).size.width * 0.35, // Largeur du bouton
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(50),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 6,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    child: ValueListenableBuilder<bool>(
                      valueListenable: showResults,
                      builder: (context, showResultsValue, child) {
                        return Center(
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 500),
                            transitionBuilder: (Widget child, Animation<double> animation) {
                              return FadeTransition(opacity: animation, child: child);
                            },
                            child: showResultsValue
                                ? ValueListenableBuilder<List<POI>>(
                                    key: ValueKey('results'),
                                    valueListenable: visibleEvents,
                                    builder: (context, events, child) {
                                      return Text(
                                        "${events.length} Résultats",
                                        style: const TextStyle(
                                          color: Colors.black,
                                          fontSize: 12,
                                          fontFamily: "Poppins",
                                          fontWeight: FontWeight.w500,
                                        ),
                                      );
                                    },
                                  )
                                : Wrap( // Utilise Wrap pour éviter les débordements
                                    key: ValueKey('dates'),
                                    alignment: WrapAlignment.center, // Centrer les éléments
                                    children: [
                                      Text(
                                        "Afficher la liste",
                                        style: const TextStyle(
                                          color: Colors.black,
                                          fontSize: 12,
                                          fontFamily: "Poppins",
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),

            // Bouton FAQ flottant
            Positioned(
              right: 10,
              bottom: 90, // Ajustement de l'espacement par rapport à la barre de navigation
              child: SizedBox(
                width: 50,  // Largeur personnalisée
                height: 50, // Hauteur personnalisée
                child: FloatingActionButton(
                  backgroundColor: Colors.white,
                  onPressed: _showCustomDatePicker,
                  child: const Icon(Icons.calendar_month, color: Colors.black, size: 27),
                  elevation: 4,  // Diminuer l'ombre en ajustant l'élévation
                  shape: const CircleBorder(),  // Forme de cercle
                ),
              ),
            ),

            // Popup de l'événement en bas de l'écran
            if (_selectedEvent != null) _buildPopup(_selectedEvent!, context),

            // La BottomNavigationBar par-dessus la carte
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: SafeArea( // Utilisation de SafeArea pour éviter les débordements en bas de l'écran
                child: Container(
                  //height: 75, // Hauteur ajustée pour éviter l'overflow
                  padding: const EdgeInsets.only(left: 10, right: 10, bottom: 10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(50),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        spreadRadius: 2,
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(25),
                    child: BottomNavigationBar(
                      backgroundColor: Colors.white.withOpacity(1), // Barre entièrement opaque
                      elevation: 3,
                      currentIndex: _currentIndex,
                      onTap: (index) {
                        setState(() {
                          _currentIndex = index;
                          // Gérer la navigation et garder la BottomNavigationBar visible sur la page Favoris
                          if (index == 0) {
                            // Naviguer vers la page Globe
                          } else if (index == 1) {
                            // Naviguer vers la page Recherche
                            Navigator.push(
                              context,
                              PageRouteBuilder(
                                pageBuilder: (context, animation1, animation2) => AdvancedSearchPage(),
                                transitionDuration: Duration.zero, // Pas de durée pour la transition
                                reverseTransitionDuration: Duration.zero, // Pas de durée pour la transition inverse
                              ),
                            );
                          } else if (index == 2) {
                            // Naviguer vers la page Tinder-like
                            Navigator.push(
                              context,
                              PageRouteBuilder(
                                pageBuilder: (context, animation1, animation2) => EventSwiperPage(),
                                transitionDuration: Duration.zero, // Pas de durée pour la transition
                                reverseTransitionDuration: Duration.zero, // Pas de durée pour la transition inverse
                              ),
                            );
                          } else if (index == 3) {
                          Navigator.push(
                            context,
                            PageRouteBuilder(
                              pageBuilder: (context, animation1, animation2) => FavoritesPage(),
                              transitionDuration: Duration.zero, // Pas de durée pour la transition
                              reverseTransitionDuration: Duration.zero, // Pas de durée pour la transition inverse
                            ),
                          );
                          } else if (index == 4) {
                          Navigator.push(
                            context,
                            PageRouteBuilder(
                              pageBuilder: (context, animation1, animation2) => ProfilePage(),
                              transitionDuration: Duration.zero, // Pas de durée pour la transition
                              reverseTransitionDuration: Duration.zero, // Pas de durée pour la transition inverse
                              ),
                            );
                          };
                        });
                      },
                      selectedItemColor: Colors.blueAccent,
                      unselectedItemColor: Colors.black,
                      showSelectedLabels: false, // Masquer les labels sélectionnés
                      showUnselectedLabels: false, // Masquer les labels non sélectionnés
                      type: BottomNavigationBarType.fixed, 
                      items: [
                        BottomNavigationBarItem(
                          icon: ShaderMask(
                            shaderCallback: (Rect bounds) {
                              return LinearGradient(
                                colors: _currentIndex == 0
                                    ? [
                                        Color(0xFFA222F5),
                                        Color(0xFF9B3EF7),
                                        Color(0xFF7D6EF9),
                                        Color(0xFF14A3F2),
                                      ]
                                    : [Colors.black, Colors.black],
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                              ).createShader(bounds);
                            },
                            child: Icon(
                              Icons.language,
                              color: _currentIndex == 0 ? Colors.white : Colors.black,
                            ),
                          ),
                          label: '',
                        ),
                        BottomNavigationBarItem(
                          icon: ShaderMask(
                            shaderCallback: (Rect bounds) {
                              return LinearGradient(
                                colors: _currentIndex == 1
                                    ? [
                                        Color(0xFFA222F5),
                                        Color(0xFF9B3EF7),
                                        Color(0xFF7D6EF9),
                                        Color(0xFF14A3F2),
                                      ]
                                    : [Colors.black, Colors.black],
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                              ).createShader(bounds);
                            },
                            child: Icon(
                              Icons.search,
                              color: _currentIndex == 1 ? Colors.white : Colors.black,
                            ),
                          ),
                          label: '', 
                        ),
                        BottomNavigationBarItem(
                          icon: ShaderMask(
                            shaderCallback: (Rect bounds) {
                              return LinearGradient(
                                colors: _currentIndex == 2
                                    ? [
                                        Color(0xFFA222F5),
                                        Color(0xFF9B3EF7),
                                        Color(0xFF7D6EF9),
                                        Color(0xFF14A3F2),
                                      ]
                                    : [Colors.black, Colors.black],
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                              ).createShader(bounds);
                            },
                            child: Icon(
                              Icons.swipe,
                              color: _currentIndex == 2 ? Colors.white : Colors.black,
                            ),
                          ),
                          label: '', 
                        ),
                        BottomNavigationBarItem(
                          icon: ShaderMask(
                            shaderCallback: (Rect bounds) {
                              return LinearGradient(
                                colors: _currentIndex == 3
                                    ? [
                                        Color(0xFFA222F5),
                                        Color(0xFF9B3EF7),
                                        Color(0xFF7D6EF9),
                                        Color(0xFF14A3F2),
                                      ]
                                    : [Colors.black, Colors.black],
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                              ).createShader(bounds);
                            },
                            child: Icon(
                              Icons.favorite,
                              color: _currentIndex == 3 ? Colors.white : Colors.black,
                            ),
                          ),
                          label: '', 
                        ),
                        BottomNavigationBarItem(
                          icon: ShaderMask(
                            shaderCallback: (Rect bounds) {
                              return LinearGradient(
                                colors: _currentIndex == 4
                                    ? [
                                        Color(0xFFA222F5),
                                        Color(0xFF9B3EF7),
                                        Color(0xFF7D6EF9),
                                        Color(0xFF14A3F2),
                                      ]
                                    : [Colors.black, Colors.black],
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                              ).createShader(bounds);
                            },
                            child: Icon(
                              Icons.person,
                              color: _currentIndex == 4 ? Colors.white : Colors.black,
                            ),
                          ),
                          label: '', 
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Vue liste des événements
            AnimatedPositioned(
              duration: const Duration(milliseconds: 500), // Durée d'animation plus longue pour plus de fluidité
              curve: Curves.easeInOut, // Utilisation d'une courbe pour lisser l'animation
              bottom: _isListViewVisible ? 0 : -MediaQuery.of(context).size.height,
              left: 0,
              right: 0,
              child: Container(
                height: MediaQuery.of(context).size.height,
                color: Colors.white,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Bouton de fermeture et titre
                    Padding(
                      padding: const EdgeInsets.only(top: 50, left: 16, right: 16),
                      child: Stack(
                        children: [
                          // Bouton de fermeture aligné à gauche
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 5,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: IconButton(
                                icon: const Icon(Icons.keyboard_arrow_down),
                                iconSize: 30,
                                onPressed: () {
                                  setState(() {
                                    _isListViewVisible = false;
                                  });
                                },
                                color: Colors.black,
                              ),
                            ),
                          ),
                          // Titre centré
                          Align(
                            alignment: Alignment.center,
                            child: ValueListenableBuilder<List<POI>>(
                              valueListenable: visibleEvents,
                              builder: (context, events, child) {
                                return Text(
                                  '${events.length} événements',
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'Sora',
                                  ),
                                  textAlign: TextAlign.center,
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Sous-titre (plage de dates active)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Center(
                        child: Text(
                          selectedDateRange != null
                              ? 'Du ${DateFormat('dd/MM/yyyy').format(selectedDateRange!.start)} au ${DateFormat('dd/MM/yyyy').format(selectedDateRange!.end)}'
                              : 'Du ${DateFormat('dd/MM/yyyy').format(DateTime.now())} au ${DateFormat('dd/MM/yyyy').format(DateTime.now().add(Duration(days: 6)))}',
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.grey[600],
                            fontFamily: 'Poppins',
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    // Barre de sélection des thématiques
                    Container(
                      height: 65,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: categories.map((category) {
                            return GestureDetector(
                              onTap: () => _filterEvents(category['id']),
                              child: Container(
                                margin: const EdgeInsets.symmetric(horizontal: 10),
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: activeCategory == category['id'] ? Colors.black : Colors.white,
                                  borderRadius: BorderRadius.circular(50),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      spreadRadius: 1,
                                      blurRadius: 5,
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      category['icon'],
                                      color: activeCategory == category['id'] ? Colors.white : Colors.black,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      category['label'],
                                      style: TextStyle(
                                        color: activeCategory == category['id'] ? Colors.white : Colors.black,
                                        fontWeight: FontWeight.w400,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                    // Bouton "Trier par"
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Row(
                        children: [
                          const Text(
                            'Trier par :',
                            style: TextStyle(fontSize: 15, fontFamily: 'Poppins'),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                if (_sortOrder == 'chronological') {
                                  _sortOrder = 'alphabetical';
                                } else {
                                  _sortOrder = 'chronological';
                                }
                                _sortEvents();
                              });
                            },
                            child: Row(
                              children: [
                                Text(
                                  _sortOrder == 'chronological' ? 'Date' : 'A-Z',
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'Poppins',
                                  ),
                                ),
                                const Icon(
                                  Icons.sort,
                                  color: Colors.black,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Liste des événements
                    Expanded(
                      child: ValueListenableBuilder<List<POI>>(
                        valueListenable: visibleEvents,
                        builder: (context, events, child) {
                          // Utiliser events comme source de données
                          List<POI> eventsList = List<POI>.from(events);

                          // Séparer les événements sponsorisés et non sponsorisés
                          List<POI> sponsoredEvents = eventsList.where((event) => eventNotifier.sponsoredEventIDs.contains(event.eventID)).toList();
                          List<POI> nonSponsoredEvents = eventsList.where((event) => !eventNotifier.sponsoredEventIDs.contains(event.eventID)).toList();

                          // Sélectionner aléatoirement un événement sponsorisé
                          POI? selectedSponsoredEvent;
                          if (sponsoredEvents.isNotEmpty) {
                            sponsoredEvents.shuffle();
                            selectedSponsoredEvent = sponsoredEvents.first;
                          }

                          // Enlever tous les événements sponsorisés de la liste des événements
                          eventsList = nonSponsoredEvents;

                          // Créer la liste finale des événements à afficher
                          List<POI> finalEventsList = [];
                          if (selectedSponsoredEvent != null) {
                            finalEventsList.add(selectedSponsoredEvent);
                          }
                          finalEventsList.addAll(eventsList);

                          return ListView.builder(
                            itemCount: finalEventsList.length,
                            itemBuilder: (context, index) {
                              POI event = finalEventsList[index];

                              // Déterminer si l'événement est le sponsorisé sélectionné
                              bool isSponsored = (index == 0 && selectedSponsoredEvent != null);

                              // Widget de l'événement avec style amélioré
                              return InkWell(
                                onTap: () {
                                  // Naviguer vers la page de détails de l'événement
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => EventPage(event: event),
                                    ),
                                  );
                                },
                                splashColor: Colors.blueAccent.withOpacity(0.3),
                                highlightColor: Colors.blueAccent.withOpacity(0.1),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 10.0),
                                  child: Container(
                                    height: 150,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(20),
                                      color: Colors.white, // Supprime le dégradé ici
                                      border: Border.all(color: Colors.grey.withOpacity(0.5), width: 0.5),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.2),
                                          blurRadius: 10,
                                          spreadRadius: 2,
                                          offset: const Offset(0, 5),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      children: [
                                        // Image de l'événement
                                        ClipRRect(
                                          borderRadius: const BorderRadius.only(
                                            topLeft: Radius.circular(20),
                                            bottomLeft: Radius.circular(20),
                                          ),
                                          child: event.photoUrl != null && event.photoUrl!.isNotEmpty
                                              ? Image.network(
                                                  event.photoUrl!,
                                                  width: MediaQuery.of(context).size.width * 0.35,
                                                  height: double.infinity,
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (context, error, stackTrace) {
                                                    return Image.asset(
                                                      'lib/assets/images/default_event_poster.png', // Image par défaut en cas d'erreur de chargement
                                                      width: MediaQuery.of(context).size.width * 0.35,
                                                      height: double.infinity,
                                                      fit: BoxFit.cover,
                                                    );
                                                  },
                                                )
                                              : Image.asset(
                                                  'lib/assets/images/default_event_poster.png', // Image par défaut
                                                  width: MediaQuery.of(context).size.width * 0.35,
                                                  height: double.infinity,
                                                  fit: BoxFit.cover,
                                                ),
                                        ),
                                        // Conteneur texte avec dégradé
                                        Expanded(
                                          child: Container(
                                            decoration: BoxDecoration(
                                            gradient: isSponsored
                                                ? const LinearGradient(
                                                    colors: [
                                                      Color(0xFFA222F5), // Violet foncé (point de départ)
                                                      Color(0xFF9B3EF7), // Première couleur intermédiaire plus claire
                                                      Color(0xFF7D6EF9), // Deuxième couleur intermédiaire pour adoucir encore
                                                      Color(0xFF14A3F2), // Bleu clair (point final)
                                                    ],
                                                    begin: Alignment.bottomCenter,
                                                    end: Alignment.topCenter,
                                                    stops: [0.0, 0.25, 0.5, 1.0], // Ajout de plusieurs stops pour une transition douce
                                                  )
                                                : null,
                                              borderRadius: const BorderRadius.only(
                                                topRight: Radius.circular(20),
                                                bottomRight: Radius.circular(20),
                                              ),
                                            ),
                                            child: Padding(
                                              padding: const EdgeInsets.all(16),
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  // Titre de l'événement avec badge sponsorisé si applicable
                                                  Row(
                                                    children: [
                                                      Expanded(
                                                        child: Text(
                                                          event.name,
                                                          style: TextStyle(
                                                            fontWeight: FontWeight.bold,
                                                            fontFamily: 'Sora',
                                                            fontSize: 18,
                                                            color: isSponsored ? Colors.white : Color(0xFF333333),
                                                          ),
                                                          maxLines: 1,
                                                          overflow: TextOverflow.ellipsis,
                                                        ),
                                                      ),
                                                      if (isSponsored) ...[
                                                        const SizedBox(width: 8),
                                                        Flexible(
                                                          child: Container(
                                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                            decoration: BoxDecoration(
                                                              color: Colors.white.withOpacity(0.8), // Couleur du badge "Sponsorisé"
                                                              borderRadius: BorderRadius.circular(8),
                                                            ),
                                                            child: const Text(
                                                              'Sponsorisé',
                                                              style: TextStyle(color: Colors.black, fontSize: 11, fontFamily: 'Poppins'),
                                                              overflow: TextOverflow.ellipsis,
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ],
                                                  ),
                                                  const SizedBox(height: 12),
                                                  // Description de l'événement
                                                  Text(
                                                    event.description != null
                                                        ? event.description!.length > 80
                                                            ? event.description!.substring(0, 80) + '...'
                                                            : event.description!
                                                        : 'Description non disponible',
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                      color: isSponsored ? Colors.white70 : Color(0xFF888888),
                                                      fontStyle: FontStyle.italic,
                                                    ),
                                                    maxLines: 2,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                  const SizedBox(height: 12),
                                                  // Emplacement et date
                                                  Row(
                                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                    children: [
                                                      Flexible(
                                                        child: Row(
                                                          children: [
                                                            Icon(Icons.location_on, size: 16, color: isSponsored ? Colors.white : Color(0xFF666666)),
                                                            const SizedBox(width: 4),
                                                            Flexible(
                                                              child: Text(
                                                                event.location?.city ?? 'Ville non spécifiée',
                                                                style: TextStyle(
                                                                  fontSize: 14,
                                                                  color: isSponsored ? Colors.white : Color(0xFF666666),
                                                                ),
                                                                maxLines: 1,
                                                                overflow: TextOverflow.ellipsis,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                      const SizedBox(width: 8),
                                                      Flexible(
                                                        child: Text(
                                                          event.endDate != event.startDate
                                                              ? 'Du ${DateFormat('dd/MM').format(DateTime.parse(event.startDate))} au ${DateFormat('dd/MM').format(DateTime.parse(event.endDate))}'
                                                              : DateFormat('dd/MM').format(DateTime.parse(event.startDate)),
                                                          style: TextStyle(
                                                            fontSize: 14,
                                                            color: isSponsored ? Colors.white : Color(0xFF666666),
                                                            letterSpacing: -1.2,
                                                          ),
                                                          maxLines: 1,
                                                          overflow: TextOverflow.ellipsis,
                                                          textAlign: TextAlign.right,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPopup(POI event, BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EventPage(event: event),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.only(bottom: 85, left: 10, right: 10),
          child: AnimatedScale(
            scale: _selectedEvent == event ? 1.0 : 0.95,
            duration: const Duration(milliseconds: 400),
            curve: Curves.elasticOut, // Ajout d'une courbe élastique pour l'effet "popping"
            child: AnimatedOpacity(
              opacity: _selectedEvent == event ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 300),
              child: AnimatedSlide(
                offset: _selectedEvent == event ? Offset(0, 0) : Offset(0, 0.5),
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeInOut,
                child: Container(
                  height: 150,
                  width: MediaQuery.of(context).size.width * 0.95,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: Colors.white,
                    border: Border.all(color: Colors.grey.withOpacity(0.5), width: 0.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 20,
                        spreadRadius: 2,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // Image de l'événement
                      ClipRRect(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(20),
                          bottomLeft: Radius.circular(20),
                        ),
                        child: event.photoUrl != null && event.photoUrl!.isNotEmpty
                            ? Image.network(
                                event.photoUrl!,
                                width: MediaQuery.of(context).size.width * 0.35,
                                height: double.infinity,
                                fit: BoxFit.cover,
                              )
                            : Image.asset(
                                'lib/assets/images/default_event_poster.png',
                                width: MediaQuery.of(context).size.width * 0.35,
                                height: double.infinity,
                                fit: BoxFit.cover,
                              ),
                      ),
                      // Détails de l'événement
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                event.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Sora',
                                  fontSize: 18,
                                  color: Color(0xFF333333),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 12),

                              Text(
                                event.description != null
                                    ? event.description!.length > 80
                                        ? event.description!.substring(0, 80) + '...'
                                        : event.description!
                                    : 'Description non disponible',
                                style: const TextStyle(fontSize: 14, color: Color(0xFF888888), fontStyle: FontStyle.italic),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 12),

                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Flexible(
                                    child: Row(
                                      children: [
                                        const Icon(Icons.location_on, size: 16, color: Color(0xFF666666)),
                                        const SizedBox(width: 4),
                                        Flexible(
                                          child: Text(
                                            event.location?.city ?? 'Ville non spécifiée',
                                            style: const TextStyle(fontSize: 14, color: Color(0xFF666666)),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis, 
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: Text(
                                      event.endDate != event.startDate
                                          ? 'Du ${DateFormat('dd/MM').format(DateTime.parse(event.startDate))} au ${DateFormat('dd/MM').format(DateTime.parse(event.endDate))}'
                                          : DateFormat('dd/MM').format(DateTime.parse(event.startDate)),
                                      style: const TextStyle(fontSize: 14, color: Color(0xFF666666), letterSpacing: -1.2),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      textAlign: TextAlign.right,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}