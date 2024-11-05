// lib/providers/auth_provider.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firebase_service.dart';
import '../services/user_service.dart';
import '../models/user.dart';

class AuthProvider with ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();
  User? _user;
  String? _role; // Ajouter le rôle

  AuthProvider() {
    _user = FirebaseAuth.instance.currentUser;
    if (_user != null) {
      fetchUserRole(); // Récupérer le rôle lors de l'initialisation
    }
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      _user = user;
      if (_user != null) {
        fetchUserRole();
      } else {
        _role = null;
      }
      notifyListeners();
    });
  }

  User? get user => _user;
  String? get role => _role;

  // Méthode pour récupérer le rôle de l'utilisateur
  Future<void> fetchUserRole() async {
    String? token = await getIdToken();
    if (token != null) {
      String? role = await UserService().getUserRole(token);
      if (role != null) {
        _role = role;
        notifyListeners();
      }
    }
  }

  Future<void> signIn(String email, String password) async {
    try {
      User? user = await _firebaseService.signInWithEmail(email, password);
      if (user == null) {
        throw FirebaseAuthException(
          code: 'user-not-found',
          message: 'Utilisateur non trouvé',
        );
      }
      _user = user;
      notifyListeners();
    } catch (e) {
      rethrow; // Relancer l'exception pour qu'elle soit gérée dans l'interface utilisateur
    }
  }

  Future<void> signOut() async {
    await FirebaseAuth.instance.signOut();
    _user = null;
    notifyListeners();
  }

  Future<String?> getIdToken() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      return await user.getIdToken();
    }
    return null;
  }
}
