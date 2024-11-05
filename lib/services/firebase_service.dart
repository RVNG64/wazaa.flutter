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
      print('Attempting sign up with email: $email');
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      print('Error during sign up: $e');
      // Relancer l'exception
      throw e;
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
    } on FirebaseAuthException catch (e) {
      logger.e('FirebaseAuthException during sign in: ${e.code}, ${e.message}');
      throw e; // Relancer l'exception pour qu'elle soit gérée ailleurs
    } catch (e) {
      logger.e('General error during sign in: $e');
      throw e; // Relancer l'exception
    }
  }
}
