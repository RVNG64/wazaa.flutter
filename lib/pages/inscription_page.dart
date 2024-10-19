import 'dart:io'; // Pour gérer les fichiers
import 'package:image_picker/image_picker.dart'; // Package pour sélectionner une image
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http_parser/http_parser.dart'; // Import pour MediaType
import 'package:path/path.dart' as path_lib; // Donne un alias à path
import 'package:mime/mime.dart'; // Pour déterminer le type MIME des fichiers
import 'events_selection_page.dart'; // Page suivante après l'inscription

class InscriptionPage extends StatefulWidget {
  final String userName;

  const InscriptionPage({Key? key, required this.userName}) : super(key: key);

  @override
  _InscriptionPageState createState() => _InscriptionPageState();
}

class _InscriptionPageState extends State<InscriptionPage> {
  File? _selectedImage;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _preloadEventImages();
  }

  // Méthode pour précharger les images de la page EventsSelectionPage
  Future<void> _preloadEventImages() async {
    List<String> imagePaths = [
      'lib/assets/images/concert_theme.png',
      'lib/assets/images/family_theme.png',
      'lib/assets/images/arts_theme.png',
      'lib/assets/images/sports-theme.png',
      'lib/assets/images/food_theme.png',
      'lib/assets/images/theater_theme.png',
      'lib/assets/images/pro_theme.png',
      'lib/assets/images/tourism_theme.png',
      'lib/assets/images/nature_theme.png',
    ];

    for (String imagePath in imagePaths) {
      await precacheImage(AssetImage(imagePath), context);
    }
  }

  // Méthode pour sélectionner une photo
  Future<File?> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      return File(pickedFile.path);
    }
    return null;
  }

  // Méthode pour soumettre uniquement la photo de profil
  Future<void> _submitData() async {
    setState(() {
      _isSubmitting = true;
    });

    try {
      // Assure-toi que l'utilisateur est connecté et récupère son ID Firebase
      final User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('Utilisateur non connecté');
      }

      final firebaseId = currentUser.uid; // Utilise l'ID Firebase de l'utilisateur connecté
      
      // Si aucune photo n'a été sélectionnée, on ne tente pas de mettre à jour la photo
      if (_selectedImage == null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const EventsSelectionPage(),
          ),
        );
        return;
      }

      // Si une photo est sélectionnée, on tente de l'uploader
      final uri = Uri.parse('https://wazaapp-backend-e95231584d01.herokuapp.com/auth/update-profile-picture/$firebaseId');
      var request = http.MultipartRequest('PATCH', uri);

      var mimeType = lookupMimeType(_selectedImage!.path);
      var imageFile = await http.MultipartFile.fromPath(
        'profilePicture',
        _selectedImage!.path,
        contentType: MediaType.parse(mimeType!),
        filename: path_lib.basename(_selectedImage!.path),
      );
      request.files.add(imageFile);

      var response = await request.send();

      if (response.statusCode == 200) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const EventsSelectionPage(),
          ),
        );
      } else {
        throw Exception('Erreur lors de la mise à jour de la photo de profil: ${response.statusCode}');
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur : ${error.toString()}')),
      );
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.2,
            colors: [
              Color(0xFF205893),
              Color(0xFF16141E),
            ],
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 50),
            _buildBackButton(),
            const SizedBox(height: 30),
            _buildGreetingText(),
            const SizedBox(height: 20),
            const Text(
              'Rien de mieux qu\'une photo pour que vos amis puissent vous reconnaître.',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 16,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            // Affichage de l'image avec FutureBuilder
            FutureBuilder<File?>(
              future: Future.value(_selectedImage),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done && snapshot.data != null) {
                  return CircleAvatar(
                    radius: 80,
                    backgroundImage: FileImage(snapshot.data!),
                  );
                } else {
                  return const CircleAvatar(
                    radius: 80,
                    child: Icon(Icons.person, size: 80, color: Colors.white),
                  );
                }
              },
            ),
            const SizedBox(height: 20),
            // Bouton pour sélectionner/modifier la photo
            TextButton(
              onPressed: () async {
                final selectedImage = await _pickImage();
                if (selectedImage != null) {
                  setState(() {
                    _selectedImage = selectedImage;
                  });
                }
              },
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: Text(
                _selectedImage != null ? 'Modifier la photo' : 'Sélectionner ma photo',
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 10,
                  fontWeight: FontWeight.w400,
                  color: Colors.black,
                ),
              ),
            ),
            const Spacer(),
            const SizedBox(height: 20),
            // Bouton "Suivant"
            _buildSubmitButton(),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  // Bouton retour
  Widget _buildBackButton() {
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
          child: const Icon(
            Icons.arrow_back_ios_new,
            color: Color(0xFF205893),
            size: 20,
          ),
        ),
      ),
    );
  }

  // Texte de salutation
  Widget _buildGreetingText() {
    return Text(
      'HELLO ${widget.userName.toUpperCase()} !',
      style: const TextStyle(
        fontFamily: 'Sora',
        fontSize: 40,
        fontWeight: FontWeight.w900,
        color: Colors.white,
      ),
      textAlign: TextAlign.center,
    );
  }

  // Bouton de soumission avec un indicateur de progression
  Widget _buildSubmitButton() {
    return _isSubmitting
        ? const CircularProgressIndicator()
        : OutlinedButton(
            onPressed: _submitData,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 100, vertical: 20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(50),
              ),
              side: const BorderSide(color: Colors.white, width: 1),
            ),
            child: const Text(
              'Suivant',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          );
  }
}
