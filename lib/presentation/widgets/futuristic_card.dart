import 'dart:ui';
import 'package:flutter/material.dart';

class FuturisticCard extends StatelessWidget {
  final Widget child;
  const FuturisticCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              colors: [Colors.cyanAccent.withOpacity(0.1), Colors.transparent],
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}
