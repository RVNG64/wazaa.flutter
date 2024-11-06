import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';

class InviteFriendsPage extends StatefulWidget {
  const InviteFriendsPage({Key? key}) : super(key: key);

  @override
  _InviteFriendsPageState createState() => _InviteFriendsPageState();
}

class _InviteFriendsPageState extends State<InviteFriendsPage>
    with SingleTickerProviderStateMixin {
  String _invitationMessage =
      "Je t'invite à rejoindre Wazaa ! \n\nPour ne plus rien rater des événements autour de toi 😍 \nTélécharge l'application ici : [Lien de l'application]";

  late AnimationController _controller;
  late Animation<double> _animation;
  bool _isAnimationReady = false;

  @override
  void initState() {
    super.initState();

    // Initialisation du controller d'animation
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    // Initialisation de l'animation avec un curve
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );

    // Démarrer l'animation et marquer comme prête
    _controller.forward().then((_) {
      setState(() {
        _isAnimationReady = true;
      });
    });
  }

  // Ouvrir la boîte de dialogue pour personnaliser le message d'invitation
  Future<void> _showCustomMessageDialog() async {
    TextEditingController _messageController =
        TextEditingController(text: _invitationMessage);

    return showDialog<void>(
      context: context,
      barrierDismissible: true, // L'utilisateur peut fermer en cliquant à l'extérieur
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            'Personnaliser l\'invitation',
            style: TextStyle(
              fontFamily: 'Sora',
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF205893),
            ),
          ),
          content: TextField(
            controller: _messageController,
            maxLines: 5,
            decoration: InputDecoration(
              hintText: 'Écris ton message ici...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF205893)),
              ),
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text(
                'Annuler',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  color: Colors.grey,
                  fontSize: 15,
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              child: const Text(
                'Valider',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF205893),
              ),
              onPressed: () {
                setState(() {
                  _invitationMessage = _messageController.text;
                });
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  // Générer un Dynamic Link
  Future<String> _createDynamicLink() async {
    final DynamicLinkParameters parameters = DynamicLinkParameters(
      uriPrefix: 'https://links.wazaa.app',
      link: Uri.parse('https://wazaa.app/invite'),
      androidParameters: const AndroidParameters(
        packageName: 'com.wazaa.app', 
        minimumVersion: 0,
      ),
      iosParameters: const IOSParameters(
        bundleId: 'com.wazaa.app', // Remplacer par le bundle ID réel
        appStoreId: 'YOUR_APP_STORE_ID', // Remplacer par l'App Store ID
        minimumVersion: '0',
      ),
      socialMetaTagParameters: const SocialMetaTagParameters(
        title: 'Rejoins-moi sur Wazaa !',
        description: 'Je t\'invite à télécharger Wazaa pour ne plus rien rater des événements autour de toi 😍',
      ),
    );

    final ShortDynamicLink shortLink = await FirebaseDynamicLinks.instance.buildShortLink(parameters);
    final Uri shortUrl = shortLink.shortUrl;

    return shortUrl.toString();
  }

  // Partager l'invitation avec le lien dynamique
  Future<void> _shareInvitation() async {
    try {
      String dynamicLink = await _createDynamicLink();

      String message = _invitationMessage.replaceFirst(
          '[Lien de l\'application]', dynamicLink);

      Share.share(
        message,
        subject: 'Invitation à rejoindre Wazaa',
      );
    } catch (e) {
      print('Erreur lors de la création du lien dynamique: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erreur lors de la création du lien de partage.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Fond en dégradé radial
          Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.2,
                colors: [
                  Color(0xFF205893), // Bleu très foncé en haut
                  Color(0xFF16141E), // Bleu moyen en bas
                ],
              ),
            ),
          ),

          // Bouton de retour en haut à gauche
          Positioned(
            top: 50,
            left: 20,
            child: GestureDetector(
              onTap: () {
                Navigator.of(context).pop(); // Fermer la page
              },
              child: Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close,
                  color: Colors.black,
                  size: 24,
                ),
              ),
            ),
          ),

          // Contenu principal placé à 100 du haut
          Positioned(
            top: 150, // Distance du top
            left: 0,
            right: 0,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Titre
                const Text(
                  'Inviter des amis',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 40,
                    fontFamily: 'Sora',
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 50),

                // Texte d'invitation
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 30.0),
                  child: Text(
                    'Invitez vos amis à rejoindre Wazaa pour partager des événements ensemble !',
                    style: TextStyle(
                      color: Colors.white,
                      fontFamily: 'Poppins',
                      fontSize: 16,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 40),

                // Personnaliser l'invitation
                TextButton(
                  onPressed: _showCustomMessageDialog,
                  child: const Text(
                    'Personnaliser le message',
                    style: TextStyle(
                      color: Colors.white,
                      decoration: TextDecoration.underline,
                      fontFamily: 'Poppins',
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Vérification si l'animation est prête avant de la rendre visible
                if (_isAnimationReady)
                  ScaleTransition(
                    scale: _animation,
                    child: Container(
                      width: double.infinity,
                      margin: const EdgeInsets.symmetric(horizontal: 30.0),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFF83402F), // Couleur gauche
                            Color(0xFFEA603E), // Couleur droite
                          ],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(50),
                          ),
                        ),
                        onPressed: _shareInvitation,
                        child: const Text(
                          'Partager Wazaa',
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
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
