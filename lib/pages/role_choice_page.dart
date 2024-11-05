// lib/pages/role_choice_page.dart

import 'package:flutter/material.dart';
import 'package:simple_animations/simple_animations.dart';
import 'dart:math';
import 'dart:ui' as ui;
import 'inscription_form_page.dart';

class RoleChoicePage extends StatefulWidget {
  const RoleChoicePage({Key? key}) : super(key: key);

  @override
  _RoleChoicePageState createState() => _RoleChoicePageState();
}

class _RoleChoicePageState extends State<RoleChoicePage> {
  String selectedRole = 'Utilisateur'; // Par défaut, 'Utilisateur' est sélectionné

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Fond animé en mesh gradient
          AnimatedMeshGradientBackground(),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 30.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Bouton de retour personnalisé
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
                    'CHOISISSEZ VOTRE RÔLE',
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
                    textAlign: TextAlign.center,
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
                  // Boutons "Utilisateur" et "Organisateur" avec effet visuel
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        child: _buildRoleButton('Utilisateur', Colors.blueAccent, Colors.purpleAccent),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: _buildRoleButton('Organisateur', Colors.orangeAccent, Colors.redAccent),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                  // Explication pour chaque choix
                  AnimatedSwitcher(
                    duration: Duration(milliseconds: 500),
                    transitionBuilder: (child, animation) => FadeTransition(opacity: animation, child: child),
                    child: selectedRole == 'Utilisateur'
                        ? _buildDescription(
                            'En tant qu\'utilisateur, vous utilisez Wazaa pour trouver des événements intéressants à proximité.\n Vous pouvez également organiser des événements privés, visibles uniquement par les personnes que vous invitez.\nQuelques exemples d\'événements privés : anniversaire, mariage, vacances entre amis, séminaire professionnel...',
                          )
                        : _buildDescription(
                            'En tant qu\'organisateur, vous représentez une entreprise, une association ou un auto-entrepreneur.\n Vous pouvez organiser des événements publics, visibles par tous les utilisateurs sur la carte Wazaa, ainsi que des événements privés.',
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
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => InscriptionFormPage(selectedRole: selectedRole),
                          ),
                        );
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

  Widget _buildRoleButton(String title, Color startColor, Color endColor) {
    bool isSelected = selectedRole == title;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedRole = title;
        });
      },
      child: AnimatedContainer(
        duration: Duration(milliseconds: 300),
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        decoration: BoxDecoration(
          gradient: isSelected ? LinearGradient(
            colors: [startColor, endColor],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ) : null,
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: isSelected ? Colors.white : Colors.grey,
            width: 2,
          ),
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
        child: Column(
          children: [
            // Titre du rôle
            Text(
              title,
              style: TextStyle(
                fontFamily: 'Sora',
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: isSelected ? Colors.white : (selectedRole == title ? Colors.white : Colors.white70),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDescription(String text) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 15,
          color: Colors.white70,
          fontFamily: 'Poppins',
          fontStyle: FontStyle.italic,
          height: 1.5,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

class AnimatedIconWidget extends StatefulWidget {
  final IconData icon;
  final bool isSelected;

  const AnimatedIconWidget({Key? key, required this.icon, required this.isSelected}) : super(key: key);

  @override
  _AnimatedIconWidgetState createState() => _AnimatedIconWidgetState();
}

class _AnimatedIconWidgetState extends State<AnimatedIconWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _rotationAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<Color?> _colorAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: 4),
    )..repeat(reverse: true);

    _rotationAnimation = Tween<double>(begin: 0, end: 2 * pi).animate(
      CurvedAnimation(parent: _controller, curve: Curves.linear),
    );

    _scaleAnimation = Tween<double>(begin: 1, end: 1.2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _colorAnimation = widget.isSelected
        ? ColorTween(
            begin: Colors.white,
            end: Colors.yellowAccent,
          ).animate(
            CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
          )
        : AlwaysStoppedAnimation<Color?>(Colors.white);
  }

  @override
  void didUpdateWidget(covariant AnimatedIconWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSelected != oldWidget.isSelected) {
      if (widget.isSelected) {
        _colorAnimation = ColorTween(
          begin: Colors.white,
          end: Colors.yellowAccent,
        ).animate(
          CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
        );
      } else {
        _colorAnimation = AlwaysStoppedAnimation<Color?>(Colors.white);
      }
    }
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
              widget.icon,
              color: _colorAnimation.value,
              size: 50,
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
              center: Alignment(0.5, 0.5),
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
        radius: 0.4,
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
