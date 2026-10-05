import 'package:flutter/material.dart';

import 'app_monogram.dart';
import 'handwritten.dart';

/// Space for the character art, showing the app logo until the artwork is
/// ready.
class IllustrationSlot extends StatelessWidget {
  const IllustrationSlot({super.key, required this.caption, this.height = 260});

  final String caption;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Stack(
        children: [
          Align(
            alignment: const Alignment(0.5, -0.3),
            child: AppMonogram(size: height * 0.68),
          ),
          Align(
            alignment: Alignment.bottomRight,
            child: Handwritten(caption, angle: 0.04),
          ),
        ],
      ),
    );
  }
}
