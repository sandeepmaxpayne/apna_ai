import 'dart:async';

import 'package:flutter/material.dart';

class AnimatedThinkingText extends StatefulWidget {
  const AnimatedThinkingText({super.key});

  @override
  State<AnimatedThinkingText> createState() => _AnimatedThinkingTextState();
}

class _AnimatedThinkingTextState extends State<AnimatedThinkingText> {
  int dotCount = 1;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 400), (_) {
      setState(() => dotCount = (dotCount % 3) + 1);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      "Thinking${"." * dotCount}",
      style: const TextStyle(
        fontWeight: FontWeight.w600,
        fontSize: 14,
        color: Colors.black54,
      ),
    );
  }
}
