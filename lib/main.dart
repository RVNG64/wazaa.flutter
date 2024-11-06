import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'package:path_provider/path_provider.dart';
import 'pages/splash_screen.dart';
import 'services/event_notifier.dart';
import 'services/dynamic_links_service.dart';
import 'models/poi_adapter.dart'; 
import 'models/poi_infos/location_adapter.dart';
import 'models/poi_infos/price_options_adapter.dart';
import 'models/poi_infos/attendance_entry_adapter.dart';
import './widgets/theme_notifier.dart';

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

    try {
      print("Chargement du fichier .env...");
      await dotenv.load(fileName: ".env");
      print("Fichier .env chargé avec succès");
    } catch (e) {
      print("Erreur lors du chargement du fichier .env: $e");
    }
    
    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (context) => AuthProvider()), 
          ChangeNotifierProvider(create: (context) => EventNotifier()),
          ChangeNotifierProvider(create: (context) => ThemeNotifier()),
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
    return Consumer<ThemeNotifier>(
      builder: (context, themeNotifier, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'WAZAA',
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('fr')],
          locale: const Locale('fr'),
          theme: ThemeData(
            primarySwatch: Colors.blue,
            brightness: Brightness.light,
            scaffoldBackgroundColor: Colors.white, // Fond des Scaffold pour le mode clair
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.white, // Couleur de l'AppBar en mode clair
              iconTheme: IconThemeData(color: Colors.black),
              titleTextStyle: TextStyle(color: Colors.black),
            ),
            textTheme: const TextTheme(
              bodyLarge: TextStyle(color: Colors.black), // Utilisation de bodyLarge au lieu de bodyText1
              bodyMedium: TextStyle(color: Colors.black), // Utilisation de bodyMedium au lieu de bodyText2
            ),
          ),
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            scaffoldBackgroundColor: Colors.black, // Fond des Scaffold pour le mode sombre
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.black, // Couleur de l'AppBar en mode sombre
              iconTheme: IconThemeData(color: Colors.white),
              titleTextStyle: TextStyle(color: Colors.white),
            ),
            textTheme: const TextTheme(
              bodyLarge: TextStyle(color: Colors.white), // Utilisation de bodyLarge au lieu de bodyText1
              bodyMedium: TextStyle(color: Colors.white), // Utilisation de bodyMedium au lieu de bodyText2
            ),
          ),
          themeMode: themeNotifier.isDarkMode ? ThemeMode.dark : ThemeMode.light, // Basé sur ThemeNotifier
          home: SplashScreen(),
        );
      },
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