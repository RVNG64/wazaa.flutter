// lib/services/firebase_service.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:logger/logger.dart';  // Import Logger

final logger = Logger();  // Utilisation de Logger

class FirebaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Initialisation de Firebase
  static Future<void> initializeFirebase() async {
    await Firebase.initializeApp();
  }

  // Inscription utilisateur avec email et mot de passe
  Future<User?> signUpWithEmail(String email, String password) async {
    try {
      logger.i('Attempting sign up with email: $email');
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      logger.i('User signed up successfully: ${userCredential.user?.uid}');
      return userCredential.user;
    } catch (e) {
      logger.e('Error during sign up: $e');
      return null;
    }
  }

  // Connexion utilisateur avec email et mot de passe
  Future<User?> signInWithEmail(String email, String password) async {
    try {
      logger.i('Attempting sign in with email: $email');
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      logger.i('User signed in successfully: ${userCredential.user?.uid}');
      return userCredential.user;
    } catch (e) {
      logger.e('Error during sign in: $e');
      return null;
    }
  }
}
