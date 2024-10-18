import 'package:flutter/material.dart';
import 'dart:async';
import 'home_page.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();

    // Initialisation de l'animation
    _controller = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    );

    _slideAnimation = Tween<double>(begin: 0.0, end: -1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );

    Timer(const Duration(seconds: 0), () {
      _controller.forward();
    });

    Timer(const Duration(seconds: 5), () {
      Navigator.pushReplacement(context, _createRoute());
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Déplacer la précharge de l'image ici
    precacheImage(
      AssetImage('lib/assets/images/img-homeWazaa.png'), 
      context,
    );
  }

  Route _createRoute() {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => HomePage(),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.easeInOut;

        var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

        return SlideTransition(
          position: animation.drive(tween),
          child: child,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Texte WAZAA
          const Center(
            child: Text(
              'WAZAA',
              style: TextStyle(
                fontSize: 60,
                fontFamily: 'Sora',
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
          ),
          // Animation du rideau noir
          SlideTransition(
            position: _slideAnimation.drive(Tween<Offset>(
              begin: const Offset(0, 0),
              end: const Offset(0, -1),
            )),
            child: Container(
              color: Colors.black,
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
