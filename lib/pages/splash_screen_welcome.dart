import 'package:flutter/material.dart';
import 'map_page.dart';
import 'dart:async';

class SplashScreenWelcome extends StatefulWidget {
  @override
  _SplashScreenWelcomeState createState() => _SplashScreenWelcomeState();
}

class _SplashScreenWelcomeState extends State<SplashScreenWelcome> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeInOutAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _disappearAnimation;

  @override
  void initState() {
    super.initState();

    // AnimationController avec une durée plus courte pour une transition rapide
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500), // Ajustement pour des transitions fluides
    );

    // Animation d'opacité pour le texte "WAZAA"
    _fadeInOutAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    // Animation de zoom pour l'apparition du texte
    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack, // Courbe fluide pour l'effet de zoom
    ));

    // Animation de disparition radiale
    _disappearAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn, // Courbe fluide pour la sortie
    ));

    // Démarrage des animations
    _controller.forward();

    // Temporisation avant la disparition et la navigation vers la page de la carte
    Timer(const Duration(milliseconds: 2500), () {
      _controller.reverse().then((_) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MapWithMarkersPage()),
        );
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose(); // Nettoyage du controller pour éviter les fuites de mémoire
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Arrière-plan avec dégradé radial
          const Positioned.fill(
            child: _BackgroundGradient(),
          ),
          // Texte animé "WAZAA"
          Center(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Opacity(
                  opacity: _fadeInOutAnimation.value,
                  child: Transform.scale(
                    scale: _scaleAnimation.value,
                    child: const _WazaaText(),
                  ),
                );
              },
            ),
          ),
          // Effet de disparition radiale
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _disappearAnimation,
              builder: (context, child) {
                return ClipPath(
                  clipper: RadialClipper(_disappearAnimation.value),
                  child: child,
                );
              },
              child: Container(
                color: Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Widget pour le fond d'écran avec dégradé radial
class _BackgroundGradient extends StatelessWidget {
  const _BackgroundGradient({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.center,
          radius: 2.0,
          colors: [
            Colors.black, // Couleur principale
            Color(0xFF203A43), // Transition vers un gris foncé
            Color(0xFF2C5364), // Transition finale vers un bleu sombre
          ],
          stops: [0.4, 0.7, 1.0],
        ),
      ),
    );
  }
}

// Widget pour le texte "WAZAA"
class _WazaaText extends StatelessWidget {
  const _WazaaText({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Text(
      'WAZAA',
      style: TextStyle(
        fontFamily: 'Sora',
        fontSize: 70,
        fontWeight: FontWeight.bold,
        color: Colors.white,
        shadows: [
          Shadow(
            blurRadius: 20.0,
            color: Colors.black.withOpacity(0.6),
            offset: const Offset(0, 5),
          ),
        ],
      ),
    );
  }
}

// Clipper personnalisé pour créer l'effet de disparition radiale
class RadialClipper extends CustomClipper<Path> {
  final double radiusFactor;

  RadialClipper(this.radiusFactor);

  @override
  Path getClip(Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final path = Path()
      ..addOval(Rect.fromCircle(center: center, radius: size.width * radiusFactor));
    return path;
  }

  @override
  bool shouldReclip(RadialClipper oldClipper) => radiusFactor != oldClipper.radiusFactor;
}
