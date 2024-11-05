import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:wazaa_app/models/poi.dart';
import 'package:wazaa_app/models/event.dart';
import 'package:wazaa_app/services/event_notifier.dart';
import '../pages/event_page.dart';

class RecommendedEventsSection extends StatelessWidget {
  final dynamic currentEvent; // Peut être un POI ou un Event

  const RecommendedEventsSection({Key? key, required this.currentEvent}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final eventNotifier = Provider.of<EventNotifier>(context);

    // Combiner les événements POI et natifs pour la recherche de recommandations
    List<dynamic> allEvents = [
      ...eventNotifier.events,
      ...eventNotifier.nativeEvents,
    ];

    // Log des événements pour vérifier leur présence
    print("Total des événements chargés : ${allEvents.length}");
    print("Événement actuel : ${currentEvent.name}, Tags : ${currentEvent.tags}");

    // Normaliser les tags de l'événement actuel
    List<String> currentEventTags = _extractTagsAsStringList(currentEvent.tags);
    print("Tags de l'événement actuel après normalisation : $currentEventTags");

    // Récupérer les événements recommandés
    List<dynamic> recommendedEvents = allEvents.where((event) {
      if (event != currentEvent && event.tags != null) {
        // Normaliser les tags de chaque événement pour s'assurer qu'ils sont des chaînes
        List<String> eventTags = _extractTagsAsStringList(event.tags);

        // Log des tags de chaque événement pour le débogage
        //print("Vérification de l'événement : ${event.name}, Tags après normalisation : $eventTags");

        // Comparer de manière insensible à la casse et autoriser une correspondance partielle
        bool hasMatchingTags = eventTags.any((tag) {
          return currentEventTags.any((currentTag) {
            return currentTag.toLowerCase() == tag.toLowerCase() ||
                currentTag.toLowerCase().contains(tag.toLowerCase()) ||
                tag.toLowerCase().contains(currentTag.toLowerCase());
          });
        });

        if (hasMatchingTags) {
          //print("Événement recommandé trouvé : ${event.name}, Tags correspondants : ${eventTags.where((tag) => currentEventTags.contains(tag)).toList()}");
        }
        return hasMatchingTags;
      }
      return false;
    }).toList();

    // Log pour vérifier si des événements recommandés ont été trouvés
    if (recommendedEvents.isEmpty) {
      print("Aucune recommandation trouvée pour l'événement : ${currentEvent.name}");
    } else {
      print("Nombre d'événements recommandés : ${recommendedEvents.length}");
    }

    // Retourne un widget vide si aucune recommandation n'est trouvée
    if (recommendedEvents.isEmpty) {
      return const SizedBox();
    }

    return Container(
      margin: const EdgeInsets.only(top: 0, bottom: 0),
      padding: const EdgeInsets.only(top: 40, bottom: 40),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF205893), Color(0xFF16141E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 30,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              'Vous aimerez aussi...',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                fontFamily: 'Sora',
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 240,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: recommendedEvents.length,
              itemBuilder: (context, index) {
                final event = recommendedEvents[index];

                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EventPage(event: event),
                      ),
                    );
                  },
                  child: AnimatedContainer(
                    duration: Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    width: 250,
                    margin: const EdgeInsets.only(left: 16, right: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      color: Colors.white,
                      border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 20,
                          offset: Offset(0, 12),
                        ),
                        BoxShadow(
                          color: Colors.blue.withOpacity(0.1),
                          blurRadius: 30,
                          offset: Offset(-5, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(18),
                            topRight: Radius.circular(18),
                          ),
                          child: Stack(
                            children: [
                              event.photoUrl != null && event.photoUrl!.isNotEmpty
                                  ? Image.network(
                                      event.photoUrl!,
                                      height: 150,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                    )
                                  : Image.asset(
                                      'lib/assets/images/default_event_poster.png',
                                      height: 140,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                    ),
                              Positioned.fill(
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.transparent,
                                        Colors.black.withOpacity(0.6),
                                      ],
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 0,
                                left: 0,
                                right: 0,
                                child: Container(
                                  height: 10,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.white.withOpacity(0.1),
                                        Colors.transparent,
                                      ],
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                event.name,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Flexible(
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.location_on,
                                          color: Colors.redAccent,
                                          size: 16,
                                        ),
                                        const SizedBox(width: 4),
                                        Flexible(
                                          child: Text(
                                            event.location?.city ?? 'Lieu non spécifié',
                                            style: const TextStyle(
                                              fontSize: 13,
                                              color: Colors.grey,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    DateFormat('dd/MM/yyyy').format(DateTime.parse(event.startDate)),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black54,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Fonction pour extraire les tags sous forme de liste de chaînes de caractères
  List<String> _extractTagsAsStringList(dynamic tags) {
    if (tags is List) {
      return tags.map((tag) => tag.toString().trim()).toList();
    }
    return [];
  }
}
