import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart'; // Pour DateFormat
import 'package:wazaa_app/services/event_notifier.dart';
import 'package:wazaa_app/pages/event_page.dart';
import 'package:wazaa_app/models/poi.dart';

class EventSwiperPage extends StatefulWidget {
  const EventSwiperPage({Key? key}) : super(key: key);

  @override
  _EventSwiperPageState createState() => _EventSwiperPageState();
}

class _EventSwiperPageState extends State<EventSwiperPage> with SingleTickerProviderStateMixin {
  late EventNotifier eventNotifier;
  List<POI> events = [];
  late CardSwiperController _swiperController;

  POI? _lastRemovedEvent; // Pour stocker la dernière carte supprimée
  int? _lastRemovedIndex; // Pour restaurer à la bonne position

  bool _showOverlay = false; // Pour afficher ou masquer l'overlay
  String _overlayMessage = '';
  Color _overlayColor = Colors.transparent;
  late AnimationController _animationController;
  late Animation<double> _overlayScale;

  List<String> _seenEventIDs = []; // Liste des événements déjà vus

  @override
  void initState() {
    super.initState();
    _swiperController = CardSwiperController(); // Initialiser le contrôleur

    eventNotifier = Provider.of<EventNotifier>(context, listen: false);
    events = eventNotifier.events.where((event) => !_seenEventIDs.contains(event.eventID)).toList();
    events.shuffle();

    // Initialiser l'animation pour l'overlay
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 500),
    );
    _overlayScale = CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    );

    // Afficher le message de bienvenue dès le chargement
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showWelcomeDialog();
    });
  }

  @override
  void dispose() {
    _swiperController.dispose(); // Dispose du contrôleur
    _animationController.dispose(); // Dispose de l'animation
    super.dispose();
  }

  // Fonction pour afficher l'overlay avec message et couleur
  void _showOverlayMessage(String message, Color color) {
    if (!_animationController.isAnimating) {
      setState(() {
        _overlayMessage = message;
        _overlayColor = color;
        _showOverlay = true;
      });
      _animationController.forward(from: 0.0).then((_) {
        Future.delayed(Duration(seconds: 2), () {
          if (mounted) {
            setState(() {
              _showOverlay = false; // Masquer l'overlay après quelques secondes
            });
          }
        });
      });
    }
  }

  // Fonction pour afficher le message de bienvenue
  void _showWelcomeDialog() {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.7), // Assombrit l'arrière-plan avec une opacité de 50%
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
          backgroundColor: Colors.transparent, // Fond transparent pour laisser apparaître le dégradé
          child: Stack(
            children: [
              // Fond dégradé personnalisé
              Container(
                padding: const EdgeInsets.all(20.0),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(25),
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFF205893), 
                      Color(0xFF16141E),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.6),
                      blurRadius: 20,
                      spreadRadius: 5,
                      offset: Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Titre principal avec effet moderne
                    Text(
                      'NEXT !',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontFamily: 'Sora',
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    // Texte de présentation
                    Text(
                      "Comment ça marche ?",
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.white70,
                        fontFamily: 'Poppins',
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),

                    // Explication pour le swipe gauche
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.arrow_back_ios_new, color: Colors.redAccent, size: 36, shadows: [
                          Shadow(
                            color: Colors.black54,
                            blurRadius: 6,
                            offset: Offset(2, 2),
                          )
                        ]),
                        const SizedBox(width: 10),
                        Flexible(
                          child: Text(
                            'Swipe gauche pour passer',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                              fontFamily: 'Poppins',
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Explication pour le swipe droite
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Flexible(
                          child: Text(
                            'Swipe droite pour 🤍',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                              fontFamily: 'Poppins',
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Icon(Icons.arrow_forward_ios, color: Colors.greenAccent, size: 36, shadows: [
                          Shadow(
                            color: Colors.black54,
                            blurRadius: 6,
                            offset: Offset(2, 2),
                          )
                        ]),
                      ],
                    ),
                    const SizedBox(height: 30),

                    // Bouton "C'est parti !" avec dégradé
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFF83402F), // Couleur gauche
                              Color(0xFFEA603E), // Couleur droite
                            ],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          borderRadius: BorderRadius.circular(50),
                        ),
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).pop(); // Fermer le message
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(50),
                            ),
                          ),
                          child: const Text(
                            'C\'est parti !',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Fonction pour annuler la suppression (via le bouton undo)
  void _restoreLastEvent() {
    if (_lastRemovedEvent != null && _lastRemovedIndex != null) {
      setState(() {
        events.insert(_lastRemovedIndex!, _lastRemovedEvent!);
        _seenEventIDs.remove(_lastRemovedEvent!.eventID); // Retirer de la liste des événements vus
      });
      _lastRemovedEvent = null;
      _lastRemovedIndex = null;
    }
  }

  // Méthode pour réinitialiser le cycle
  void _resetCycle() {
    setState(() {
      _seenEventIDs.clear(); // Vider la liste des événements vus
      events = List.from(eventNotifier.events); // Récupérer tous les événements
      events.shuffle(); // Remélanger la liste
      _showOverlayMessage('Nouveau cycle commencé', Colors.blueAccent);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) {
      // Tous les événements ont été vus, réinitialiser le cycle
      _resetCycle();
    }

    return Scaffold(
      body: Stack(
        children: [
          // Fond avec un dégradé du bleu au noir
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF0A3D75), // Bleu plus sombre
                    Colors.black,
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: [0.7, 1.0], // Vire au noir dans le dernier quart
                ),
              ),
            ),
          ),

          // Titre et bouton de fermeture en haut
          Positioned(
            top: 50,
            left: 20,
            child: GestureDetector(
              onTap: () {
                Navigator.of(context).pop(); // Fermer la page
              },
              child: Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close,
                  color: Colors.black,
                  size: 24,
                ),
              ),
            ),
          ),

          // Titre centré
          Positioned(
            top: 50,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                'NEXT !',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 38,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'Sora',
                ),
              ),
            ),
          ),

          // Contenu principal : Swiper avec des cartes
          Positioned(
            top: 120, // Ajustement pour que le swiper commence en dessous du titre et du bouton
            left: 0,
            right: 0,
            bottom: 70, // Espace ajouté en bas pour que le bouton undo ne couvre pas les cartes
            child: Center(
              child: CardSwiper(
                controller: _swiperController, // Utiliser le contrôleur correct
                cardsCount: events.length,
                cardBuilder: (BuildContext context, int index, int percentThresholdX, int percentThresholdY) {
                  final event = events[index];
                  return GestureDetector(
                    onTap: () {
                      // Naviguer vers la page de détails de l'événement
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EventPage(event: event),
                        ),
                      );
                    },
                    child: Stack(
                      children: [
                        // Card background (Image + Gradient)
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 10,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: Stack(
                              children: [
                                // Image de l'événement
                                CachedNetworkImage(
                                  imageUrl: event.photoUrl != null && event.photoUrl!.isNotEmpty
                                      ? event.photoUrl! // Si l'URL est valide, on la charge
                                      : '', // Si l'URL est null ou vide, on met un placeholder vide
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  height: double.infinity,
                                  // Si l'URL est incorrecte ou une erreur survient lors du chargement
                                  errorWidget: (context, url, error) => Image.asset(
                                    'lib/assets/images/default_event_poster.png', // Image par défaut si l'URL échoue
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    height: double.infinity,
                                  ),
                                  // Afficher un indicateur de chargement pendant le chargement de l'image
                                  placeholder: (context, url) => Center(child: CircularProgressIndicator()),
                                ),
                                // Gradient overlay pour texte
                                Positioned.fill(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [
                                          Colors.transparent,
                                          Colors.black.withOpacity(0.6),
                                          Colors.black.withOpacity(0.9),
                                        ],
                                        stops: [0.5, 0.8, 1.0], // Vire au noir vers le bas
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        // Détails de l'événement sur l'image
                        Positioned(
                          left: 16,
                          bottom: 20,
                          right: 16,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                event.name,
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w900,
                                  fontFamily: 'Sora',
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.location_on, color: Colors.white, size: 16),
                                      const SizedBox(width: 4),
                                      Text(
                                        event.location?.city ?? 'Lieu non spécifié',
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.white70,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Spacer(), // Spacer pour séparer la ville et la date
                                  Text(
                                    '${DateFormat('dd/MM/yyyy').format(DateTime.parse(event.startDate))}',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontFamily: 'Poppins',
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                event.description ?? 'Description non disponible',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.white70,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
                isLoop: false,
                allowedSwipeDirection: const AllowedSwipeDirection.only(
                  left: true,
                  right: true,
                ),
                onSwipe: (int index, int? previousIndex, CardSwiperDirection direction) async {
                  final event = events[index];

                  // Ajouter l'événement à la liste des événements vus
                  _seenEventIDs.add(event.eventID);

                  if (direction == CardSwiperDirection.right) {
                    // Ajouter aux favoris
                    await eventNotifier.addToFavorites(event);

                    // Afficher le message "Ajouté aux favoris" avec effet
                    _showOverlayMessage('${event.name} ajouté aux favoris', Colors.greenAccent);
                  } else if (direction == CardSwiperDirection.left) {
                    // Sauvegarder la carte supprimée
                    _lastRemovedEvent = event;
                    _lastRemovedIndex = index;

                    // Afficher le message "Passé" avec effet
                    _showOverlayMessage('${event.name} passé', Colors.redAccent);
                  }

                  // Retirer l'événement de la liste après l'ajout aux favoris
                  setState(() {
                    events.removeAt(index);
                  });

                  return true; // Toujours confirmer le swipe
                },
                duration: Duration(milliseconds: 300),
              ),
            ),
          ),

          // Overlay pour afficher les messages de swipe avec un effet dynamique
          if (_showOverlay)
            Center(
              child: ScaleTransition(
                scale: _overlayScale,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    color: _overlayColor.withOpacity(0.85),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Text(
                    _overlayMessage,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

          /* Bouton pour restaurer la dernière carte
          if (_lastRemovedEvent != null)
            Positioned(
              bottom: 50, // Placer en dessous de la pile de cartes
              left: MediaQuery.of(context).size.width * 0.5 - 25, // Centrer le bouton
              child: GestureDetector(
                onTap: _restoreLastEvent,
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.5),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.refresh,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
} */
