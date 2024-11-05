import 'package:flutter/material.dart';
import 'profile_infos.dart';
import 'invite_friends.dart';
import 'faq_page.dart';
import 'contact_page.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_page.dart';
import '../widgets/theme_notifier.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({Key? key}) : super(key: key);

  // Fonction pour ouvrir les URLs externes
  Future<void> _launchURL(String url) async {
    Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw 'Impossible d\'ouvrir le lien $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context); // Récupérer le thème actuel

    return Scaffold(
      // 3. Changer le fond de la page en gris clair
      backgroundColor: theme.scaffoldBackgroundColor, 
      appBar: AppBar(
        toolbarHeight: 85, // Augmenter la hauteur de l'AppBar
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 15, top: 10),
          child: GestureDetector(
            onTap: () {
              Navigator.pop(context);
            },
            child: Container(
              width: 35,
              height: 35,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 6,
                    spreadRadius: 1,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Center(
                child: Icon(
                  Icons.arrow_back_ios_new,
                  size: 16, // Taille ajustée
                  color: Colors.black,
                ),
              ),
            ),
          ),
        ),
        centerTitle: true,
        title: Padding(
          padding: EdgeInsets.only(top: 10), // 2. Ajouter plus de marge au-dessus du titre
          child: Text(
            'Réglages',
            style: TextStyle(
              fontFamily: 'Sora',
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: theme.appBarTheme.titleTextStyle?.color ?? Colors.white,
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20),
              children: [
                ListTile(
                  title: const Text('Mes informations'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ProfileInfosPage()),
                    );
                  },
                ),
                ListTile(
                  title: const Text('Inviter des amis'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const InviteFriendsPage()),
                    );
                  },
                ),
                ListTile(
                  title: const Text('FAQ'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const FAQPage()),
                    );
                  },
                ),
                ListTile(
                  title: const Text('Nous contacter'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ContactPage()),
                    );
                  },
                ),
                const SizedBox(height: 16),

                /* Option pour basculer entre le Light et le Dark Mode
                Consumer<ThemeNotifier>(
                  builder: (context, themeNotifier, child) {
                    return SwitchListTile(
                      title: const Text('Mode sombre'),
                      value: themeNotifier.isDarkMode,
                      onChanged: (val) {
                        themeNotifier.toggleTheme(); // Basculer le thème
                      },
                    );
                  },
                ),
                const SizedBox(height: 16), */

                ListTile(
                  title: const Text('Version 1.0.0'),
                  onTap: () {},
                ),
                const SizedBox(height: 60),

                Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text('Suivez-nous ❤️', style: TextStyle(fontSize: 16)),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        GestureDetector(
                          onTap: () {
                            _launchURL('https://www.tiktok.com/@wazaa.app');
                          },
                          child: const Icon(Icons.tiktok, size: 32),
                        ),
                        const SizedBox(width: 16),
                        GestureDetector(
                          onTap: () {
                            _launchURL('https://www.instagram.com/wazaa.app/');
                          },
                          child: const Icon(Icons.camera_alt_outlined, size: 32),
                        ),
                        const SizedBox(width: 16),
                        GestureDetector(
                          onTap: () {
                            _launchURL('https://www.facebook.com/wazaa.official?_rdr');
                          },
                          child: const Icon(Icons.facebook, size: 32),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
          // 4. Positionner le bouton "Se déconnecter" à 25 pixels du bas de la page
          Padding(
            padding: const EdgeInsets.only(bottom: 25.0),
            child: Center(
              child: TextButton(
                onPressed: () async {
                  try {
                    await FirebaseAuth.instance.signOut();
                    // Naviguer vers la page de connexion après la déconnexion
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (context) => const LoginPage()),
                    );
                  } catch (e) {
                    // Gérer les erreurs de déconnexion
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Erreur lors de la déconnexion')),
                    );
                  }
                },
                child: const Text(
                  'Se déconnecter',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
