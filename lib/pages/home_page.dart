import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // Import du Provider pour EventNotifier
import 'package:wazaa_app/services/event_service.dart'; // Import du service d'événements
import 'package:wazaa_app/models/poi.dart'; // Import du modèle des événements
import '../services/event_notifier.dart'; // Import du EventNotifier
import 'role_choice_page.dart'; // Page de choix de rôle
import 'login_page.dart'; // Page de connexion

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final EventService _eventService = EventService('http://10.0.2.2:3000'); // URL backend

  @override
  void initState() {
    super.initState();
    _preloadEvents(); // Lancer le chargement des événements en arrière-plan
  }

  Future<void> _preloadEvents() async {
    try {
      // Appel pour charger les événements
      List<POI> events = await _eventService.fetchEventsByPage(1, 50); 

      // Utiliser EventNotifier pour stocker les événements
      Provider.of<EventNotifier>(context, listen: false).setPreloadedEvents(events);
    } catch (e) {
      print('Erreur lors du chargement des événements : $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Centralisation des styles
    final TextStyle buttonTextStyle = TextStyle(
      fontFamily: 'Poppins',
      fontSize: 20,
      fontWeight: FontWeight.w700,
      color: Colors.white,
    );

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0E1636),
              Color(0xFF1B1F3A),
              Color(0xFF11121F),
            ],
          ),
        ),
        child: Stack(
          children: [
            // Image d'arrière-plan optimisée
            Positioned.fill(
              child: Opacity(
                opacity: 0.6,
                child: Transform.translate(
                  offset: const Offset(-70, 0),
                  child: Transform.scale(
                    scale: 1.34,
                    child: Image.asset(
                      'lib/assets/images/img-homeWazaa.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
            ),
            Column(
              children: [
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Text(
                          'WAZAA',
                          style: TextStyle(
                            fontFamily: 'Sora',
                            fontSize: 70,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 10),
                        Text(
                          'Un monde d\'événements',
                          style: TextStyle(
                            fontFamily: 'Sora',
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            height: 1.2,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
                // Section contenant les boutons en bas
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Bouton Inscription avec dégradé
                      Container(
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
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const RoleChoicePage(),
                              ),
                            );
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
                            'Inscription',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10), // Réduire cet espace pour rapprocher les boutons
                      // Bouton Connexion
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const LoginPage(),
                              ),
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            side: const BorderSide(color: Colors.white, width: 1),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(50),
                            ),
                          ),
                          child: Text('Connexion', style: buttonTextStyle),
                        ),
                      ),
                      const SizedBox(height: 20), // Diminuer cette valeur pour rapprocher davantage
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}