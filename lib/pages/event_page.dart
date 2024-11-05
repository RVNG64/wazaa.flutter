import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:intl/intl.dart';
import 'package:wazaa_app/models/poi.dart';
import 'package:wazaa_app/models/poi_infos/price_options.dart';
import 'package:share_plus/share_plus.dart';
import 'package:provider/provider.dart';
import '../services/event_notifier.dart';
import '../widgets/advertisement_banner.dart';
import '../widgets/recommended_events_section.dart';
import 'dart:ui';

// Function to format the price options
String formatPriceOptions(PriceOptions? priceOptions) {
  if (priceOptions == null) {
    return 'Non spécifié';
  }
  if (priceOptions.isFree) {
    return 'Gratuit';
  } else if (priceOptions.uniquePrice != null) {
    return '${priceOptions.uniquePrice} €';
  } else if (priceOptions.priceRange != null) {
    final double minPrice = priceOptions.priceRange!.min;
    final double maxPrice = priceOptions.priceRange!.max;

    if (minPrice == 0 && maxPrice == 0) {
      return 'Gratuit';
    } else if (minPrice == 0 && maxPrice != null) {
      return 'Gratuit';
    } else {
      return 'De $minPrice à $maxPrice €';
    }
  } else {
    return 'Non spécifié';
  }
}

class EventPage extends StatelessWidget {
  final POI event;

  const EventPage({Key? key, required this.event}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final eventNotifier = Provider.of<EventNotifier>(context);
    final isFavorite = eventNotifier.isFavorite(event);

    // Formatting the dates
    String formattedStartDate = 'Date inconnue';
    String formattedEndDate = 'Date inconnue';

    try {
      DateTime startDate = DateTime.parse(event.startDate);
      formattedStartDate = DateFormat('dd/MM').format(startDate);
    } catch (_) {}

    try {
      DateTime endDate = DateTime.parse(event.endDate);
      formattedEndDate = DateFormat('dd/MM').format(endDate);
    } catch (_) {}

    // Formatting the times
    String formattedStartTime = 'Non indiqué';
    String formattedEndTime = '';

    if (event.startTime != null && event.startTime != 'Heure inconnue') {
      try {
        DateTime startTime = DateTime.parse(event.startDate + ' ' + event.startTime!);
        formattedStartTime = DateFormat('HH:mm').format(startTime);
      } catch (_) {
        formattedStartTime = 'Non indiqué'; 
      }
    }

    if (event.endTime != null && event.endTime != 'Heure de fin inconnue') {
      try {
        DateTime endTime = DateTime.parse(event.startDate + ' ' + event.endTime!);
        formattedEndTime = DateFormat('HH:mm').format(endTime);
      } catch (_) {}
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack( 
        children: [
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top image with a gradient and event information
                Stack(
                  children: [
                    // GestureDetector for image tap
                    GestureDetector(
                      onTap: () {
                        _showFullImage(context, event.photoUrl);
                      },
                      child: Container(
                        height: MediaQuery.of(context).size.height * 0.6,
                        width: double.infinity,
                        child: event.photoUrl != null && event.photoUrl!.isNotEmpty
                            ? Image.network(
                                event.photoUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Image.asset(
                                    'lib/assets/images/default_event_poster.png',
                                    fit: BoxFit.cover,
                                  );
                                },
                              )
                            : Image.asset(
                                'lib/assets/images/default_event_poster.png',
                                fit: BoxFit.cover,
                              ),
                      ),
                    ),
                    // Larger gradient
                    Positioned.fill(
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: Container(
                          height: 100,  // Large gradient
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [
                                Colors.white.withOpacity(1),
                                Colors.white.withOpacity(0.7),
                                Colors.white.withOpacity(0.3),
                                Colors.transparent
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Back arrow icon with white circular background and shadow
                    Positioned(
                      top: 40,
                      left: 15,
                      child: GestureDetector(
                        onTap: () {
                          Navigator.pop(context);
                        },
                        child: Container(
                          width: 35,
                          height: 35,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 6,
                                spreadRadius: 1,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Icon(
                              Icons.arrow_back_ios_new,
                              size: 16,  // Taille ajustée
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 40,
                      right: 15,
                      child: Row(
                        children: [
                          // Share icon with white circular background and shadow
                          /*Container(
                            width: 35,
                            height: 35,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 6,
                                  spreadRadius: 1,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: IconButton(
                              iconSize: 18,  // Taille ajustée
                              icon: const Icon(Icons.share),
                              color: Colors.black,
                              onPressed: () {
                                // Logique de partage
                                _shareEvent(event);
                              },
                            ),
                          ), */
                          const SizedBox(width: 12),
                          FavoriteToggleIcon(event: event),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Event details section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event.name,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: Colors.black,
                          fontFamily: 'Sora',
                        ),
                      ),
                      const SizedBox(height: 8),
                      
                      // Tags
                      if (event.tags != null && event.tags!.isNotEmpty)
                        Text(
                          event.tags!.map((tag) => '#$tag').join(' '),
                          style: const TextStyle(fontSize: 13, color: Colors.grey, fontFamily: 'Poppins', fontStyle: FontStyle.italic),
                        ),
                      const SizedBox(height: 24),

                      // Ligne avec ombre en dessous
                      Container(
                        height: 1,
                        decoration: const BoxDecoration(
                          color: Colors.grey,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black26, 
                              blurRadius: 2,
                              offset: Offset(0, 2), 
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Affichage des dates et des heures côte à côte avec un design moderne
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [Colors.white, Colors.blueGrey.shade50], // Arrière-plan en dégradé
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Colors.blueGrey.shade100,
                                  width: 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.blueGrey.withOpacity(0.1),
                                    blurRadius: 8,
                                    spreadRadius: 2,
                                    offset: Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.calendar_today, size: 22, color: Colors.blueGrey.shade600),
                                  const SizedBox(height: 8),
                                  Text(
                                    formattedStartDate == formattedEndDate
                                        ? formattedStartDate
                                        : 'Du $formattedStartDate au $formattedEndDate',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.blueGrey.shade800,
                                      fontFamily: 'Poppins',
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 8), // Espacement entre les deux cartes
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [Colors.white, Colors.blueGrey.shade50], // Arrière-plan en dégradé
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Colors.blueGrey.shade100,
                                  width: 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.blueGrey.withOpacity(0.1),
                                    blurRadius: 8,
                                    spreadRadius: 2,
                                    offset: Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.access_time, size: 22, color: Colors.blueGrey.shade600),
                                  const SizedBox(height: 8),
                                  Text(
                                    formattedEndTime.isNotEmpty
                                        ? '$formattedStartTime - $formattedEndTime'
                                        : (formattedStartTime == 'Non indiqué' ? 'Non indiqué' : 'À partir de $formattedStartTime'),
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.blueGrey.shade800,
                                      fontFamily: 'Poppins',
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),

                      // Description
                      if (event.description != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),  // Ajout d'un padding pour aérer
                          child: Text(
                            event.description!,
                            textAlign: TextAlign.justify,  // Justifier le texte pour qu'il soit aligné à gauche et à droite
                            style: const TextStyle(
                              fontSize: 15,
                              fontFamily: 'Poppins',
                              height: 1.5,  // Augmenter l'interligne pour rendre le texte plus lisible
                              color: Colors.black87,  // Utiliser une couleur légèrement plus foncée pour le contraste
                            ),
                          ),
                        ),
                      const SizedBox(height: 32),
                      // Full address
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),  // Ajouter du padding autour
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,  // Centrer verticalement l'icône et le texte
                          // Centrer l'icône et le texte horizontalement
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.location_on, size: 24, color: Colors.black),  // Augmenter la taille et la couleur de l'icône
                            const SizedBox(width: 8),
                            Expanded(  // Utilisation de Expanded pour s'assurer que le texte ne dépasse pas
                              child: Text(
                                '${event.location?.address}, ${event.location?.city} ${event.location?.postalCode}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontFamily: 'Poppins',
                                  fontWeight: FontWeight.w500,  // Style plus en gras pour mieux distinguer l'adresse
                                  color: Colors.black87,  // Utilisation du noir pour rester dans le thème
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Map with marker
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),  // Bordures arrondies pour un effet moderne
                        child: Container(
                          height: 200,  // Augmenter la hauteur pour plus de visibilité
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.black12, width: 1),  // Ajout d'une bordure discrète
                          ),
                          child: FlutterMap(
                            options: MapOptions(
                              initialCenter: LatLng(event.location?.latitude ?? 0, event.location?.longitude ?? 0),
                              initialZoom: 15.0,
                            ),
                            children: [
                              TileLayer(
                                urlTemplate: "https://api.mapbox.com/styles/v1/hervemake/clu1zgvkj00p601qsgono9buy/tiles/{z}/{x}/{y}?access_token={accessToken}",
                                additionalOptions: {
                                  'accessToken': 'sk.eyJ1IjoiaGVydmVtYWtlIiwiYSI6ImNtMTUzeHBudjA1c3YydnM4NWozYmk3a2YifQ.8DsYqi5sX_-G7__icEAmjA',
                                },
                              ),
                              MarkerLayer(
                                markers: [
                                  Marker(
                                    point: LatLng(event.location?.latitude ?? 0, event.location?.longitude ?? 0),
                                    width: 80.0,
                                    height: 80.0,
                                    rotate: true,  // Permet la rotation du marqueur avec la carte si besoin
                                    child: Icon(
                                      Icons.location_pin,
                                      color: Colors.red,
                                      size: 40,  // Icône plus grande pour bien marquer l'emplacement
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Section Tarifs et moyens de paiement
                      Container(
                        margin: const EdgeInsets.symmetric(vertical: 16.0),
                        padding: const EdgeInsets.all(20.0),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.white, Colors.grey.shade50], // Fond légèrement dégradé
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.grey.shade300, // Bordure subtile
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.2),
                              blurRadius: 15,
                              spreadRadius: 2,
                              offset: Offset(0, 8), // Ombre plus longue pour effet de profondeur
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                // Section Tarifs
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(Icons.monetization_on_outlined, size: 20, color: Colors.blueGrey),
                                        SizedBox(width: 8),
                                        Text(
                                          'Tarif',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.blueGrey.shade800,
                                            fontFamily: 'Poppins',
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      event.priceOptions != null ? formatPriceOptions(event.priceOptions!) : 'Non spécifié',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontFamily: 'Poppins',
                                        color: Colors.blueGrey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                                // Ajout d'une icône ou d'un détail visuel subtil
                                Icon(Icons.euro_symbol, size: 24, color: Colors.blueGrey.shade300),
                              ],
                            ),
                            Divider(
                              height: 32,
                              color: Colors.blueGrey.shade100,
                              thickness: 1,
                            ),

                            // Section Moyens de paiement
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(Icons.payment_outlined, size: 20, color: Colors.blueGrey),
                                        SizedBox(width: 8),
                                        Text(
                                          'Moyens de paiement',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.blueGrey.shade800,
                                            fontFamily: 'Poppins',
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      event.acceptedPayments?.join(", ") ?? 'Non spécifié',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontFamily: 'Poppins',
                                        color: Colors.blueGrey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                                Icon(Icons.credit_card, size: 24, color: Colors.blueGrey.shade300),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                // Bannière publicitaire en bas de l'écran
                AdvertisementBanner(),

                //const SizedBox(height: 20),

                // Section des événements recommandés
                RecommendedEventsSection(currentEvent: event),
                
                //const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Méthode pour partager l'événement
  void _shareEvent(POI event) {
    final String shareText = 'Rejoignez-moi à l\'événement "${event.name}" le ${event.startDate} à ${event.location?.city}.\n'
        'Plus d\'infos: ${event.description}';
    
    Share.share(shareText);
  }

  // Function to show the full image in a dialog
  void _showFullImage(BuildContext context, String? imageUrl) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Material(
          color: Colors.transparent, // Ensure the background color is transparent
          child: GestureDetector(
            onTap: () {
              Navigator.of(context).pop(); // Close the dialog when tapping on the background
            },
            child: Stack(
              children: [
                // Darken the background with a blur filter that covers the entire screen
                Positioned.fill(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10), // Apply blur
                    child: Container(
                      color: Colors.black.withOpacity(0.7), // Darken the background
                    ),
                  ),
                ),
                // Enlarged image
                Center(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.of(context).pop(); // Close the dialog when the image is clicked
                    },
                    child: FractionallySizedBox(
                      widthFactor: 0.95, // Use 95% of the screen's width
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20), // Add rounded corners to the image
                        child: imageUrl != null && imageUrl.isNotEmpty
                            ? Image.network(
                                imageUrl,
                                fit: BoxFit.contain, // Scale the image while maintaining aspect ratio
                                errorBuilder: (context, error, stackTrace) {
                                  return Image.asset(
                                    'lib/assets/images/default_event_poster.png',
                                    fit: BoxFit.contain,
                                  );
                                },
                              )
                            : Image.asset(
                                'lib/assets/images/default_event_poster.png',
                                fit: BoxFit.contain,
                              ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class FavoriteToggleIcon extends StatefulWidget {
  final POI event;

  const FavoriteToggleIcon({Key? key, required this.event}) : super(key: key);

  @override
  _FavoriteToggleIconState createState() => _FavoriteToggleIconState();
}

class _FavoriteToggleIconState extends State<FavoriteToggleIcon> with SingleTickerProviderStateMixin {
  bool _isFavorite = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _showMessage = false;

  @override
  void initState() {
    super.initState();
    final eventNotifier = Provider.of<EventNotifier>(context, listen: false);
    _isFavorite = eventNotifier.isFavorite(widget.event);

    // Initialisation du controller d'animation
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500), // Durée augmentée pour plus de fluidité
    );

    // Configuration du tween pour un effet de rebond plus fluide
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutBack, // Courbe plus douce avec un léger rebond
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose(); // Libérer les ressources de l'animation
    super.dispose();
  }

  void _toggleFavorite() async {
    final eventNotifier = Provider.of<EventNotifier>(context, listen: false);

    setState(() {
      _isFavorite = !_isFavorite;
      _showMessage = true;
    });

    if (_isFavorite) {
      await eventNotifier.addToFavorites(widget.event);
    } else {
      await eventNotifier.removeFromFavorites(widget.event);
    }

    // Démarrer l'animation de rebond fluide
    _animationController.forward().then((value) {
      // Revenir à l'état initial après l'effet de rebond
      _animationController.reverse();
    });

    // Utilisation de Overlay pour afficher un message temporaire en haut de la page
    OverlayState? overlayState = Overlay.of(context);
    OverlayEntry overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: 100, // Positionner le message en haut de la page
        right: 20, // Ajuster la position pour qu'elle soit proche de l'icône des favoris
        left: 40,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.8),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Center(
              child: Text(
                _isFavorite ? 'Ajouté aux favoris ❤️' : 'Retiré des favoris 💔',
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ),
    );

    // Afficher le message pendant 2 secondes puis le retirer
    overlayState!.insert(overlayEntry);
    Future.delayed(const Duration(seconds: 2), () {
      overlayEntry.remove();
    });
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation, // Utilisation de l'animation de l'effet de rebond plus fluide
      child: Container(
        width: 35,
        height: 35,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: _isFavorite
              ? const LinearGradient(
                  colors: [Colors.blue, Colors.purple],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: _isFavorite ? null : Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 6,
              spreadRadius: 1,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: IconButton(
          iconSize: 18,
          icon: Icon(
            _isFavorite ? Icons.favorite : Icons.favorite_border,
            color: _isFavorite ? Colors.white : Colors.black,
          ),
          onPressed: _toggleFavorite,
        ),
      ),
    );
  }
}
