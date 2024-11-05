import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:wazaa_app/models/poi.dart';
import 'package:wazaa_app/services/event_notifier.dart';
import './event_page.dart';

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({Key? key}) : super(key: key);

  @override
  _FavoritesPageState createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  // Toggle state: 'true' for upcoming events, 'false' for past events
  bool showUpcoming = true;

  // Sorting state: true for alphabetical (A-Z), false for chronological (default is false for date sorting)
  bool sortAlphabetically = false;

  // State to determine whether sorting is ascending or descending
  bool sortAscending = true; // Set default to true (show nearest first)

  @override
  void initState() {
    super.initState();
    // Charger les favoris lorsque la page est initialisée
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<EventNotifier>(context, listen: false).loadFavorites();
    });
  }

  @override
  Widget build(BuildContext context) {
    final eventNotifier = Provider.of<EventNotifier>(context);
    final favoriteEvents = Provider.of<EventNotifier>(context).favoriteEvents;

    if (eventNotifier.isLoadingFavorites) {
      return Center(child: CircularProgressIndicator());
    }

    // Initialiser la localisation française
    Intl.defaultLocale = 'fr_FR'; // Forcer la localisation française

    // Filter events based on the toggle state
    List<POI> filteredEvents = favoriteEvents.where((event) {
      DateTime eventEndDate = DateTime.parse(event.endDate);
      return showUpcoming ? eventEndDate.isAfter(DateTime.now()) : eventEndDate.isBefore(DateTime.now());
    }).toList();

    for (var event in filteredEvents) {
      print("Événement favori : ${event.name} avec ID : ${event.eventID}");
    }

    // Sorting the events either alphabetically or by date (default is by date)
    if (sortAlphabetically) {
      filteredEvents.sort((a, b) {
        int comparison = a.name.compareTo(b.name);
        return sortAscending ? comparison : -comparison; // Appliquer l'ordre croissant/décroissant
      });
    } else {
      // Default sorting by date
      filteredEvents.sort((a, b) {
        int comparison = DateTime.parse(a.startDate).compareTo(DateTime.parse(b.startDate));
        return sortAscending ? comparison : -comparison; // Sort ascending or descending based on sortAscending
      });
    }

    // Group events by month
    Map<String, List<POI>> eventsByMonth = {};
    for (var event in filteredEvents) {
      DateTime eventDate = DateTime.parse(event.startDate);

      // Utiliser la localisation française pour afficher les mois en français
      String monthKey = DateFormat('MMMM yyyy').format(eventDate);

      // Transformer la première lettre en majuscule
      monthKey = monthKey[0].toUpperCase() + monthKey.substring(1);

      if (!eventsByMonth.containsKey(monthKey)) {
        eventsByMonth[monthKey] = [];
      }
      eventsByMonth[monthKey]!.add(event);
    }

    return Scaffold(
      backgroundColor: Colors.white, // Fond blanc
      body: Column(
        children: [
          const SizedBox(height: 60), // Marge depuis le haut de la page
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Icone croix pour fermer la page
                GestureDetector(
                  onTap: () {
                    Navigator.of(context).pop();
                  },
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.close,
                      color: Colors.black,
                      size: 24,
                    ),
                  ),
                ),
                // Titre "Favoris"
                const Expanded(
                  child: Center(
                    child: Text(
                      'Favoris',
                      style: TextStyle(
                        fontFamily: 'Sora',
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
                // Espace réservé pour aligner le titre au centre
                const SizedBox(width: 40),
              ],
            ),
          ),
          const SizedBox(height: 16), // Marge supplémentaire après le titre

          // 1. Barre de tri
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () {
                    setState(() {
                      // Toggle ascending/descending order for dates
                      sortAscending = !sortAscending;
                    });
                  },
                  child: Row(
                    children: [
                      const Icon(Icons.filter_list, color: Colors.black),
                      const SizedBox(width: 8),
                      Text(
                        'Trier par : ${sortAlphabetically ? "A - Z" : "Date"}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                      Icon(
                        sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
                        color: Colors.black,
                        size: 18,
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    // Bouton A-Z pour tri alphabétique
                    ElevatedButton.icon(
                      onPressed: () {
                        setState(() {
                          sortAlphabetically = true; // Tri par ordre alphabétique (A-Z)
                        });
                      },
                      label: const Text('A - Z'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: sortAlphabetically ? Colors.black : Colors.white, // Bouton actif si tri alphabétique
                        foregroundColor: sortAlphabetically ? Colors.white : Colors.black,
                        shape: const StadiumBorder(), // Bordure arrondie
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Bouton pour tri par date
                    OutlinedButton.icon(
                      onPressed: () {
                        setState(() {
                          sortAlphabetically = false; // Tri par ordre chronologique (Date)
                        });
                      },
                      label: const Text('Date'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: !sortAlphabetically ? Colors.white : Colors.black,
                        backgroundColor: !sortAlphabetically ? Colors.black : Colors.white,
                        shape: const StadiumBorder(),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // 2. Toggle "Event passé" / "Event à venir"
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(25),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          showUpcoming = false;
                        });
                      },
                      child: const Text('Evénements passés'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: !showUpcoming ? Colors.black : Colors.white,
                        foregroundColor: !showUpcoming ? Colors.white : Colors.black,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(25),
                            bottomLeft: Radius.circular(25),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          showUpcoming = true;
                        });
                      },
                      child: const Text('Evénements à venir'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: showUpcoming ? Colors.black : Colors.white,
                        foregroundColor: showUpcoming ? Colors.white : Colors.black,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.only(
                            topRight: Radius.circular(25),
                            bottomRight: Radius.circular(25),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // 3. Afficher la liste des événements groupés par mois avec fond gris et nombre de favoris
          Expanded(
            child: Container(
              color: Colors.grey[200], // Fond gris pour la section événements
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  // Ajouter le nombre total d'événements favoris
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      '${filteredEvents.length} événement(s) en favoris', // Affichage du nombre d'événements
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                  ),

                  Expanded(
                    child: ListView(
                      children: eventsByMonth.entries.map((entry) {
                        String month = entry.key;
                        List<POI> events = entry.value;

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Titre du mois
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                              child: Text(
                                month,
                                style: const TextStyle(
                                  fontFamily: 'Sora',
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
                                ),
                              ),
                            ),

                            // Cartes d'événements
                            Column(
                              children: events.map((event) {
                                return GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => EventPage(event: event),
                                      ),
                                    );
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                                    child: Container(
                                      height: 150,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(20),
                                        color: Colors.white,
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.2),
                                            blurRadius: 10,
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
                                            child: Container(
                                              width: 110,  // Largeur définie pour maintenir la structure
                                              height: double.infinity,  // Pour remplir la hauteur de la carte
                                              decoration: BoxDecoration(
                                                color: Colors.grey,  // Fond gris si l'image est manquante
                                              ),
                                              child: event.photoUrl != null && event.photoUrl!.isNotEmpty
                                                ? Image.network(
                                                    event.photoUrl!,
                                                    fit: BoxFit.cover,
                                                    errorBuilder: (context, error, stackTrace) {
                                                      // Image de fallback en cas d'erreur
                                                      return Image.asset(
                                                        'lib/assets/images/default_event_poster.png',
                                                        fit: BoxFit.cover,
                                                      );
                                                    },
                                                  )
                                                : Image.asset(
                                                    'lib/assets/images/default_event_poster.png',  // Image par défaut si pas d'image
                                                    fit: BoxFit.cover,
                                                  ),
                                            ),
                                          ),
                                          // Détails de l'événement
                                          Expanded(
                                            child: Padding(
                                              padding: const EdgeInsets.all(16),
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    event.name,
                                                    style: const TextStyle(
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 16,
                                                      color: Color(0xFF333333),
                                                    ),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                  const SizedBox(height: 12),
                                                  Text(
                                                    event.description ?? "Aucune description disponible",
                                                    style: const TextStyle(
                                                      fontSize: 14,
                                                      color: Color(0xFF888888),
                                                    ),
                                                    maxLines: 2,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                  const SizedBox(height: 12),
                                                  Row(
                                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                    children: [
                                                      Expanded(
                                                        child: Row(
                                                          children: [
                                                            const Icon(Icons.location_on, size: 16, color: Color(0xFF666666)),
                                                            const SizedBox(width: 4),
                                                            Expanded(
                                                              child: Text(
                                                                event.location?.city ?? "Ville non spécifiée",
                                                                style: const TextStyle(fontSize: 14, color: Color(0xFF666666)),
                                                                maxLines: 1,
                                                                overflow: TextOverflow.ellipsis,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                      Text(
                                                        DateFormat('dd/MM').format(DateTime.parse(event.startDate)),
                                                        style: const TextStyle(fontSize: 14, color: Color(0xFF666666)),
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
                                );
                              }).toList(),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
