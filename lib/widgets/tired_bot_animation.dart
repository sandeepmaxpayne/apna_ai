import 'package:flutter/material.dart';

class TiredBotAnimation extends StatefulWidget {
  const TiredBotAnimation({super.key});

  @override
  State<TiredBotAnimation> createState() => _TiredBotAnimationState();
}

class _TiredBotAnimationState extends State<TiredBotAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    _shakeAnimation = Tween<double>(begin: -4, end: 4).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _shakeAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(_shakeAnimation.value, 0),
          child: child,
        );
      },
      child: Image.asset(
        'assets/robot_tired.png',
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => const Icon(
            Icons.sentiment_dissatisfied,
            color: Colors.deepPurple,
            size: 32),
      ),
    );
  }
}
