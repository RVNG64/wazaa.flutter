// lib/services/user_service.dart

import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/user.dart';

class UserService {
  final String baseUrl = 'https://wazaapp-backend-e95231584d01.herokuapp.com/auth'; // Assurez-vous que l'URL est correcte

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
    Set<String> preferences
  ) async {
    try {
      print('Envoi de la requête PUT /auth/user avec le token: $token');
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
          'preferences': preferences.toList(),  // Ajout des préférences
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

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        List<String> favorites = List<String>.from(data['favorites']);
        return favorites;
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
