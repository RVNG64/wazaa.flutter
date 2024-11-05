// lib/services/organizer_service.dart

import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/organizer.dart';

class OrganizerService {
  final String baseUrl = 'https://wazaapp-backend-e95231584d01.herokuapp.com/auth';

  Future<OrganizerModel?> getOrganizerInfo(String token) async {
    try {
      print('Envoi de la requête GET /auth/organizer avec le token: $token');
      final response = await http.get(
        Uri.parse('$baseUrl/organizer'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        print('Réponse réussie: ${response.body}');
        final data = jsonDecode(response.body);
        return OrganizerModel.fromJson(data['organizer']);
      } else {
        print('Erreur lors de la récupération des informations organisateur: ${response.statusCode}');
        print('Corps de la réponse: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Exception lors de la récupération des informations organisateur: $e');
      return null;
    }
  }

  Future<bool> updateOrganizerProfile(
    String token,
    String lastName,
    String firstName,
    String phone,
    String profilePicture,
    String organizationName,
    String website,
    String address,
    String city,
    String zip,
    String country,
    String howwemet,
    Set<String> preferences,
    Map<String, String> socialMedias,
    // Ajoutez d'autres paramètres si nécessaire
  ) async {
    try {
      print('Envoi de la requête PUT /auth/organizer avec le token: $token');
      final response = await http.put(
        Uri.parse('$baseUrl/organizer'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'lastName': lastName,
          'firstName': firstName,
          'phone': phone,
          'profilePicture': profilePicture,
          'organizationName': organizationName,
          'website': website,
          'address': address,
          'city': city,
          'zip': zip,
          'country': country,
          'howwemet': howwemet,
          'socialMedias': socialMedias,
          // Ajoutez d'autres champs si nécessaire
        }),
      );

      if (response.statusCode == 200) {
        print('Profil organisateur mis à jour avec succès.');
        return true;
      } else {
        print('Erreur lors de la mise à jour du profil organisateur: ${response.statusCode}');
        print('Corps de la réponse: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Exception lors de la mise à jour du profil organisateur: $e');
      return false;
    }
  }
}
