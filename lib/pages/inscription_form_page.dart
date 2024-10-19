import 'package:flutter/material.dart';
import 'inscription_page.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../services/firebase_service.dart';

class InscriptionFormPage extends StatefulWidget {
  const InscriptionFormPage({
    Key? key,
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

  final _formKey = GlobalKey<FormState>(); // Clé globale pour la validation du formulaire
  final ValueNotifier<bool> _isLoading = ValueNotifier(false); // Utilisation de ValueNotifier pour le loader

  // Ajouter des ValueNotifier pour chaque champ pour suivre l'interaction utilisateur
  final ValueNotifier<bool> _hasInteractedWithNom = ValueNotifier(false);
  final ValueNotifier<bool> _hasInteractedWithPrenom = ValueNotifier(false);
  final ValueNotifier<bool> _hasInteractedWithTelephone = ValueNotifier(false);
  final ValueNotifier<bool> _hasInteractedWithEmail = ValueNotifier(false);
  final ValueNotifier<bool> _hasInteractedWithMotDePasse = ValueNotifier(false);
  final ValueNotifier<bool> _hasInteractedWithConfirmer = ValueNotifier(false);

  @override
  void dispose() {
    // Ne pas oublier de nettoyer les controllers et ValueNotifier
    _nomController.dispose();
    _prenomController.dispose();
    _telephoneController.dispose();
    _emailController.dispose();
    _motDePasseController.dispose();
    _confirmerController.dispose();
    _isLoading.dispose();
    _hasInteractedWithNom.dispose();
    _hasInteractedWithPrenom.dispose();
    _hasInteractedWithTelephone.dispose();
    _hasInteractedWithEmail.dispose();
    _hasInteractedWithMotDePasse.dispose();
    _hasInteractedWithConfirmer.dispose();
    super.dispose();
  }

  // Fonction pour valider les champs
  bool _isFieldValid(String? value, String? Function(String?)? validator) {
    if (validator != null) {
      return validator(value) == null;
    }
    return false;
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

                    // Titre "INSCRIPTION"
                    const Text(
                      'INSCRIPTION',
                      style: TextStyle(
                        fontFamily: 'Sora',
                        fontSize: 38,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 30), // Espacement

                    // Champs du formulaire stylisés
                    ValueListenableBuilder<bool>(
                      valueListenable: _hasInteractedWithNom,
                      builder: (context, hasInteracted, _) {
                        return StyledTextField(
                          label: 'Nom',
                          controller: _nomController,
                          placeholder: 'Dupont',
                          validator: (value) => value!.isEmpty ? 'Veuillez entrer votre nom' : null,
                          isFieldValid: hasInteracted && _isFieldValid(_nomController.text, (value) => value!.isEmpty ? 'Veuillez entrer votre nom' : null),
                          onChanged: () {
                            _hasInteractedWithNom.value = true;
                          },
                        );
                      },
                    ),
                    ValueListenableBuilder<bool>(
                      valueListenable: _hasInteractedWithPrenom,
                      builder: (context, hasInteracted, _) {
                        return StyledTextField(
                          label: 'Prénom',
                          controller: _prenomController,
                          placeholder: 'Adrien',
                          validator: (value) => value!.isEmpty ? 'Veuillez entrer votre prénom' : null,
                          isFieldValid: hasInteracted && _isFieldValid(_prenomController.text, (value) => value!.isEmpty ? 'Veuillez entrer votre prénom' : null),
                          onChanged: () {
                            _hasInteractedWithPrenom.value = true;
                          },
                        );
                      },
                    ),
                    ValueListenableBuilder<bool>(
                      valueListenable: _hasInteractedWithTelephone,
                      builder: (context, hasInteracted, _) {
                        return StyledTextField(
                          label: 'Téléphone',
                          controller: _telephoneController,
                          placeholder: '0601020304',
                          validator: (value) => value!.length == 10 ? null : 'Numéro de téléphone invalide',
                          isFieldValid: hasInteracted && _isFieldValid(_telephoneController.text, (value) => value!.length == 10 ? null : 'Numéro de téléphone invalide'),
                          onChanged: () {
                            _hasInteractedWithTelephone.value = true;
                          },
                        );
                      },
                    ),
                    ValueListenableBuilder<bool>(
                      valueListenable: _hasInteractedWithEmail,
                      builder: (context, hasInteracted, _) {
                        return StyledTextField(
                          label: 'E-mail',
                          controller: _emailController,
                          placeholder: 'contact@wazaa.app',
                          validator: (value) => (value!.contains('@') && value.contains('.'))
                              ? null
                              : 'Veuillez entrer un email valide',
                          isFieldValid: hasInteracted && _isFieldValid(_emailController.text, (value) => (value!.contains('@') && value.contains('.')) ? null : 'Veuillez entrer un email valide'),
                          onChanged: () {
                            _hasInteractedWithEmail.value = true;
                          },
                        );
                      },
                    ),
                    ValueListenableBuilder<bool>(
                      valueListenable: _hasInteractedWithMotDePasse,
                      builder: (context, hasInteracted, _) {
                        return StyledTextField(
                          label: 'Mot de passe',
                          controller: _motDePasseController,
                          obscureText: true,
                          placeholder: '************',
                          validator: (value) =>
                              value!.length >= 6 ? null : 'Le mot de passe doit comporter au moins 6 caractères',
                          isFieldValid: hasInteracted && _isFieldValid(_motDePasseController.text, (value) => value!.length >= 6 ? null : 'Le mot de passe doit comporter au moins 6 caractères'),
                          onChanged: () {
                            _hasInteractedWithMotDePasse.value = true;
                          },
                        );
                      },
                    ),
                    ValueListenableBuilder<bool>(
                      valueListenable: _hasInteractedWithConfirmer,
                      builder: (context, hasInteracted, _) {
                        return StyledTextField(
                          label: 'Confirmer',
                          controller: _confirmerController,
                          obscureText: true,
                          placeholder: '************',
                          validator: (value) =>
                              value == _motDePasseController.text ? null : 'Les mots de passe ne correspondent pas',
                          isFieldValid: hasInteracted && _isFieldValid(_confirmerController.text, (value) => value == _motDePasseController.text ? null : 'Les mots de passe ne correspondent pas'),
                          onChanged: () {
                            _hasInteractedWithConfirmer.value = true;
                          },
                        );
                      },
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
                                  onPressed: () async {
                                    if (_formKey.currentState!.validate()) {
                                      _isLoading.value = true;
                                      try {
                                        final firebaseService = FirebaseService();
                                        final user = await firebaseService.signUpWithEmail(
                                          _emailController.text,
                                          _motDePasseController.text,
                                        );

                                        if (user != null) {
                                          final response = await http.post(
                                            Uri.parse('https://wazaapp-backend-e95231584d01.herokuapp.com/auth/signup'),
                                            headers: {'Content-Type': 'application/json'},
                                            body: jsonEncode({
                                              'firebaseId': user.uid,
                                              'firstName': _prenomController.text,
                                              'lastName': _nomController.text,
                                              'email': _emailController.text,
                                              'phone': _telephoneController.text,
                                              'profilePicture': null,
                                            }),
                                          );

                                          if (response.statusCode == 201) {
                                            Navigator.pushReplacement(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) => InscriptionPage(userName: _prenomController.text),
                                              ),
                                            );
                                          } else {
                                            print('Erreur lors de l\'inscription backend: ${response.body}');
                                          }
                                        }
                                      } catch (e) {
                                        print('Erreur lors de l\'inscription: $e');
                                      } finally {
                                        _isLoading.value = false;
                                      }
                                    }
                                  },
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
}

// Widget séparé pour les champs du formulaire avec icône de validation
class StyledTextField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool obscureText;
  final String? placeholder;
  final String? Function(String?)? validator;
  final bool isFieldValid;
  final VoidCallback? onChanged;

  const StyledTextField({
    Key? key,
    required this.label,
    required this.controller,
    this.obscureText = false,
    this.placeholder,
    this.validator,
    required this.isFieldValid,
    this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
            validator: validator, // Validation incluse
            onChanged: (_) {
              if (onChanged != null) {
                onChanged!();
              }
            },
          ),
        ],
      ),
    );
  }
}
