import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'dart:convert';

class ContactPage extends StatefulWidget {
  const ContactPage({Key? key}) : super(key: key);

  @override
  _ContactPageState createState() => _ContactPageState();
}

class _ContactPageState extends State<ContactPage> {
  final TextEditingController _messageController = TextEditingController();
  final FocusNode _messageFocusNode = FocusNode(); 
  String? _selectedSubject;
  final List<String> _subjects = [
    'Générale',
    'Signaler un problème',
    'Suggestion',
    'Partenariat',
    'Autre',
  ];

  static const int _minMessageLength = 10;

  @override
  void dispose() {
    _messageController.dispose();
    _messageFocusNode.dispose(); 
    super.dispose();
  }

  Future<String?> _getFirebaseToken() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      return await user.getIdToken(); 
    }
    return null;
  }

  // Envoi du message à l'API Backend
    Future<void> _sendMessage(BuildContext context) async {
    FocusScope.of(context).unfocus(); 

    if (_selectedSubject == null) {
        ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez choisir un sujet.')),
        );
        return;
    }

    if (_messageController.text.isEmpty || _messageController.text.length < _minMessageLength) {
        ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Le message doit contenir au moins $_minMessageLength caractères.'),
        ),
        );
        return;
    }

    final String? token = await _getFirebaseToken();
    
    // Log du jeton pour voir ce qu'il contient
    print('Firebase Token: $token');

    if (token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erreur d\'authentification. Veuillez vous reconnecter.')),
        );
        return;
    }

    final Map<String, dynamic> messageData = {
        'subject': _selectedSubject,
        'message': _messageController.text,
    };

    try {
        final response = await http.post(
        Uri.parse('https://wazaapp-backend-e95231584d01.herokuapp.com/send-email'),
        headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token', 
        },
        body: json.encode(messageData),
        );

        if (response.statusCode == 200) {
            ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Row(
                    children: [
                        Icon(Icons.check_circle_outline, color: Colors.white), // Icône de succès
                        SizedBox(width: 10),
                        Expanded(
                        child: Text('Merci, votre message sur le sujet "$_selectedSubject" a bien été envoyé ! Nous vous répondrons sous peu.'),
                        ),
                    ],
                    ),
                    backgroundColor: Colors.green, // Fond vert pour indiquer le succès
                    duration: const Duration(seconds: 5), // Durée d'affichage du message
                ),
            );
            Navigator.of(context).pop();
        } else {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Échec de l\'envoi du message. Statut: ${response.statusCode}, Corps: ${response.body}')),
        );
        }
    } catch (error) {
        ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $error')),
        );
    }
    }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Stack(
          children: [
            // Fond en dégradé radial
            Container(
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
            ),
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 20, top: 50),
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: GestureDetector(
                      onTap: () {
                        Navigator.of(context).pop(); 
                      },
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.arrow_back,
                          color: Colors.black,
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                const Text(
                  'CONTACTEZ-NOUS',
                  style: TextStyle(
                    fontFamily: 'Sora',
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.white38),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedSubject,
                        hint: const Text(
                          'Choisissez un sujet',
                          style: TextStyle(color: Colors.white38),
                        ),
                        dropdownColor: const Color(0xFF16141E),
                        iconEnabledColor: Colors.white,
                        items: _subjects.map((String subject) {
                          return DropdownMenuItem<String>(
                            value: subject,
                            child: Text(
                              subject,
                              style: const TextStyle(color: Colors.white),
                            ),
                          );
                        }).toList(),
                        onChanged: (newValue) {
                          setState(() {
                            _selectedSubject = newValue;
                          });
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.white38),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: TextField(
                        controller: _messageController,
                        focusNode: _messageFocusNode,
                        maxLines: 10,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          hintText: 'Rédigez votre question...',
                          hintStyle: TextStyle(color: Colors.white38),
                        ),
                      ),
                    ),
                  ),
                ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFF83402F), 
                          Color(0xFFEA603E),
                        ],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: ElevatedButton(
                      onPressed: () {
                        _sendMessage(context); 
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent, 
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(50),
                        ),
                      ),
                      child: const Text(
                        'Envoyer',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
