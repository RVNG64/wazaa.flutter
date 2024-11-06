import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:ui';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/event.dart';
import '../services/event_service.dart';
import '../services/event_notifier.dart';
import '../widgets/advertisement_banner.dart';
import '../widgets/recommended_events_section.dart';
import '../widgets/video_player_widget.dart';

// Fonction pour formater les options de prix
String formatPriceOptions(Map<String, dynamic>? priceOptions) {
  if (priceOptions == null) {
    return 'Non spécifié';
  }
  if (priceOptions['isFree'] == true) {
    return 'Gratuit';
  } else if (priceOptions['uniquePrice'] != null) {
    return '${priceOptions['uniquePrice']} €';
  } else if (priceOptions['priceRange'] != null) {
    return 'De ${priceOptions['priceRange']['min']} à ${priceOptions['priceRange']['max']} €';
  } else {
    return 'Non spécifié';
  }
}

class NativeEventPage extends StatelessWidget {
  final Event event;

  const NativeEventPage({Key? key, required this.event}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final eventNotifier = Provider.of<EventNotifier>(context);
    final isFavorite = eventNotifier.isFavorite(event);

    // Formatage des dates
    String formattedStartDate = 'Date inconnue';
    String formattedEndDate = 'Date inconnue';

    try {
      formattedStartDate = DateFormat('dd/MM/yyyy').format(DateTime.parse(event.startDate!));
      formattedEndDate = DateFormat('dd/MM/yyyy').format(DateTime.parse(event.endDate!));
    } catch (_) {}

    // Formatage des heures
    String formattedStartTime = event.startTime ?? 'Heure inconnue';
    String formattedEndTime = event.endTime ?? '';

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image principale avec effet de gradient
                Stack(
                  children: [
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
                    // Gradient blanc en bas de l'affiche
                    Positioned.fill(
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: Container(
                          height: 120,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [
                                Colors.white.withOpacity(1),
                                Colors.white.withOpacity(0.7),
                                Colors.white.withOpacity(0.3),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 40,
                      left: 15,
                      child: GestureDetector(
                        onTap: () => Navigator.pop(context),
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
                          child: const Center(
                            child: Icon(
                              Icons.arrow_back_ios_new,
                              size: 16,
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
                          FavoriteToggleIcon(event: event),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Détails de l'événement
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event.name,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                          fontFamily: 'Sora',
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Tags
                      if (event.tags != null && event.tags!.isNotEmpty)
                        Text(
                          event.tags!.map((tag) => '#$tag').join(' '),
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.grey,
                            fontFamily: 'Poppins',
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      const SizedBox(height: 24),

                      // Séparateur
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
                      const SizedBox(height: 12),
                      
                    // Vidéo de présentation
                    if (event.videoUrl != null && event.videoUrl!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                        child: YouTubePlayerWidget(videoUrl: event.videoUrl!),
                      ),
                      const SizedBox(height: 12),

                    
                      /* Affichage du site Web
                      if (event.website != null && event.website!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Container(
                            width: double.infinity, // Prend toute la largeur possible
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Color(0xFF4C88FF), Color(0xFF567AF2)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(50),
                            ),
                            child: ElevatedButton.icon(
                              onPressed: () => _launchURL(event.website!),
                              icon: Icon(Icons.web, color: Colors.white),
                              label: Text('Visiter le site Web'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent, // Transparent pour montrer le dégradé
                                shadowColor: Colors.transparent, // Retirer l'ombre pour éviter le conflit de couleur
                                padding: EdgeInsets.symmetric(vertical: 14.0),
                                textStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 5,
                              ),
                            ),
                          ),
                        ), */

                    // Lien pour l'achat de billets
                    if (event.ticketLink != null && event.ticketLink!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: GestureDetector(
                          onTap: () => _launchURL(event.ticketLink!),
                          child: Container(
                            width: double.infinity, // Prend toute la largeur
                            padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(
                                color: Colors.white,
                                width: 2,
                              ),
                              gradient: LinearGradient(
                                colors: [Colors.blueAccent, Colors.purpleAccent], // Dégradé de bleu à violet
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black45,
                                  blurRadius: 15,
                                  offset: Offset(0, 5),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                'BILLETTERIE',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontFamily: 'Sora', // Police moderne et élégante
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Dates et horaires
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
                          const SizedBox(width: 8),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [Colors.white, Colors.blueGrey.shade50],
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
                                children: [
                                  Icon(Icons.access_time, size: 22, color: Colors.blueGrey.shade600),
                                  const SizedBox(height: 8),
                                  Text(
                                    formattedEndTime.isNotEmpty
                                        ? '$formattedStartTime - $formattedEndTime'
                                        : 'À partir de $formattedStartTime',
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
                      const SizedBox(height: 24),
                      
                      // Description
                      if (event.description != null)
                        Text(
                          event.description!,
                          textAlign: TextAlign.justify,
                          style: const TextStyle(
                            fontSize: 15,
                            fontFamily: 'Poppins',
                            height: 1.5,
                            color: Colors.black87,
                          ),
                        ),
                      const SizedBox(height: 32),
                      
                      // Boutons de présence (Attendances)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                        child: AttendanceButtons(eventId: event.id),
                      ),
                      const SizedBox(height: 16),

                      // Adresse complète
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.location_on, size: 24, color: Colors.black),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              [
                                if (event.location?['address']?.isNotEmpty ?? false) event.location?['address'],
                                if (event.location?['city']?.isNotEmpty ?? false) event.location?['city'],
                                if (event.location?['postalCode']?.isNotEmpty ?? false) event.location?['postalCode'],
                              ].where((part) => part != null && part.isNotEmpty).join(', '),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Colors.black87,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Carte
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          height: 200,
                          child: FlutterMap(
                            options: MapOptions(
                              initialCenter: LatLng(
                                event.location?['latitude'] ?? 0,
                                event.location?['longitude'] ?? 0,
                              ),
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
                                    point: LatLng(
                                      event.location?['latitude'] ?? 0,
                                      event.location?['longitude'] ?? 0,
                                    ),
                                    width: 40.0,
                                    height: 40.0,
                                    child: const Icon(
                                      Icons.location_pin,
                                      color: Colors.red,
                                      size: 40,
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
                AdvertisementBanner(),
                RecommendedEventsSection(currentEvent: event),

                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Fonction pour afficher l'image complète
  void _showFullImage(BuildContext context, String? imageUrl) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Material(
          color: Colors.transparent,
          child: GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Stack(
              children: [
                Positioned.fill(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      color: Colors.black.withOpacity(0.7),
                    ),
                  ),
                ),
                Center(
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: FractionallySizedBox(
                      widthFactor: 0.95,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: imageUrl != null && imageUrl.isNotEmpty
                            ? Image.network(
                                imageUrl,
                                fit: BoxFit.contain,
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

// Widget pour l'icône des favoris
class FavoriteToggleIcon extends StatefulWidget {
  final Event event;

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
      await eventNotifier.addEventToFavorites(widget.event);
    } else {
      await eventNotifier.removeEventFromFavorites(widget.event);
    }

    // Démarrer l'animation de rebond fluide
    _animationController.forward().then((value) {
      // Revenir à l'état initial après l'effet de rebond
      _animationController.reverse();
    });

    // Afficher un message temporaire
    OverlayState? overlayState = Overlay.of(context);
    OverlayEntry overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: 100,
        right: 20,
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
      scale: _scaleAnimation,
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

// Fonction pour ouvrir une URL dans le navigateur
void _launchURL(String url) async {
  if (await canLaunch(url)) {
    await launch(url);
  } else {
    throw 'Impossible d\'ouvrir l\'URL $url';
  }
}

class AttendanceButtons extends StatefulWidget {
  final String eventId;

  AttendanceButtons({required this.eventId});

  @override
  _AttendanceButtonsState createState() => _AttendanceButtonsState();
}

class _AttendanceButtonsState extends State<AttendanceButtons>
    with SingleTickerProviderStateMixin {
  String? _selectedStatus;
  late EventService _eventService;
  bool _isLoading = false;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _eventService = EventService('http://10.0.2.2:3000');
    _fetchAttendanceStatus();

    // Initialisation de l'animation de pulsation
    _pulseController = AnimationController(
      vsync: this,
      duration: Duration(seconds: 1),
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _fetchAttendanceStatus() async {
    try {
      String? status =
          await _eventService.getUserAttendanceStatus(widget.eventId);
      setState(() {
        _selectedStatus = status;
      });
    } catch (e) {
      print('Erreur lors de la récupération du statut de présence: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text('Erreur lors de la récupération du statut de présence.')),
      );
    }
  }

  void _updateAttendanceStatus(String status) async {

    setState(() {
      _isLoading = true;
    });
    try {
      bool success =
          await _eventService.updateAttendanceStatus(widget.eventId, status);
      if (success) {
        setState(() {
          _selectedStatus = status;
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Statut de présence mis à jour.')),
        );

        // Démarrer l'animation de pulsation pour le bouton sélectionné
        _pulseController.forward().then((_) {
          _pulseController.reverse();
        });
      } else {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de la mise à jour du statut.')),
        );
      }
    } catch (e) {
      print('Erreur lors de la mise à jour du statut: $e');
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la mise à jour du statut.')),
      );
    }
  }

  Widget _buildStatusButton(
      {required String label,
      required String status,
      required Color color,
      required IconData icon}) {
    bool isSelected = _selectedStatus == status;

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _updateAttendanceStatus(status),
          borderRadius: BorderRadius.circular(30),
          splashColor: color.withOpacity(0.3),
          highlightColor: Colors.transparent,
          child: AnimatedContainer(
            duration: Duration(milliseconds: 300),
            margin: EdgeInsets.symmetric(horizontal: 3),
            padding: EdgeInsets.symmetric(vertical: 16, horizontal: 12),
            decoration: BoxDecoration(
              gradient: isSelected
                  ? LinearGradient(
                      colors: [color.withOpacity(0.8), color],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : LinearGradient(
                      colors: [Colors.white, Colors.white],
                    ),
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                if (isSelected)
                  BoxShadow(
                    color: color.withOpacity(0.5),
                    blurRadius: 15,
                    offset: Offset(0, 8),
                  ),
                if (!isSelected)
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    blurRadius: 5,
                    offset: Offset(0, 3),
                  ),
              ],
              border: Border.all(
                color: isSelected ? color : Colors.grey.shade300,
                width: 1.5,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Animation de pulsation pour le bouton sélectionné
                ScaleTransition(
                  scale: isSelected ? _pulseAnimation : AlwaysStoppedAnimation(1.0),
                  child: AnimatedSwitcher(
                    duration: Duration(milliseconds: 300),
                    transitionBuilder: (Widget child, Animation<double> animation) {
                      return ScaleTransition(child: child, scale: animation);
                    },
                    child: Icon(
                      icon,
                      key: ValueKey<bool>(isSelected),
                      color: isSelected ? Colors.white : color,
                      size: 28,
                    ),
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  label,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.black87,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Poppins',
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? Center(
            child: SizedBox(
              width: 26, 
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blueAccent),
              ),
            ),
          )
        : Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildStatusButton(
                label: 'Présent',
                status: 'Participating',
                color: Colors.green,
                icon: Icons.check_circle_outline,
              ),
              _buildStatusButton(
                label: 'Peut-être',
                status: 'Maybe',
                color: Colors.orange,
                icon: Icons.help_outline,
              ),
              _buildStatusButton(
                label: 'Absent',
                status: 'Not Participating',
                color: Colors.red,
                icon: Icons.cancel_outlined,
              ),
            ],
          );
  }
}
