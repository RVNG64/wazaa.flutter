// lib/services/user_service.dart

import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/user.dart';

class UserService {
  final String baseUrl = 'http://10.0.2.2:3000/auth'; // Assurez-vous que l'URL est correcte


  Future<String?> getUserRole(String token) async {
    try {
      print('Envoi de la requête GET /auth/role avec le token: $token');
      final response = await http.get(
        Uri.parse('$baseUrl/role'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        print('Réponse réussie: ${response.body}');
        final data = jsonDecode(response.body);
        return data['role'] as String?;
      } else {
        print('Erreur lors de la récupération du rôle utilisateur: ${response.statusCode}');
        print('Corps de la réponse: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Exception lors de la récupération du rôle utilisateur: $e');
      return null;
    }
  }

  // Méthode pour récupérer les informations de l'utilisateur
  Future<UserModel?> getUserInfo(String token) async {
    try {
      print('Envoi de la requête GET /auth/user avec le token: $token');
      final response = await http.get(
        Uri.parse('$baseUrl/user'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        print('Réponse réussie: ${response.body}');
        final data = jsonDecode(response.body);
        return UserModel.fromJson(data['user']);
      } else {
        print('Erreur lors de la récupération des informations utilisateur: ${response.statusCode}');
        print('Corps de la réponse: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Exception lors de la récupération des informations utilisateur: $e');
      return null;
    }
  }

  // Méthode pour mettre à jour le nom et le prénom de l'utilisateur
  Future<bool> updateUserProfilePicture(String token, String newProfilePicUrl) async {
    try {
      print('Envoi de la requête PUT /auth/user avec le token: $token et URL: $newProfilePicUrl');
      final response = await http.put(
        Uri.parse('$baseUrl/user'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'profilePicture': newProfilePicUrl,
        }),
      );

      if (response.statusCode == 200) {
        print('Photo de profil mise à jour avec succès.');
        return true;
      } else {
        print('Erreur lors de la mise à jour de la photo de profil: ${response.statusCode}');
        print('Corps de la réponse: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Exception lors de la mise à jour de la photo de profil: $e');
      return false;
    }
  }

  // Méthode mise à jour pour inclure les préférences
  Future<bool> updateUserProfile(
    String token,
    String lastName,
    String firstName,
    String phone,
    String profilePicture,
    Set<String> preferences, {
    String? gender,
    String? dob,
    String? city,
    String? zip,
    String? country,
    String? howwemet,
    Map<String, String>? socialMedias,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/user'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'lastName': lastName,
          'firstName': firstName,
          'phone': phone,
          'profilePicture': profilePicture,
          'preferences': preferences.toList(),
          'gender': gender,
          'dob': dob,
          'city': city,
          'zip': zip,
          'country': country,
          'howwemet': howwemet,
          'socialMedias': socialMedias,
        }),
      );

      if (response.statusCode == 200) {
        print('Profil utilisateur mis à jour avec succès.');
        return true;
      } else {
        print('Erreur lors de la mise à jour du profil utilisateur: ${response.statusCode}');
        print('Corps de la réponse: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Exception lors de la mise à jour du profil utilisateur: $e');
      return false;
    }
  }

  // Méthode pour ajouter un événement aux favoris
  Future<bool> addEventToFavorites(String token, String eventId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/user/favorites/add'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'eventId': eventId}),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Erreur lors de l\'ajout de l\'événement aux favoris : $e');
      return false;
    }
  }

  // Méthode pour supprimer un événement des favoris
  Future<bool> removeEventFromFavorites(String token, String eventId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/user/favorites/remove'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'eventId': eventId}),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Erreur lors de la suppression de l\'événement des favoris : $e');
      return false;
    }
  }

  // Méthode pour récupérer les favoris de l'utilisateur
  Future<List<String>?> getUserFavorites(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/user/favorites'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Vérifier si 'favorites' est présent et non nul
        if (data['favorites'] != null && data['favorites'] is List) {
          List<String> favorites = List<String>.from(data['favorites']);
          return favorites;
        } else {
          print('Aucun favori trouvé dans la réponse');
          return [];
        }
      } else {
        print('Erreur lors de la récupération des favoris : ${response.body}');
        return null;
      }
    } catch (e) {
      print('Erreur lors de la récupération des favoris : $e');
      return null;
    }
  }
}
