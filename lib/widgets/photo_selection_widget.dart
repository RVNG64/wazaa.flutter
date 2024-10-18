import 'package:flutter/material.dart';

class PhotoSelectionWidget extends StatelessWidget {
  const PhotoSelectionWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Cercle contenant la photo ou l'icône par défaut
        CircleAvatar(
          radius: 60, // Taille de l'avatar
          backgroundImage: AssetImage('lib/assets/images/default-avatar.png'), // Image par défaut, à changer
          child: Align(
            alignment: Alignment.bottomRight,
            child: IconButton(
              icon: const Icon(Icons.camera_alt, color: Colors.white),
              onPressed: () {
                // Ajouter la logique pour prendre une photo ou choisir une photo dans la galerie
              },
            ),
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'Modifier la photo',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}
