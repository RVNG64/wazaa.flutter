import 'package:flutter/material.dart';
import 'splash_screen_welcome.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Image de fond optimisée avec BoxFit.cover
          const _BackgroundImage(),

          // Overlay avec dégradé pour améliorer la lisibilité du texte
          const _OverlayGradient(),

          // Contenu textuel et bouton aligné en bas
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end, // Aligner le contenu en bas
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const _WelcomeText(),
                const SizedBox(height: 20),
                const _DescriptionText(),
                const SizedBox(height: 40),
                _StartButton(onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => SplashScreenWelcome()),
                  );
                }),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Widget pour l'image de fond
class _BackgroundImage extends StatelessWidget {
  const _BackgroundImage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Image.asset(
        'lib/assets/images/welcome-screen.jpg',
        fit: BoxFit.cover,
        alignment: Alignment.topCenter,
      ),
    );
  }
}

// Widget pour l'overlay avec dégradé
class _OverlayGradient extends StatelessWidget {
  const _OverlayGradient({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent, // Commence par du transparent en haut
              Color(0xFF000000), // Noir en bas pour améliorer la lisibilité
            ],
            stops: [0.6, 1.0], // Ajuster pour une transition douce
          ),
        ),
      ),
    );
  }
}

// Widget pour le texte de bienvenue
class _WelcomeText extends StatelessWidget {
  const _WelcomeText({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Text(
      'Bienvenue dans ton univers WAZAA !',
      style: TextStyle(
        fontFamily: 'Sora',
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
      textAlign: TextAlign.center,
    );
  }
}

// Widget pour le texte de description
class _DescriptionText extends StatelessWidget {
  const _DescriptionText({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Text(
      'Cette 1ère version de l\'app se concentre sur les événements Pays Basque/Landes.\n\n'
      'De nombreuses fonctionnalités viendront chaque mois pour améliorer l\'expérience, nous comptons sur vos retours... et vos suggestions !\n\n'
      'En attendant, l\'équipe WAZAA vous souhaite une belle expérience ❤️',
      style: TextStyle(
        fontFamily: 'Poppins',
        fontSize: 14,
        color: Colors.white,
      ),
      textAlign: TextAlign.center,
    );
  }
}

// Widget pour le bouton "Commencer"
class _StartButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _StartButton({Key? key, required this.onPressed}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 100, vertical: 20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(50),
        ),
        side: const BorderSide(color: Colors.white, width: 1),
      ),
      child: const Text(
        'Commencer',
        style: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }
}
