import 'dart:math';
import 'package:flutter/material.dart';

class NeuralCard extends StatefulWidget {
  final String frontImage;
  final String backImage;
  final Color themeColor;
  final bool isRevealed;

  const NeuralCard({
    super.key,
    required this.frontImage,
    required this.backImage,
    required this.themeColor,
    required this.isRevealed,
  });

  @override
  State<NeuralCard> createState() => _NeuralCardState();
}

class _NeuralCardState extends State<NeuralCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0, end: pi).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutBack,
    ));
  }

  @override
  void didUpdateWidget(NeuralCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isRevealed && !oldWidget.isRevealed) {
      _controller.forward();
    } else if (!widget.isRevealed && oldWidget.isRevealed) {
      _controller.reverse();
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
      animation: _animation,
      builder: (context, child) {
        final angle = _animation.value;
        final isBack = angle >= pi / 2;

        return Transform(
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.001) // perspective
            ..rotateY(angle),
          alignment: Alignment.center,
          child: isBack
              ? Transform(
                  transform: Matrix4.identity()..rotateY(pi),
                  alignment: Alignment.center,
                  child: _buildCardSide(widget.backImage, isFront: false),
                )
              : _buildCardSide(widget.frontImage, isFront: true),
        );
      },
    );
  }

  Widget _buildCardSide(String imagePath, {required bool isFront}) {
    return Container(
      width: 280,
      height: 400,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: widget.themeColor.withValues(alpha: 0.5),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: widget.themeColor.withValues(alpha: 0.3),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          children: [
            Image.asset(
              imagePath,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
            ),
            
            if (!widget.isRevealed && isFront)
              Container(
                color: Colors.black.withValues(alpha: 0.9),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.lock_outline_rounded, color: widget.themeColor, size: 60),
                      const SizedBox(height: 20),
                      Text(
                        "ENCRYPTED_DATA",
                        style: TextStyle(
                          fontFamily: 'SpaceMono',
                          color: widget.themeColor,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            
            // Holographic Overlay
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withValues(alpha: 0.1),
                      Colors.transparent,
                      widget.themeColor.withValues(alpha: 0.05),
                      Colors.white.withValues(alpha: 0.05),
                    ],
                    stops: const [0.1, 0.4, 0.6, 0.9],
                  ),
                ),
              ),
            ),

            // Scanlines effect
            Positioned.fill(
              child: Opacity(
                opacity: 0.1,
                child: ListView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  itemBuilder: (context, index) => Container(
                    height: 1,
                    color: Colors.white,
                    margin: const EdgeInsets.only(bottom: 2),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
