import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../providers/auth_provider.dart' as custom_auth;
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'welcome_page.dart';
import 'package:logger/logger.dart';

final logger = Logger();

// Page de sélection des événements
class EventsSelectionPage extends StatefulWidget {
  const EventsSelectionPage({Key? key}) : super(key: key);

  @override
  _EventsSelectionPageState createState() => _EventsSelectionPageState();
}

class _EventsSelectionPageState extends State<EventsSelectionPage> {
  // Utiliser ValueNotifier pour optimiser la gestion de l'état
  final ValueNotifier<Set<String>> _selectedCategories = ValueNotifier<Set<String>>({});

  // Méthode pour gérer la sélection des catégories
  void _toggleCategorySelection(String category) {
    _selectedCategories.value = {..._selectedCategories.value}; // Clone l'ensemble
    if (_selectedCategories.value.contains(category)) {
      _selectedCategories.value.remove(category); // Supprime la catégorie
    } else {
      _selectedCategories.value.add(category); // Ajoute la catégorie
    }
    // Notifier la mise à jour
    _selectedCategories.notifyListeners(); // Très important pour notifier la modification
  }

  // Méthode pour récupérer l'ID utilisateur Firebase
  String? getFirebaseUserId() {
    return FirebaseAuth.instance.currentUser?.uid;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.2,
            colors: [Color(0xFF205893), Color(0xFF16141E)],
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 50),
            _buildBackButton(context),
            const SizedBox(height: 40),
            const _PageTitle(),
            const SizedBox(height: 20),
            const _Subtitle(),
            const SizedBox(height: 20),
            _buildEventGrid(),
            const SizedBox(height: 20),
            _buildSubmitButton(context),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  // Composant pour gérer la grille des événements
  Widget _buildEventGrid() {
    const categories = [
      {'title': 'Musique', 'image': 'lib/assets/images/concert_theme.png'},
      {'title': 'Famille', 'image': 'lib/assets/images/family_theme.png'},
      {'title': 'Arts', 'image': 'lib/assets/images/arts_theme.png'},
      {'title': 'Sport', 'image': 'lib/assets/images/sports-theme.png'},
      {'title': 'Food', 'image': 'lib/assets/images/food_theme.png'},
      {'title': 'Théâtre', 'image': 'lib/assets/images/theater_theme.png'},
      {'title': 'Pro', 'image': 'lib/assets/images/pro_theme.png'},
      {'title': 'Tourisme', 'image': 'lib/assets/images/tourism_theme.png'},
      {'title': 'Nature', 'image': 'lib/assets/images/nature_theme.png'},
    ];

    return Expanded(
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          return ValueListenableBuilder<Set<String>>(
            valueListenable: _selectedCategories,
            builder: (context, selectedCategories, child) {
              return _EventCategoryTile(
                title: category['title']!,
                imageUrl: category['image']!,
                isSelected: selectedCategories.contains(category['title']),
                onTap: () => _toggleCategorySelection(category['title']!),
              );
            },
          );
        },
      ),
    );
  }

  // Bouton "Suivant" pour valider la sélection
  Widget _buildSubmitButton(BuildContext context) {
    return Center(
      child: OutlinedButton(
        onPressed: () async {
          String? firebaseId = getFirebaseUserId();
          if (firebaseId == null) {
            print('Erreur : utilisateur non connecté');
            return;
          }

          final authProvider = Provider.of<custom_auth.AuthProvider>(context, listen: false);
          String? role = authProvider.role;

          logger.i('Attempting to update preferences with Firebase UID: $firebaseId');

          final response = await http.put(
            Uri.parse('https://wazaapp-backend-e95231584d01.herokuapp.com/routes/preferences'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'firebaseId': firebaseId,
              'categories': _selectedCategories.value.toList(),
              'role': role, // Ajouter le rôle
            }),
          );

          if (response.statusCode == 200) {
            logger.i('Preferences updated successfully for Firebase UID: $firebaseId');
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const WelcomePage()),
            );
          } else {
            logger.e('Erreur lors de la mise à jour des préférences: ${response.body}');
          }
        },
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 100, vertical: 20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
          side: const BorderSide(color: Colors.white, width: 1),
        ),
        child: const Text(
          'Suivant',
          style: TextStyle(fontFamily: 'Poppins', fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white),
        ),
      ),
    );
  }

  // Bouton de retour
  Widget _buildBackButton(BuildContext context) {
    return Align(
      alignment: Alignment.topLeft,
      child: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Container(
          width: 30,
          height: 30,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF205893), size: 20),
        ),
      ),
    );
  }
}

// Widget pour afficher chaque catégorie d'événement dans la grille
class _EventCategoryTile extends StatelessWidget {
  final String title;
  final String imageUrl;
  final bool isSelected;
  final VoidCallback onTap;

  const _EventCategoryTile({
    Key? key,
    required this.title,
    required this.imageUrl,
    required this.isSelected,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              image: DecorationImage(image: AssetImage(imageUrl), fit: BoxFit.cover),
            ),
          ),
          if (isSelected)
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white, width: 1),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.blue, Colors.purple],
                ),
              ),
            ),
          if (!isSelected)
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.black.withOpacity(0.4),
              ),
            ),
          Center(
            child: Text(
              title,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: isSelected ? 17 : 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                shadows: const [Shadow(offset: Offset(0, 1), blurRadius: 6.0, color: Colors.black)],
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

// Titre principal
class _PageTitle extends StatelessWidget {
  const _PageTitle({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Text(
      'VOS EVENTS PRÉFÉRÉS ❤️',
      style: TextStyle(fontFamily: 'Sora', fontSize: 38, fontWeight: FontWeight.w900, color: Colors.white, height: 1.2),
      textAlign: TextAlign.center,
    );
  }
}

// Sous-titre
class _Subtitle extends StatelessWidget {
  const _Subtitle({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Text(
      'Sélectionnez les événements que vous préférez pour personnaliser votre expérience.',
      style: TextStyle(fontFamily: 'Poppins', fontSize: 15, color: Colors.white),
      textAlign: TextAlign.center,
    );
  }
}
