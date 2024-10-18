// lib/pages/login_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import './splash_screen_welcome.dart';
import './forgot_password_page.dart';
import '../providers/auth_provider.dart' as my_auth; 

// Styles constants pour le texte
const TextStyle _labelTextStyle = TextStyle(color: Colors.white);
const TextStyle _hintTextStyle = TextStyle(color: Colors.white54);
const TextStyle _buttonTextStyle = TextStyle(
  fontFamily: 'Poppins',
  fontSize: 20,
  fontWeight: FontWeight.w700,
  color: Colors.white,
);

// Bordures communes pour les champs de saisie
final _borderStyle = OutlineInputBorder(
  borderSide: const BorderSide(color: Colors.white, width: 1.5),
  borderRadius: BorderRadius.circular(50),
);
final _focusedBorderStyle = OutlineInputBorder(
  borderSide: const BorderSide(color: Colors.orange, width: 2),
  borderRadius: BorderRadius.circular(50),
);

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FocusNode _emailFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();
  final _formKey = GlobalKey<FormState>();
  final ValueNotifier<bool> _isLoading = ValueNotifier(false);
  bool _obscurePassword = true; // Gestion de la visibilité du mot de passe

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _isLoading.dispose();
    super.dispose();
  }

  Future<void> _loginUser() async {
    if (!_formKey.currentState!.validate()) return;

    _isLoading.value = true;

    try {
      final authProvider = Provider.of<my_auth.AuthProvider>(context, listen: false);
      await authProvider.signIn(_emailController.text.trim(), _passwordController.text.trim());

      String? firebaseUid = authProvider.user?.uid ?? "";
      print("Firebase UID récupéré: $firebaseUid");

      final token = await authProvider.getIdToken();

      if (token == null) {
        _showErrorDialog(context, 'Impossible de récupérer le token d\'authentification.');
        return;
      }

      final response = await http.post(
        Uri.parse('http://10.0.2.2:3000/auth/login'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'email': _emailController.text.trim(),
          'firebaseUid': firebaseUid,
        }),
      );

      if (response.statusCode == 200) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => SplashScreenWelcome()),
        );
      } else {
        _showErrorDialog(context, jsonDecode(response.body)['message'] ?? 'Erreur de connexion');
      }
    } on FirebaseAuthException catch (e) {
      _showErrorDialog(context, e.message ?? 'Erreur de connexion');
    } catch (e) {
      _showErrorDialog(context, 'Erreur de connexion');
    } finally {
      _isLoading.value = false;
    }
  }

  // Afficher un dialogue d'erreur
  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Erreur de connexion'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  // Widget réutilisable pour les champs de saisie
  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    required String hintText,
    required FocusNode focusNode,
    required bool obscureText,
    required FormFieldValidator<String>? validator,
    required IconData iconData,
    VoidCallback? onSuffixTap,
  }) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      obscureText: obscureText,
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        labelStyle: _labelTextStyle,
        hintStyle: _hintTextStyle,
        enabledBorder: _borderStyle,
        focusedBorder: _focusedBorderStyle,
        filled: true,
        fillColor: Colors.white.withOpacity(0.1),
        contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
        suffixIcon: onSuffixTap != null
            ? GestureDetector(
                onTap: onSuffixTap,
                child: Icon(
                  obscureText ? Icons.visibility : Icons.visibility_off,
                  color: Colors.white54,
                ),
              )
            : Icon(iconData, color: Colors.white54),
      ),
      style: const TextStyle(color: Colors.white),
      validator: validator,
      textInputAction: obscureText ? TextInputAction.done : TextInputAction.next,
      onFieldSubmitted: (_) {
        if (!obscureText) {
          FocusScope.of(context).requestFocus(_passwordFocus);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,  // Permet de gérer l'apparition du clavier sans débordement
      body: SingleChildScrollView(  // Ajout de défilement
        child: Container(
          height: MediaQuery.of(context).size.height,  // S'assurer que le conteneur occupe tout l'écran
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
          child: Stack(
            children: [
              Positioned(
                top: 50,
                left: 20,
                child: GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
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
              ),
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(top: 100, left: 20, right: 20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 100),  // Espace supplémentaire pour gérer le clavier
                        const Text(
                          'CONNEXION',
                          style: TextStyle(
                            fontFamily: 'Sora',
                            fontSize: 44,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 50),

                        // Champ E-mail
                        _buildTextField(
                          controller: _emailController,
                          labelText: 'E-mail',
                          hintText: 'contact@wazaa.com',
                          focusNode: _emailFocus,
                          obscureText: false,
                          validator: (value) {
                            if (value == null || value.isEmpty || !value.contains('@')) {
                              return 'Veuillez entrer une adresse e-mail valide';
                            }
                            return null;
                          },
                          iconData: Icons.email,
                        ),
                        const SizedBox(height: 20),

                        // Champ Mot de passe avec icône de visibilité
                        _buildTextField(
                          controller: _passwordController,
                          labelText: 'Mot de passe',
                          hintText: '********',
                          focusNode: _passwordFocus,
                          obscureText: _obscurePassword,
                          validator: (value) {
                            if (value == null || value.length < 6) {
                              return 'Le mot de passe doit comporter au moins 6 caractères';
                            }
                            return null;
                          },
                          iconData: Icons.lock,
                          onSuffixTap: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                        const SizedBox(height: 40),

                        // Bouton Connexion avec dégradé
                        ValueListenableBuilder<bool>(
                          valueListenable: _isLoading,
                          builder: (context, isLoading, child) {
                            return Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF83402F), Color(0xFFEA603E)],
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                ),
                                borderRadius: BorderRadius.circular(50),
                              ),
                              child: ElevatedButton(
                                onPressed: isLoading ? null : _loginUser,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  padding: const EdgeInsets.symmetric(vertical: 20),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(50),
                                  ),
                                ),
                                child: isLoading
                                    ? const CircularProgressIndicator()
                                    : const Text(
                                        'Connexion',
                                        style: _buttonTextStyle,
                                      ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 20),

                        Align(
                          alignment: Alignment.bottomCenter,
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 20),
                            child: TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => const ForgotPasswordPage()),
                                );
                              },
                              child: const Text(
                                'Vous avez perdu vos identifiants ?',
                                style: TextStyle(
                                  color: Colors.white,
                                  decoration: TextDecoration.underline,
                                  decorationThickness: 1.2,
                                  height: 3,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
