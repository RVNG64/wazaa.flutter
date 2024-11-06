// services/dynamic_links_service.dart

import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import 'package:flutter/material.dart';
import '../pages/invite_friends.dart';
import '../pages/event_page.dart'; 
import '../pages/splash_screen.dart';

class DynamicLinksService {
  final FirebaseDynamicLinks _dynamicLinks = FirebaseDynamicLinks.instance;

  Future<void> initDynamicLinks(BuildContext context) async {
    // Gérer les liens reçus lorsqu'on ouvre l'application à partir d'un lien
    _dynamicLinks.onLink.listen((dynamicLinkData) {
      _handleDynamicLink(dynamicLinkData, context);
    }).onError((error) {
      print('Erreur lors de la réception du lien dynamique: $error');
    });

    // Gérer les liens reçus lors du démarrage de l'application
    final PendingDynamicLinkData? initialLink = await _dynamicLinks.getInitialLink();
    if (initialLink != null) {
      _handleDynamicLink(initialLink, context);
    }
  }

  void _handleDynamicLink(PendingDynamicLinkData data, BuildContext context) {
    final Uri deepLink = data.link;

    if (deepLink.pathSegments.contains('invite')) {
      // Rediriger vers la page d'invitation
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => InviteFriendsPage()),
      );
    } else if (deepLink.pathSegments.contains('event')) {
      String? eventId = deepLink.queryParameters['id'];
        if (eventId != null) {
        Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => EventPage(eventId: eventId)),
        );
      }
    } else {
      // Rediriger vers la page par défaut si le lien ne correspond pas
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => SplashScreen()),
      );
    }
  }
}
