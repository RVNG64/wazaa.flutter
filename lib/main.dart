import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'package:path_provider/path_provider.dart';
import 'pages/splash_screen.dart';
import 'services/event_notifier.dart';
import 'models/poi_adapter.dart'; 
import 'models/poi_infos/location_adapter.dart';
import 'models/poi_infos/price_options_adapter.dart';
import 'models/poi_infos/attendance_entry_adapter.dart';

final logger = Logger(); // Utilisation de Logger

void main() async {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    /* await Hive.initFlutter();
    Hive.registerAdapter(POIAdapter());
    Hive.registerAdapter(LocationAdapter());
    Hive.registerAdapter(PriceOptionsAdapter());
    Hive.registerAdapter(AttendanceEntryAdapter());
    await Hive.openBox('eventsBox'); */

    await Firebase.initializeApp();

    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (context) => AuthProvider()), 
          ChangeNotifierProvider(create: (context) => EventNotifier()),
        ],
        child: const MyApp(),
      ),
    );

  }, (error, stackTrace) {
    logger.e('Uncaught error: $error\nStackTrace: $stackTrace');
  });
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Charger les favoris après le démarrage de l'application
    final eventNotifier = Provider.of<EventNotifier>(context, listen: false);
    eventNotifier.loadFavorites();

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'WAZAA',
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('fr'),
      ],
      locale: const Locale('fr'),
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: SplashScreen(), // Écran initial
    );
  }
}

class FirebaseInitialization extends StatelessWidget {
  const FirebaseInitialization({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: Firebase.initializeApp(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        } else if (snapshot.hasError) {
          return const Scaffold(
            body: Center(
              child: Text('Erreur lors de l\'initialisation de Firebase'),
            ),
          );
        } else {
          return SplashScreen(); // Passe à l'écran Splash après initialisation
        }
      },
    );
  }
}

class MyHomePage extends StatelessWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sélecteur de date'),
      ),
      body: const Center(
        child: Text('Sélecteur de date'),
      ),
    );
  }
}