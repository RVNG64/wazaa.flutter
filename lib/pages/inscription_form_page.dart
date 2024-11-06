// lib/pages/inscription_form_page.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'inscription_page.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../services/firebase_service.dart';

class InscriptionFormPage extends StatefulWidget {
  final String selectedRole;

  const InscriptionFormPage({
    Key? key,
    required this.selectedRole,
  }) : super(key: key);

  @override
  _InscriptionFormPageState createState() => _InscriptionFormPageState();
}

class _InscriptionFormPageState extends State<InscriptionFormPage> {
  // Controllers pour capturer les valeurs des champs de texte
  final TextEditingController _nomController = TextEditingController();
  final TextEditingController _prenomController = TextEditingController();
  final TextEditingController _telephoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _motDePasseController = TextEditingController();
  final TextEditingController _confirmerController = TextEditingController();
  
  // Contrôleurs supplémentaires pour les organisateurs
  final TextEditingController _companyNameController = TextEditingController();

  final _formKey = GlobalKey<FormState>(); // Clé globale pour la validation du formulaire
  final ValueNotifier<bool> _isLoading = ValueNotifier(false); // Utilisation de ValueNotifier pour le loader

  // Ajouter des ValueNotifier pour chaque champ pour suivre l'interaction utilisateur
  final ValueNotifier<bool> _hasInteractedWithNom = ValueNotifier(false);
  final ValueNotifier<bool> _hasInteractedWithPrenom = ValueNotifier(false);
  final ValueNotifier<bool> _hasInteractedWithTelephone = ValueNotifier(false);
  final ValueNotifier<bool> _hasInteractedWithEmail = ValueNotifier(false);
  final ValueNotifier<bool> _hasInteractedWithMotDePasse = ValueNotifier(false);
  final ValueNotifier<bool> _hasInteractedWithConfirmer = ValueNotifier(false);
  final ValueNotifier<bool> _hasInteractedWithCompanyName = ValueNotifier(false);

  @override
  void dispose() {
    // Ne pas oublier de nettoyer les controllers et ValueNotifier
    _nomController.dispose();
    _prenomController.dispose();
    _telephoneController.dispose();
    _emailController.dispose();
    _motDePasseController.dispose();
    _confirmerController.dispose();
    _companyNameController.dispose();
    _isLoading.dispose();
    _hasInteractedWithNom.dispose();
    _hasInteractedWithPrenom.dispose();
    _hasInteractedWithTelephone.dispose();
    _hasInteractedWithEmail.dispose();
    _hasInteractedWithMotDePasse.dispose();
    _hasInteractedWithConfirmer.dispose();
    _hasInteractedWithCompanyName.dispose();
    super.dispose();
  }

  // Fonction pour valider les champs
  bool _isFieldValid(String? value, String? Function(String?)? validator) {
    if (validator != null) {
      return validator(value) == null;
    }
    return false;
  }

  void _showErrorMessage(String message) {
    Future.delayed(Duration.zero, () {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    String pageTitle = widget.selectedRole == 'Organisateur' ? 'INSCRIPTION ORGANISATEUR' : 'INSCRIPTION';

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.2,
            colors: [
              Color(0xFF205893), // Centre
              Color(0xFF16141E), // Extérieur
            ],
          ),
        ),
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height, // S'assurer que le contenu prend au moins toute la hauteur
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Form(
                key: _formKey, // Ajout du formulaire pour gérer la validation
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 50), // Espacement du haut

                    // Flèche retour
                    Padding(
                      padding: const EdgeInsets.only(left: 5),
                      child: GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: Container(
                          width: 30,
                          height: 30,
                          decoration: const BoxDecoration(
                            color: Colors.white, // Fond blanc
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.arrow_back_ios_new,
                            color: Color(0xFF205893),
                            size: 20,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 30),

                    // Titre de la page
                    Text(
                      pageTitle,
                      style: const TextStyle(
                        fontFamily: 'Sora',
                        fontSize: 38,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 30), // Espacement

                    // Champs du formulaire stylisés
                    // Champs supplémentaires pour les organisateurs
                    if (widget.selectedRole == 'Organisateur') ...[
                      _buildTextField(
                        label: 'Organisation',
                        controller: _companyNameController,
                        placeholder: 'Nom de votre organisation',
                        validator: (value) => value!.isEmpty ? 'Veuillez entrer le nom de votre organisation' : null,
                        hasInteractedNotifier: _hasInteractedWithCompanyName,
                      ),
                    ],

                    // Champs communs
                    _buildTextField(
                      label: 'Nom',
                      controller: _nomController,
                      placeholder: 'Dupont',
                      validator: (value) => value!.isEmpty ? 'Veuillez entrer votre nom' : null,
                      hasInteractedNotifier: _hasInteractedWithNom,
                    ),
                    _buildTextField(
                      label: 'Prénom',
                      controller: _prenomController,
                      placeholder: 'Adrien',
                      validator: (value) => value!.isEmpty ? 'Veuillez entrer votre prénom' : null,
                      hasInteractedNotifier: _hasInteractedWithPrenom,
                    ),
                    _buildTextField(
                      label: 'Téléphone',
                      controller: _telephoneController,
                      placeholder: '0601020304',
                      validator: (value) => value!.length == 10 ? null : 'Numéro de téléphone invalide',
                      hasInteractedNotifier: _hasInteractedWithTelephone,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly, // Empêche l'entrée de lettres
                      ],
                    ),
                    _buildTextField(
                      label: 'E-mail',
                      controller: _emailController,
                      placeholder: 'hello@wazaa.app',
                      validator: (value) => (value!.contains('@') && value.contains('.'))
                          ? null
                          : 'Veuillez entrer un email valide',
                      hasInteractedNotifier: _hasInteractedWithEmail,
                    ),
                    _buildTextField(
                      label: 'Mot de passe',
                      controller: _motDePasseController,
                      obscureText: true,
                      placeholder: '************',
                      validator: (value) =>
                          value!.length >= 6 ? null : 'Le mot de passe doit comporter au moins 6 caractères',
                      hasInteractedNotifier: _hasInteractedWithMotDePasse,
                    ),
                    _buildTextField(
                      label: 'Confirmer',
                      controller: _confirmerController,
                      obscureText: true,
                      placeholder: '************',
                      validator: (value) =>
                          value == _motDePasseController.text ? null : 'Les mots de passe ne correspondent pas',
                      hasInteractedNotifier: _hasInteractedWithConfirmer,
                    ),

                    const SizedBox(height: 20),

                    // Bouton "Suivant" stylisé avec ValueListenableBuilder pour gérer le loader
                    Center(
                      child: ValueListenableBuilder<bool>(
                        valueListenable: _isLoading,
                        builder: (context, isLoading, child) {
                          return isLoading
                              ? const CircularProgressIndicator() // Affiche un loader si l'inscription est en cours
                              : OutlinedButton(
                                  onPressed: _handleSignUp,
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
                        },
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Méthode pour construire les champs de texte
  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    bool obscureText = false,
    String? placeholder,
    String? Function(String?)? validator,
    required ValueNotifier<bool> hasInteractedNotifier,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return ValueListenableBuilder<bool>(
      valueListenable: hasInteractedNotifier,
      builder: (context, hasInteracted, _) {
        bool isFieldValid = hasInteracted && _isFieldValid(controller.text, validator);

        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontFamily: 'Sora',
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              TextFormField(
                controller: controller,
                obscureText: obscureText,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 16,
                  color: Colors.white,
                ),
                decoration: InputDecoration(
                  hintText: placeholder,
                  hintStyle: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 15,
                    color: Colors.grey,
                  ),
                  enabledBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white),
                  ),
                  focusedBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white),
                  ),
                  suffixIcon: isFieldValid
                      ? const Icon(Icons.check_circle, color: Colors.green)
                      : null,
                ),
                validator: validator,
                onChanged: (_) {
                  hasInteractedNotifier.value = true;
                },
                inputFormatters: inputFormatters,
              ),
            ],
          ),
        );
      },
    );
  }

  // Méthode pour gérer l'inscription
  Future<void> _handleSignUp() async {
    if (_formKey.currentState!.validate()) {
      _isLoading.value = true;
      try {
        final firebaseService = FirebaseService();
        final user = await firebaseService.signUpWithEmail(
          _emailController.text,
          _motDePasseController.text,
        );

        if (user != null) {
          // Construire le corps de la requête
          Map<String, dynamic> requestBody = {
            'firebaseId': user.uid,
            'firstName': _prenomController.text,
            'lastName': _nomController.text,
            'email': _emailController.text,
            'phone': _telephoneController.text,
            'profilePicture': null,
          };

          // Déterminer l'endpoint en fonction du rôle
          String endpoint = 'http://10.0.2.2:3000/auth/signup';

          // Ajouter des champs spécifiques aux organisateurs
          if (widget.selectedRole == 'Organisateur') {
            requestBody.addAll({
              'organizationName': _companyNameController.text,
            });
            // Changer l'endpoint pour les organisateurs
            endpoint = 'http://10.0.2.2:3000/auth/signup/organizer';
          } else {
            // Ajouter le rôle pour les utilisateurs
            requestBody['role'] = 'user';
          }

          final response = await http.post(
            Uri.parse(endpoint),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(requestBody),
          );

          if (response.statusCode == 201) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => InscriptionPage(userName: _prenomController.text),
              ),
            );
          } else {
            _showErrorMessage('Erreur lors de l\'inscription backend : ${response.body}');
          }
        }
      } on FirebaseAuthException catch (e) {
        // Vérifiez si l'erreur correspond à une adresse e-mail déjà utilisée
        if (e.code == 'email-already-in-use') {
          _showErrorMessage('Cette adresse e-mail est déjà utilisée. Veuillez en utiliser une autre.');
        } else {
          _showErrorMessage('Erreur lors de l\'inscription : ${e.message}');
        }
      } catch (e) {
        _showErrorMessage('Erreur inconnue : $e');
      } finally {
        _isLoading.value = false;
      }
    }
  }
}
