// lib/widgets/animated_cluster.dart

import 'package:flutter/material.dart';

class AnimatedCluster extends StatefulWidget {
  final int markerCount;

  const AnimatedCluster({required this.markerCount});

  @override
  _AnimatedClusterState createState() => _AnimatedClusterState();
}

class _AnimatedClusterState extends State<AnimatedCluster>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true); // Animation infinie

    _animation = Tween<double>(begin: -0.5, end: 0.5).animate(
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
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(25),
            gradient: RadialGradient(
              colors: [
                Color(0xFF1E90FF),
                Color(0xFF205893),
              ],
              center: Alignment(_animation.value, _animation.value),
              radius: 0.8,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.6),
                blurRadius: 8,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Text(
                widget.markerCount.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Positioned(
                bottom: -8,
                right: -8,
                child: ScaleTransition(
                  scale: Tween(begin: 0.9, end: 1.1)
                      .animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut)),
                  child: Icon(
                    Icons.circle,
                    color: Colors.white.withOpacity(0.4),
                    size: 12,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
