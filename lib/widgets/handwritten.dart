import 'package:flutter/material.dart';

import '../app/app_theme.dart';

class Handwritten extends StatelessWidget {
  const Handwritten(
    this.text, {
    super.key,
    this.fontSize = 20,
    this.color,
    this.angle = 0,
    this.textAlign,
  });

  final String text;
  final double fontSize;
  final Color? color;

  final double angle;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) {
    final text = Text(
      this.text,
      textAlign: textAlign,
      style: TextStyle(
        fontFamily: handwritingFont,
        fontSize: fontSize,
        height: 1.1,
        color: color ?? Theme.of(context).colorScheme.onSurface,
      ),
    );
    return angle == 0 ? text : Transform.rotate(angle: angle, child: text);
  }
}
