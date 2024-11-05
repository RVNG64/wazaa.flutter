// lib/pages/create_event_page.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:simple_animations/simple_animations.dart';
import 'dart:math';
import 'dart:ui' as ui;
import 'event_form_page.dart';
import '../services/user_service.dart';
import '../pages/contact_page.dart';

class CreateEventPage extends StatefulWidget {
  @override
  _CreateEventPageState createState() => _CreateEventPageState();
}

class _CreateEventPageState extends State<CreateEventPage> {
  bool isPublic = false;
  String? userRole;
  bool isLoading = true;
  final UserService _userService = UserService();

  @override
  void initState() {
    super.initState();
    _fetchUserRole();
  }

  void _showComingSoonDialog() {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Coming Soon',
      barrierColor: Colors.black54,
      transitionDuration: Duration(milliseconds: 500),
      pageBuilder: (context, animation, secondaryAnimation) {
        return Center(
          child: ComingSoonDialog(),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return ScaleTransition(
          scale: CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutBack,
          ),
          child: child,
        );
      },
    );
  }

  Future<void> _fetchUserRole() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      String? token = await user.getIdToken();
      if (token != null) {
        String? role = await _userService.getUserRole(token);
        setState(() {
          userRole = role;
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
          userRole = null;
        });
        print('Erreur : le token est null');
      }
    } else {
      setState(() {
        isLoading = false;
        userRole = null;
      });
      print('Erreur : l\'utilisateur n\'est pas connecté');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: isLoading
          ? Center(child: CircularProgressIndicator(color: Colors.white))
          : Stack(
              children: [
                // Fond animé en mesh gradient
                AnimatedMeshGradientBackground(),
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 30, left: 24, right: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center, // Pour centrer le contenu
                      children: [
                        // Bouton de retour stylisé
                        Align(
                          alignment: Alignment.topLeft,
                          child: GestureDetector(
                            onTap: () {
                              Navigator.pop(context);
                            },
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 8,
                                    spreadRadius: 2,
                                    offset: Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.arrow_back_ios_new,
                                size: 20,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 50),
                        // Titre centré
                        Text(
                          'CRÉER UN ÉVÉNEMENT',
                          style: TextStyle(
                            fontFamily: 'Sora',
                            fontSize: 34,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            shadows: [
                              Shadow(
                                blurRadius: 10.0,
                                color: Colors.black54,
                                offset: Offset(0, 3),
                              ),
                            ],
                          ),
                          textAlign: TextAlign.center, // Centrage du texte
                        ),
                        SizedBox(height: 10),
                        Container(
                          width: 120,
                          height: 5,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(2.5),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.white.withOpacity(0.5),
                                blurRadius: 8,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 40),
                        // Toggle Button pour Public/Privé avec effet visuel
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildOptionButton('Public', isPublic),
                            SizedBox(width: 20),
                            _buildOptionButton('Privé', !isPublic),
                          ],
                        ),
                        SizedBox(height: 20),
                        // Explication pour chaque choix
                        Center(
                          child: AnimatedSwitcher(
                            duration: Duration(milliseconds: 500),
                            transitionBuilder: (child, animation) => FadeTransition(opacity: animation, child: child),
                            child: Column(
                              key: ValueKey<bool>(isPublic),
                              children: [
                                Icon(
                                  isPublic ? Icons.public : Icons.lock,
                                  color: Colors.blueAccent,
                                  size: 30,
                                ),
                                SizedBox(height: 10),
                                Text(
                                  isPublic
                                      ? 'Votre événement sera visible par tous les utilisateurs sur la carte publique Wazaa.'
                                      : 'Votre événement sera visible uniquement par les utilisateurs invités et ceux à qui vous partagez le lien. Les autres utilisateurs ne le verront pas sur la carte publique Wazaa.\n\nExemples : anniversaire, mariage, séminaire d\'entreprise...',
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: Colors.white70,
                                    fontFamily: 'Poppins',
                                    fontStyle: FontStyle.italic,
                                    height: 1.5,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ),
                        Spacer(),
                        // Bouton "Continuer" stylisé
                        Center(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.black,
                              padding: EdgeInsets.symmetric(horizontal: 80, vertical: 20),
                              textStyle: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Sora',
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(50),
                              ),
                              elevation: 10,
                            ),
                            onPressed: () {
                              /* Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => EventFormPage(isPublic: isPublic),
                                ), 
                              ); */
                              _showComingSoonDialog();
                            },
                            child: Text('Continuer'),
                          ),
                        ),
                        SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildOptionButton(String title, bool isSelected) {
    bool isOptionPublic = (title == 'Public');
    bool isOptionEnabled = userRole == 'organizer' || !isOptionPublic;

    return GestureDetector(
      onTap: () {
        if (isOptionEnabled) {
          setState(() {
            isPublic = isOptionPublic;
          });
        } else {
          _showRoleAlert();
        }
      },
      child: AnimatedContainer(
        duration: Duration(milliseconds: 300),
        padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: isOptionEnabled ? Colors.white : Colors.grey,
            width: 2,
          ),
          gradient: isSelected
              ? LinearGradient(
                  colors: [Colors.blueAccent, Colors.purpleAccent],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black45,
                    blurRadius: 15,
                    offset: Offset(0, 5),
                  ),
                ]
              : [],
        ),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 18,
            color: isSelected ? Colors.white : (isOptionEnabled ? Colors.white70 : Colors.grey),
            fontWeight: FontWeight.w700,
            fontFamily: 'Sora',
          ),
        ),
      ),
    );
  }

  void _showRoleAlert() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF205893),
                  Color(0xFF16141E),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white, 
                width: 1, 
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black54,
                  blurRadius: 15,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    //Icon(Icons.info, color: Colors.blue, size: 28),
                    SizedBox(width: 8),
                    Text(
                      'Hey ! 👋',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Sora',
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20),
                Text(
                  'Seuls les utilisateurs avec un statut "Organisateur" peuvent créer des événements publics.',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                    fontFamily: 'Poppins',
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                /* SizedBox(height: 30),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 25, vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 5,
                  ),
                  onPressed: () async {
                    await FirebaseAuth.instance.signOut(); // Déconnecte l'utilisateur
                    Navigator.of(context).pushReplacement(MaterialPageRoute(
                      builder: (context) => ContactPage(),
                    ));
                  },
                  child: Text(
                    'Contacter Nous',
                    style: TextStyle(fontSize: 14, fontFamily: 'Sora'),
                  ),
                ), */
                SizedBox(height: 10),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[700],
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 25, vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 5,
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text(
                    'Fermer',
                    style: TextStyle(
                      fontSize: 14,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class AnimatedMeshGradientBackground extends StatefulWidget {
  @override
  _AnimatedMeshGradientBackgroundState createState() => _AnimatedMeshGradientBackgroundState();
}

class _AnimatedMeshGradientBackgroundState extends State<AnimatedMeshGradientBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<AnimatedBall> _balls;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 15),
      vsync: this,
    )..repeat(reverse: false);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Initialiser `_balls` ici, après que le contexte soit complètement disponible
    _balls = List.generate(7, (index) {
      return AnimatedBall(
        position: Offset(
          Random().nextDouble() * MediaQuery.of(context).size.width,
          Random().nextDouble() * MediaQuery.of(context).size.height,
        ),
        color: Color((Random().nextDouble() * 0xFFFFFF).toInt()).withOpacity(0.8),
        speed: Offset(
          (Random().nextDouble() - 0.5) * 4,
          (Random().nextDouble() - 0.5) * 4,
        ),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(0.5, 0.5), // la couleur bleue foncée est centrée, la couleur bleue moyenne est autour
              radius: 2.0,
              colors: [
                Color(0xFF205893),
                Color(0xFF16141E),
              ],
              stops: [0.1, 0.5],
            ),
          ),
        ),
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            for (var ball in _balls) {
              ball.updatePosition(context);
            }
            return CustomPaint(
              painter: MeshGradientPainter(balls: _balls),
              child: Container(),
            );
          },
        ),
      ],
    );
  }
}

class AnimatedBall {
  Offset position;
  final Color color;
  Offset speed;

  AnimatedBall({required this.position, required this.color, required this.speed});

  void updatePosition(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;

    position += speed;

    if (position.dx <= 0 || position.dx >= width) {
      speed = Offset(-speed.dx, speed.dy); // Inverser la direction horizontale
      position = Offset(position.dx.clamp(0, width), position.dy);
    }
    if (position.dy <= 0 || position.dy >= height) {
      speed = Offset(speed.dx, -speed.dy); // Inverser la direction verticale
      position = Offset(position.dx, position.dy.clamp(0, height));
    }
  }
}

class MeshGradientPainter extends CustomPainter {
  final List<AnimatedBall> balls;

  MeshGradientPainter({required this.balls});

  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint();

    for (var ball in balls) {
      paint.shader = RadialGradient(
        colors: [
          ball.color.withOpacity(0.6),
          Colors.transparent,
        ],
        radius: 0.4, // Ajuster la taille de la "tache" de couleur
      ).createShader(
        Rect.fromCircle(center: ball.position, radius: 150),
      );

      canvas.drawCircle(ball.position, 150, paint);
    }
  }

  @override
  bool shouldRepaint(covariant MeshGradientPainter oldDelegate) {
    return true;
  }
}

class ComingSoonDialog extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent, // Fond transparent
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Arrière-plan animé
          Positioned.fill(
            child: AnimatedBackground(),
          ),
          // Conteneur de la popup
          Container(
            width: MediaQuery.of(context).size.width * 0.85,
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.white, Colors.grey.shade100],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 20,
                  spreadRadius: 2,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icône animée
                AnimatedIconWidget(),
                SizedBox(height: 20),
                // Titre avec animation de glissement
                SlideTransition(
                  position: Tween<Offset>(begin: Offset(0, -0.5), end: Offset.zero)
                      .animate(CurvedAnimation(parent: ModalRoute.of(context)!.animation!, curve: Curves.easeOut)),
                  child: Text(
                    'Bientôt Disponible 😍',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.blueGrey.shade800,
                      fontFamily: 'Poppins',
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                SizedBox(height: 10),
                // Description avec animation de fondu
                FadeTransition(
                  opacity: Tween<double>(begin: 0, end: 1).animate(
                    CurvedAnimation(parent: ModalRoute.of(context)!.animation!, curve: Curves.easeIn),
                  ),
                  child: Text(
                    'Nous travaillons dur pour vous offrir cette fonctionnalité phare de Wazaa.\nRestez connecté, c\'est pour la prochaine mise à jour !',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.blueGrey.shade600,
                      fontFamily: 'Poppins',
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                SizedBox(height: 20),
                // Nouvelle explication avec bouton pour contacter
                Text(
                  'En attendant la sortie de cette fonctionnalité, vous pouvez nous contacter pour ajouter un événement à la carte publique Wazaa.',
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.blueGrey.shade600,
                    fontFamily: 'Poppins',
                    fontStyle: FontStyle.italic,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 20),
                /* Bouton "Contactez-Nous"
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    padding: EdgeInsets.symmetric(horizontal: 25, vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 5,
                  ),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => ContactPage(),
                      ),
                    );
                  },
                  child: Text(
                    'Nous Contacter',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ), */
                SizedBox(height: 10),
                // Bouton "Fermer" avec effet de pulsation
                PulseButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // Ferme la popup
                  },
                  text: 'Fermer',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class PulseButton extends StatefulWidget {
  final VoidCallback onPressed;
  final String text;

  PulseButton({required this.onPressed, required this.text});

  @override
  _PulseButtonState createState() => _PulseButtonState();
}

class _PulseButtonState extends State<PulseButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: 2),
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _pulseAnimation,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blueAccent,
          padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
          elevation: 8,
        ),
        onPressed: widget.onPressed,
        child: Text(
          widget.text,
          style: TextStyle(
            fontSize: 16,
            color: Colors.white,
            fontFamily: 'Poppins',
          ),
        ),
      ),
    );
  }
}

class AnimatedIconWidget extends StatefulWidget {
  @override
  _AnimatedIconWidgetState createState() => _AnimatedIconWidgetState();
}

class _AnimatedIconWidgetState extends State<AnimatedIconWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _rotationAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: 2),
    )..repeat(reverse: true);
    _rotationAnimation = Tween<double>(begin: 0, end: 2 * pi).animate(CurvedAnimation(parent: _controller, curve: Curves.linear));
    _scaleAnimation = Tween<double>(begin: 1, end: 1.1).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.rotate(
          angle: _rotationAnimation.value,
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: Icon(
              Icons.hourglass_bottom,
              color: Colors.blueAccent,
              size: 60,
            ),
          ),
        );
      },
    );
  }
}

class AnimatedBackground extends StatefulWidget {
  @override
  _AnimatedBackgroundState createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<AnimatedBackground> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<AnimatedCircle> _circles;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 6),
      vsync: this,
    )..repeat(reverse: true);

    _circles = List.generate(5, (index) => AnimatedCircle());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: CirclePainter(circles: _circles, animationValue: _controller.value),
          child: Container(),
        );
      },
    );
  }
}

class AnimatedCircle {
  final Offset position;
  final double maxRadius;
  final Color color;

  AnimatedCircle()
      : position = Offset(Random().nextDouble() * 300, Random().nextDouble() * 300),
        maxRadius = Random().nextDouble() * 50 + 20,
        color = Colors.blueAccent.withOpacity(0.2);
}

class CirclePainter extends CustomPainter {
  final List<AnimatedCircle> circles;
  final double animationValue;

  CirclePainter({required this.circles, required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint();
    for (var circle in circles) {
      double radius = circle.maxRadius * (0.5 + 0.5 * sin(animationValue * 2 * pi));
      paint.color = circle.color;
      canvas.drawCircle(circle.position, radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CirclePainter oldDelegate) {
    return true;
  }
}
