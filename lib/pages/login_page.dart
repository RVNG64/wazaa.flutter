import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import './splash_screen_welcome.dart';
import './forgot_password_page.dart';
import '../providers/auth_provider.dart' as my_auth;

const TextStyle _labelTextStyle = TextStyle(color: Colors.white);
const TextStyle _hintTextStyle = TextStyle(color: Colors.white54);
const TextStyle _buttonTextStyle = TextStyle(
  fontFamily: 'Poppins',
  fontSize: 20,
  fontWeight: FontWeight.w700,
  color: Colors.white,
);

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
  late TextEditingController _emailController; // Retirer 'final' et utiliser 'late'
  final TextEditingController _passwordController = TextEditingController();

  final FocusNode _emailFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();

  final _formKey = GlobalKey<FormState>();
  final ValueNotifier<bool> _isLoading = ValueNotifier(false);
  bool _obscurePassword = true;
  bool _rememberMe = false;

  List<String> _savedEmails = []; // Liste des emails sauvegardés

  @override
  void initState() {
    super.initState();
    _loadSavedEmails(); // Charger la liste des emails enregistrés
  }

  Future<void> _loadSavedEmails() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? savedEmails = prefs.getStringList('saved_emails');
    if (savedEmails != null) {
      setState(() {
        _savedEmails = savedEmails;
      });
    }
  }

  Future<void> _addEmailToSavedList(String email) async {
    if (!_savedEmails.contains(email)) {
      _savedEmails.add(email);
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('saved_emails', _savedEmails);
    }
  }

  Future<void> _loginUser() async {
    if (!_formKey.currentState!.validate()) return;

    _isLoading.value = true;

    try {
      final authProvider = Provider.of<my_auth.AuthProvider>(context, listen: false);
      await authProvider.signIn(_emailController.text.trim(), _passwordController.text.trim());

      // Récupérer le rôle de l'utilisateur
      await authProvider.fetchUserRole();
      String? role = authProvider.role;

      if (role == null) {
        _showErrorDialog(context, 'Impossible de déterminer le rôle de l\'utilisateur.');
        _isLoading.value = false;
        return;
      }

      // Naviguer en fonction du rôle
      if (role == 'user' || role == 'organizer') {
        await _addEmailToSavedList(_emailController.text.trim());
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => SplashScreenWelcome()),
        );
      } else {
        _showErrorDialog(context, 'Rôle inconnu: $role');
        _isLoading.value = false;
        return;
      }
    } on FirebaseAuthException catch (e) {
      _showErrorDialog(context, 'FirebaseAuthException: ${e.code} - ${e.message}');
    } catch (e) {
      _showErrorDialog(context, 'Erreur inconnue lors de la connexion: $e');
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> _removeEmailFromSavedList(String email) async {
    _savedEmails.remove(email);
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('saved_emails', _savedEmails);
    setState(() {}); // Mettre à jour l'interface utilisateur
  }

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

  Widget _buildEmailField() {
    return Autocomplete<String>(
      optionsBuilder: (TextEditingValue textEditingValue) {
        if (textEditingValue.text == '') {
          return _savedEmails; // Afficher toutes les adresses si le champ est vide
        }
        return _savedEmails.where((String email) {
          return email.toLowerCase().contains(textEditingValue.text.toLowerCase());
        });
      },
      onSelected: (String selection) {
        _emailController.text = selection;
      },
      fieldViewBuilder: (BuildContext context, TextEditingController textEditingController, FocusNode focusNode, VoidCallback onFieldSubmitted) {
        _emailController = textEditingController; // Assigner le contrôleur fourni
        return TextFormField(
          controller: _emailController,
          focusNode: focusNode,
          decoration: InputDecoration(
            labelText: 'E-mail',
            hintText: 'hello@wazaa.app',
            labelStyle: _labelTextStyle,
            hintStyle: _hintTextStyle,
            enabledBorder: _borderStyle,
            focusedBorder: _focusedBorderStyle,
            filled: true,
            fillColor: Colors.white.withOpacity(0.1),
            contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
            suffixIcon: Icon(Icons.email, color: Colors.white54),
          ),
          style: const TextStyle(color: Colors.white),
          validator: (value) {
            if (value == null || value.isEmpty || !value.contains('@')) {
              return 'Veuillez entrer une adresse e-mail valide';
            }
            return null;
          },
          textInputAction: TextInputAction.next,
          onFieldSubmitted: (_) {
            FocusScope.of(context).requestFocus(_passwordFocus);
          },
        );
      },
      optionsViewBuilder: (BuildContext context, AutocompleteOnSelected<String> onSelected, Iterable<String> options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: MediaQuery.of(context).size.width - 40,
              margin: const EdgeInsets.only(top: 5),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: ListView.separated(
                padding: EdgeInsets.zero,
                itemCount: options.length,
                shrinkWrap: true,
                separatorBuilder: (context, index) => const Divider(height: 1, color: Colors.grey),
                itemBuilder: (BuildContext context, int index) {
                  final String option = options.elementAt(index);
                  return ListTile(
                    leading: const Icon(Icons.email, color: Colors.blueGrey),
                    title: Text(
                      option,
                      style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w600),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () async {
                        await _removeEmailFromSavedList(option);
                      },
                    ),
                    tileColor: index % 2 == 0 ? Colors.white : Colors.grey.withOpacity(0.1),
                    onTap: () {
                      onSelected(option);
                    },
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPasswordField() {
    return TextFormField(
      controller: _passwordController,
      focusNode: _passwordFocus,
      obscureText: _obscurePassword,
      decoration: InputDecoration(
        labelText: 'Mot de passe',
        hintText: '********',
        labelStyle: _labelTextStyle,
        hintStyle: _hintTextStyle,
        enabledBorder: _borderStyle,
        focusedBorder: _focusedBorderStyle,
        filled: true,
        fillColor: Colors.white.withOpacity(0.1),
        contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
        suffixIcon: GestureDetector(
          onTap: () {
            setState(() {
              _obscurePassword = !_obscurePassword;
            });
          },
          child: Icon(
            _obscurePassword ? Icons.visibility : Icons.visibility_off,
            color: Colors.white54,
          ),
        ),
      ),
      style: const TextStyle(color: Colors.white),
      validator: (value) {
        if (value == null || value.length < 6) {
          return 'Le mot de passe doit comporter au moins 6 caractères';
        }
        return null;
      },
      textInputAction: TextInputAction.done,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: GestureDetector(
        onTap: () {
          // Fermer le clavier et la liste d'autocomplétion lorsqu'on clique en dehors
          FocusScope.of(context).unfocus();
        },
        child: SingleChildScrollView(
          child: Container(
            height: MediaQuery.of(context).size.height,
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
                    padding: const EdgeInsets.only(top: 0, left: 20, right: 20),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 0),
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
                          _buildEmailField(),
                          const SizedBox(height: 20),
                          _buildPasswordField(),
                          const SizedBox(height: 40),
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
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
