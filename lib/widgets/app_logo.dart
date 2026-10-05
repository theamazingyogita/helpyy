import 'package:flutter/material.dart';

import '../app/app_theme.dart';

/// How much bigger the yellow dot is than the letters.
const dotScale = 1.6;

class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.fontSize = 28});

  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Text.rich(
      TextSpan(
        text: 'helpyy',
        children: [
          TextSpan(
            text: '.',
            style: TextStyle(
              color: colorScheme.secondary,
              fontSize: fontSize * dotScale,
            ),
          ),
        ],
      ),
      style: TextStyle(
        fontFamily: handwritingFont,
        fontSize: fontSize,
        height: 1,
        color: colorScheme.onSurface,
      ),
    );
  }
}
