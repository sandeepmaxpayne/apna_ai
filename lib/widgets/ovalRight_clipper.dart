import 'package:flutter/material.dart';

class OvalRightClipper extends CustomClipper<Path> {
  final double progress;

  OvalRightClipper(this.progress);

  @override
  Path getClip(Size size) {
    final path = Path();
    double curve = 60 * progress;
    path.moveTo(0, 0);
    path.lineTo(size.width - curve, 0);
    path.quadraticBezierTo(
        size.width, size.height / 2, size.width - curve, size.height);
    path.lineTo(0, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(OvalRightClipper oldClipper) =>
      oldClipper.progress != progress;
}
