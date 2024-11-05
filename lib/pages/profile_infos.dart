import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:path/path.dart' as path;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:mime/mime.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:multi_select_flutter/multi_select_flutter.dart';
import '../providers/auth_provider.dart' as my_auth;
import '../widgets/theme_notifier.dart';
import '../services/organizer_service.dart';
import '../services/user_service.dart';
import '../models/organizer.dart';
import '../models/user.dart';

class ProfileInfosPage extends StatefulWidget {
  const ProfileInfosPage({Key? key}) : super(key: key);

  @override
  _ProfileInfosPageState createState() => _ProfileInfosPageState();
}

class _ProfileInfosPageState extends State<ProfileInfosPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _currentPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmNewPasswordController = TextEditingController();
  final TextEditingController _organizationNameController = TextEditingController();
  final TextEditingController _websiteController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _zipController = TextEditingController();
  final TextEditingController _countryController = TextEditingController();
  final TextEditingController _genderController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _howwemetController = TextEditingController();

  final List<String> _selectedSocialMedias = [];

  Map<String, TextEditingController> _socialMediaControllers = {};
  String profilePicUrl = 'https://example.com/profile-pic.jpg'; // Par défaut
  File? _selectedImage;

  final UserService _userService = UserService(); // Service pour gérer les utilisateurs
  final ValueNotifier<Set<String>> _selectedCategories = ValueNotifier<Set<String>>({});

  UserModel? _user;
  OrganizerModel? _organizer;

  // Liste des options pour "Comment nous avez-vous connu?"
  final List<String> _howWeMetOptions = [
    'Bouche à oreille',
    'Réseaux Sociaux',
    'Recherche en ligne',
    'Presse/Médias',
    'Publicité',
    'Événement',
    'Autre',
  ];

  @override
  void initState() {
    super.initState();
    _fetchUserInfo();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _firstNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmNewPasswordController.dispose();
    _organizationNameController.dispose();
    _websiteController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _zipController.dispose();
    _countryController.dispose();
    _genderController.dispose();
    _dobController.dispose();
    _howwemetController.dispose();
    _socialMediaControllers.forEach((key, controller) {
      controller.dispose();
    });
    super.dispose();
  }

  // Méthode pour récupérer les informations utilisateur depuis le backend
  Future<void> _fetchUserInfo() async {
    final authProvider = Provider.of<my_auth.AuthProvider>(context, listen: false);
    String? token = await authProvider.getIdToken();
    String? role = authProvider.role; // Récupérer le rôle
    if (token != null && role != null) {
      if (role == 'user') {
        UserModel? user = await _userService.getUserInfo(token);
        if (user != null) {
          setState(() {
            _user = user;
            _nameController.text = user.lastName;
            _firstNameController.text = user.firstName;
            _phoneController.text = user.phone;
            _emailController.text = user.email;
            profilePicUrl = user.profilePicture ?? "";
            _genderController.text = user.gender; // Ajouté
            _dobController.text = user.dob != null ? DateFormat('dd/MM/yyyy').format(user.dob!) : ''; // Format modifié
            _cityController.text = user.city; // Ajouté
            _zipController.text = user.zip; // Ajouté
            _countryController.text = user.country; // Ajouté
            _howwemetController.text = user.howwemet; // Ajouté
            _selectedCategories.value = Set<String>.from(user.preferences);
            print('User preferences: ${user.preferences}');
            print('Selected categories: ${_selectedCategories.value}');
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Erreur lors de la récupération des données utilisateur')),
          );
        }
      } else if (role == 'organizer') {
        OrganizerModel? organizer = await OrganizerService().getOrganizerInfo(token);
        if (organizer != null) {
          setState(() {
            _organizer = organizer;
            _nameController.text = organizer.lastName;
            _firstNameController.text = organizer.firstName;
            _phoneController.text = organizer.phone;
            _emailController.text = organizer.email;
            profilePicUrl = organizer.profilePicture ?? "";
            _organizationNameController.text = organizer.organizationName;
            _websiteController.text = organizer.website;
            _addressController.text = organizer.address;
            _cityController.text = organizer.city;
            _zipController.text = organizer.zip;
            _countryController.text = organizer.country;
            _howwemetController.text = organizer.howwemet;
            _selectedSocialMedias.addAll(organizer.socialMedias.keys);
            for (String media in organizer.socialMedias.keys) {
              _socialMediaControllers[media] = TextEditingController(text: organizer.socialMedias[media]);
            }
            _selectedCategories.value = Set<String>.from(organizer.preferences);
            print('Organizer preferences: ${organizer.preferences}');
            print('Selected categories: ${_selectedCategories.value}');
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Erreur lors de la récupération des données organisateur')),
          );
        }
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aucun token d\'authentification ou rôle non trouvé')),
      );
    }
  }

  // Méthode pour sélectionner une photo depuis la galerie
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  // Méthode pour mettre à jour le mot de passe de l'utilisateur
  Future<void> _updatePassword() async {
    final authProvider = Provider.of<my_auth.AuthProvider>(context, listen: false);
    String? token = await authProvider.getIdToken();

    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aucun token d\'authentification trouvé')),
      );
      return;
    }

    String currentPassword = _currentPasswordController.text.trim();
    String newPassword = _newPasswordController.text.trim();
    String confirmNewPassword = _confirmNewPasswordController.text.trim();

    if (newPassword != confirmNewPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Les nouveaux mots de passe ne correspondent pas')),
      );
      return;
    }

    try {
      // Récupérer l'utilisateur actuel
      User? user = FirebaseAuth.instance.currentUser;

      // Re-authentifier l'utilisateur avec son mot de passe actuel
      AuthCredential credential = EmailAuthProvider.credential(
        email: user!.email!,
        password: currentPassword,
      );

      await user.reauthenticateWithCredential(credential);

      // Si la ré-authentification a réussi, mettre à jour le mot de passe
      await user.updatePassword(newPassword);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mot de passe mis à jour avec succès')),
      );
    } on FirebaseAuthException catch (e) {
      if (e.code == 'wrong-password') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Mot de passe actuel incorrect')),
        );
      } else if (e.code == 'weak-password') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Le nouveau mot de passe est trop faible')),
        );
      } else if (e.code == 'requires-recent-login') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Veuillez vous reconnecter et réessayer')),
        );
      } else {
        // Pour les autres erreurs
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Échec de la mise à jour du mot de passe')),
        );
      }
    } catch (e) {
      // Pour toute autre erreur générique
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erreur inattendue lors de la mise à jour du mot de passe')),
      );
    }
  }

  // Méthode pour mettre à jour le profil utilisateur
  Future<void> _updateProfile() async {
    final authProvider = Provider.of<my_auth.AuthProvider>(context, listen: false);
    String? token = await authProvider.getIdToken();
    String? role = authProvider.role;

    if (token == null || role == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aucun token d\'authentification ou rôle non trouvé')),
      );
      return;
    }

    String newProfilePicUrl = profilePicUrl;

    if (_selectedImage != null) {
      // Upload de l'image vers Cloudinary
      String cloudinaryUploadUrl = 'https://api.cloudinary.com/v1_1/${dotenv.env['CLOUDINARY_CLOUD_NAME']}/image/upload';
      String cloudinaryPreset = dotenv.env['CLOUDINARY_PRESET'] ?? '';

      String mimeType = lookupMimeType(_selectedImage!.path) ?? 'image/jpeg';
      var mimeTypeData = mimeType.split('/');

      var request = http.MultipartRequest('POST', Uri.parse(cloudinaryUploadUrl));
      request.fields['upload_preset'] = cloudinaryPreset; // Utiliser la variable d'environnement

      var multipartFile = await http.MultipartFile.fromPath(
        'file',
        _selectedImage!.path,
        contentType: MediaType(mimeTypeData[0], mimeTypeData[1]),
      );

      request.files.add(multipartFile);

      try {
        var response = await request.send();
        var responseData = await response.stream.bytesToString();

        if (response.statusCode == 200) {
          final jsonResponse = jsonDecode(responseData);
          newProfilePicUrl = jsonResponse['secure_url']; // URL de la nouvelle image
          print('Photo de profil mise à jour avec succès : $newProfilePicUrl');
        } else {
          print('Échec de l\'upload de la photo: ${response.statusCode}');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Échec de l\'upload de la photo.')),
          );
          return;
        }
      } catch (e) {
        print('Exception lors de l\'upload de la photo: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erreur lors de l\'upload de la photo.')),
        );
        return;
      }
    }

    // Conversion de la date de naissance de 'dd/MM/yyyy' à 'yyyy-MM-dd' pour le backend
    String? formattedDob;
    if (_dobController.text.isNotEmpty) {
      try {
        DateTime parsedDate = DateFormat('dd/MM/yyyy').parse(_dobController.text);
        formattedDob = DateFormat('yyyy-MM-dd').format(parsedDate);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Format de date invalide.')),
        );
        return;
      }
    }

    // Mise à jour des autres informations (nom, prénom, etc.) avec l'URL de la photo (nouvelle ou existante)
    bool success = false;

    if (role == 'user') {
      // Mise à jour pour les utilisateurs
      Map<String, String> socialMedias = {};
      for (String media in _selectedSocialMedias) {
        String link = _socialMediaControllers[media]?.text ?? '';
        socialMedias[media] = link;
      }

      success = await _userService.updateUserProfile(
        token,
        _nameController.text,
        _firstNameController.text,
        _phoneController.text,
        newProfilePicUrl,
        _selectedCategories.value,
        gender: _genderController.text,
        dob: formattedDob, // Utiliser la date formatée
        city: _cityController.text,
        zip: _zipController.text,
        country: _countryController.text,
        howwemet: _howwemetController.text,
        socialMedias: socialMedias,
      );
    } else if (role == 'organizer') {
      // Mise à jour pour les organisateurs
      Map<String, String> socialMedias = {};
      for (String media in _selectedSocialMedias) {
        String link = _socialMediaControllers[media]?.text ?? '';
        socialMedias[media] = link;
      }

      success = await OrganizerService().updateOrganizerProfile(
        token,
        _nameController.text,
        _firstNameController.text,
        _phoneController.text,
        newProfilePicUrl,
        _organizationNameController.text,
        _websiteController.text,
        _addressController.text,
        _cityController.text,
        _zipController.text,
        _countryController.text,
        _howwemetController.text,
        _selectedCategories.value,
        socialMedias,
      );
    }

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profil mis à jour avec succès.')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Échec de la mise à jour du profil.')),
      );
    }
  }

  // Méthode pour gérer la sélection des catégories
  void _toggleCategorySelection(String category) {
    _selectedCategories.value = {..._selectedCategories.value}; // Clone l'ensemble
    if (_selectedCategories.value.contains(category)) {
      _selectedCategories.value.remove(category); // Supprime la catégorie
    } else {
      _selectedCategories.value.add(category); // Ajoute la catégorie
    }
    _selectedCategories.notifyListeners(); // Très important pour notifier la modification
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<my_auth.AuthProvider>(context, listen: false);
    final theme = Theme.of(context);
    String? role = authProvider.role; // Récupérer le rôle

    // Liste des pays (vous pouvez utiliser un package ou une liste plus complète)
    final List<String> countryList = ['France', 'Belgique', 'Suisse', 'Canada', 'Espagne', 'Autre'];

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 85,
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.iconTheme.color),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        centerTitle: true,
        title: Text(
          'Mes Informations',
          style: theme.textTheme.titleLarge?.copyWith(
            fontSize: 24,
            fontFamily: 'Sora',
            fontWeight: FontWeight.w900,
            color: theme.appBarTheme.titleTextStyle?.color ?? Colors.white,
          ),
        ),
      ),
      body: (_user == null && _organizer == null)
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 20),

                  // Avatar modifiable
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundImage: _selectedImage != null
                            ? FileImage(_selectedImage!)
                            : (profilePicUrl.isNotEmpty)
                                ? NetworkImage(profilePicUrl)
                                : const AssetImage('lib/assets/images/default_profile_pic.png') as ImageProvider,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: InkWell(
                          onTap: _pickImage,
                          child: Container(
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.black,
                            ),
                            padding: const EdgeInsets.all(6),
                            child: const Icon(
                              Icons.edit,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Modifier',
                    style: TextStyle(
                      color: Colors.black,
                      fontFamily: 'Poppins',
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Champs communs pour User et Organizer
                  _buildProfileInput('Nom', _nameController),
                  const SizedBox(height: 15),
                  _buildProfileInput('Prénom', _firstNameController),
                  const SizedBox(height: 15),
                  _buildProfileInput('Téléphone', _phoneController),
                  const SizedBox(height: 15),
                  _buildProfileInput('E-Mail', _emailController),
                  const SizedBox(height: 15),
                  _buildDropdownField('Comment nous avez-vous connu?', _howwemetController, _howWeMetOptions),
                  const SizedBox(height: 15),

                  // Champs spécifiques en fonction du rôle
                  if (role == 'organizer') ...[
                    _buildProfileInput('Nom de l\'organisation', _organizationNameController),
                    const SizedBox(height: 15),
                    _buildProfileInput('Site Web', _websiteController),
                    const SizedBox(height: 15),
                    _buildProfileInput('Adresse', _addressController),
                    const SizedBox(height: 15),
                    _buildCityAutocompleteField('Ville', _cityController),
                    const SizedBox(height: 15),
                    _buildNumericInput('Code Postal', _zipController),
                    const SizedBox(height: 15),
                    _buildDropdownField('Pays', _countryController, countryList),
                    const SizedBox(height: 15),
                    _buildMultiSelectField('Réseaux Sociaux', _selectedSocialMedias),
                    const SizedBox(height: 15),
                  ] else if (role == 'user') ...[
                    _buildDropdownField('Genre', _genderController, ['Homme', 'Femme', 'Autre']),
                    const SizedBox(height: 15),
                    _buildDatePickerField('Date de naissance', _dobController),
                    const SizedBox(height: 15),
                    _buildCityAutocompleteField('Ville (Où habitez-vous?)', _cityController),
                    const SizedBox(height: 15),
                    _buildNumericInput('Code Postal', _zipController),
                    const SizedBox(height: 15),
                    _buildDropdownField('Pays', _countryController, countryList),
                    const SizedBox(height: 15),
                  ],

                  const SizedBox(height: 50),

                  // Section pour les catégories préférées
                  _buildCategorySection(),

                  const SizedBox(height: 30),

                  // Boutons "Annuler" et "Modifier"
                  Row(
                    children: [
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: Text(
                          'Annuler',
                          style: TextStyle(
                            color: Theme.of(context).textTheme.bodyLarge?.color,
                            fontFamily: 'Poppins',
                            fontSize: 14,
                            decoration: TextDecoration.underline, // Souligné
                          ),
                        ),
                      ),
                      const Spacer(),
                      ElevatedButton(
                        onPressed: _updateProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(50),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 50,
                            vertical: 20,
                          ),
                        ),
                        child: const Text(
                          'Mettre à jour',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            fontFamily: 'Poppins',
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Ligne de séparation avec ombre pour effet d'élévation
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 30),
                    child: Divider(
                      color: Colors.black.withOpacity(0.2), // Ligne fine, légère
                      thickness: 1,
                      height: 1,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Section du changement de mot de passe modernisée
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50, // Couleur de fond subtile pour la section
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.grey.shade300), // Bordure fine
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          spreadRadius: 2,
                          blurRadius: 10,
                          offset: const Offset(0, 5), // Ombre douce sous le container
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Titre avec fond différent pour le mettre en avant
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                          decoration: BoxDecoration(
                            color: Colors.blueGrey.shade900, // Couleur de fond du titre
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(20),
                              topRight: Radius.circular(20),
                            ),
                          ),
                          child: const Text(
                            'Changer le mot de passe',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Poppins',
                              color: Colors.white, // Couleur du texte pour contraster
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Champs pour le mot de passe
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildPasswordInput('Mot de passe actuel', _currentPasswordController),
                              const SizedBox(height: 15),
                              _buildPasswordInput('Nouveau mot de passe', _newPasswordController),
                              const SizedBox(height: 15),
                              _buildPasswordInput('Confirmer nouveau mot de passe', _confirmNewPasswordController),
                            ],
                          ),
                        ),

                        const SizedBox(height: 30),

                        // Bouton pour mettre à jour le mot de passe
                        Center(
                          child: ElevatedButton(
                            onPressed: _updatePassword,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blueGrey.shade900, // Couleur de fond du bouton
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30), // Bordures très arrondies
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 60,
                                vertical: 18,
                              ),
                              shadowColor: Colors.transparent, // Désactivation de l'ombre pour un style plus plat
                            ),
                            child: const Text(
                              'Mettre à jour',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'Poppins',
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),

                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 30),
                    child: Divider(
                      color: Colors.black.withOpacity(0.2), // Ligne fine, légère
                      thickness: 1,
                      height: 1,
                    ),
                  ),

                  // Bouton de suppression du compte
                  ElevatedButton(
                    onPressed: () => _confirmAccountDeletion(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent.shade200, // Rouge moins vif, plus élégant
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30), // Bordures légèrement moins arrondies pour plus de modernité
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 40,
                        vertical: 18,
                      ),
                      elevation: 3, // Légère élévation pour un effet d'ombre discret
                      shadowColor: Colors.black26, // Ombre subtile pour donner du relief
                    ),
                    child: const Text(
                      'Supprimer le compte',
                      style: TextStyle(
                        fontSize: 16, // Taille de texte légèrement réduite pour plus de sobriété
                        fontWeight: FontWeight.w700, // Un peu moins en gras pour plus d'élégance
                        fontFamily: 'Poppins',
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
    );
  }

  // Fonction pour générer la section des catégories
  Widget _buildCategorySection() {
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Mes événements préférés ❤️',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 20),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
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
                return _CategoryTile(
                  title: category['title']!,
                  imageUrl: category['image']!,
                  isSelected: selectedCategories.contains(category['title']),
                  onTap: () => _toggleCategorySelection(category['title']!),
                );
              },
            );
          },
        ),
      ],
    );
  }

  // Fonction pour générer un champ de profil avec TextFormField
  Widget _buildProfileInput(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            fontFamily: 'Poppins',
          ),
        ),
        const SizedBox(height: 5),
        TextFormField(
          controller: controller,
          decoration: const InputDecoration(
            border: UnderlineInputBorder(),
          ),
        ),
      ],
    );
  }

  // Méthode pour générer un champ DropdownButtonFormField
  Widget _buildDropdownField(String label, TextEditingController controller, List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            fontFamily: 'Poppins',
          ),
        ),
        const SizedBox(height: 5),
        DropdownButtonFormField<String>(
          value: controller.text.isNotEmpty && items.contains(controller.text) ? controller.text : null,
          items: items.map((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
          onChanged: (String? newValue) {
            setState(() {
              controller.text = newValue ?? '';
            });
          },
          decoration: const InputDecoration(
            border: UnderlineInputBorder(),
          ),
        ),
      ],
    );
  }

  // Méthode pour générer un champ DatePicker
  Widget _buildDatePickerField(String label, TextEditingController controller) {
    return GestureDetector(
      onTap: () async {
        DateTime? pickedDate = await showDatePicker(
          context: context,
          initialDate: controller.text.isNotEmpty
              ? DateFormat('yyyy-MM-dd').parse(controller.text)
              : DateTime.now(),
          firstDate: DateTime(1900),
          lastDate: DateTime.now(),
        );
        if (pickedDate != null) {
          controller.text = DateFormat('yyyy-MM-dd').format(pickedDate);
        }
      },
      child: AbsorbPointer(
        child: _buildProfileInput(label, controller),
      ),
    );
  }

  // Méthode pour générer un champ TextFormField pour la ville sans autocomplétion
  Widget _buildCityAutocompleteField(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            fontFamily: 'Poppins',
          ),
        ),
        const SizedBox(height: 5),
        TextFormField(
          controller: controller,
          decoration: const InputDecoration(
            border: UnderlineInputBorder(),
          ),
        ),
      ],
    );
  }

  // Méthode pour générer un champ numérique
  Widget _buildNumericInput(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            fontFamily: 'Poppins',
          ),
        ),
        const SizedBox(height: 5),
        TextFormField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            border: UnderlineInputBorder(),
          ),
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        ),
      ],
    );
  }

  // Méthode pour générer un champ MultiSelect pour les réseaux sociaux
  Widget _buildMultiSelectField(String label, List<String> selectedItems) {
    final socialMediaOptions = [
      'Facebook',
      'Instagram',
      'Twitter',
      'LinkedIn',
      'YouTube',
      'TikTok',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            fontFamily: 'Poppins',
          ),
        ),
        const SizedBox(height: 5),
        MultiSelectDialogField(
          items: socialMediaOptions.map((e) => MultiSelectItem<String>(e, e)).toList(),
          title: const Text('Sélectionnez vos réseaux sociaux'),
          selectedColor: Colors.blue,
          buttonText: Text(
            selectedItems.isEmpty ? 'Choisir' : selectedItems.join(', '),
            style: const TextStyle(
              fontSize: 16,
              fontFamily: 'Poppins',
            ),
          ),
          onConfirm: (values) {
            setState(() {
              // Gérer les réseaux sociaux non sélectionnés
              List<String> removedItems = selectedItems.where((item) => !values.contains(item)).toList();
              for (String item in removedItems) {
                _socialMediaControllers[item]?.dispose();
                _socialMediaControllers.remove(item);
              }
              selectedItems.clear();
              selectedItems.addAll(List<String>.from(values));

              // Initialiser les contrôleurs pour les nouveaux réseaux sociaux sélectionnés
              for (String item in selectedItems) {
                if (!_socialMediaControllers.containsKey(item)) {
                  _socialMediaControllers[item] = TextEditingController();
                }
              }
            });
          },
          initialValue: selectedItems,
        ),
        // Afficher les champs de saisie pour les réseaux sociaux sélectionnés
        ...selectedItems.map((platform) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              Text(
                'Lien $platform',
                style: const TextStyle(
                  fontWeight: FontWeight.normal,
                  fontSize: 14,
                  fontFamily: 'Poppins',
                ),
              ),
              TextFormField(
                controller: _socialMediaControllers[platform],
                decoration: InputDecoration(
                  hintText: 'Entrez le lien de votre $platform',
                ),
              ),
            ],
          );
        }).toList(),
      ],
    );
  }

  // Fonction pour générer un champ de mot de passe
  Widget _buildPasswordInput(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            fontFamily: 'Poppins',
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 5),
        TextFormField(
          controller: controller,
          obscureText: true,
          decoration: const InputDecoration(
            border: UnderlineInputBorder(),
          ),
          style: const TextStyle(
            color: Colors.black,
          ),
        ),
      ],
    );
  }

  // Méthode pour afficher une boîte de dialogue de confirmation avant suppression du compte
  void _confirmAccountDeletion(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Confirmer la suppression"),
          content: const Text("Êtes-vous sûr de vouloir supprimer votre compte ? Cette action est irréversible."),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Fermer la boîte de dialogue
              },
              child: const Text("Annuler"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(); // Fermer la boîte de dialogue
                _deleteAccount(); // Appeler la méthode de suppression
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: const Text("Confirmer"),
            ),
          ],
        );
      },
    );
  }

  // Méthode pour supprimer le compte utilisateur
  Future<void> _deleteAccount() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await user.delete(); // Supprimer l'utilisateur de Firebase
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Compte supprimé avec succès.')),
        );
        // Redirection vers la page de connexion ou autre
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Veuillez vous reconnecter et réessayer.')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erreur lors de la suppression du compte.')),
        );
      }
    }
  }
}

// Widget pour afficher chaque catégorie dans la grille
class _CategoryTile extends StatelessWidget {
  final String title;
  final String imageUrl;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryTile({
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
