import 'package:flutter/material.dart';

import 'handwritten.dart';

class IllustrationSlot extends StatelessWidget {
  const IllustrationSlot({super.key, required this.caption, this.height = 120});

  final String caption;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      alignment: Alignment.bottomRight,
      child: Handwritten(caption, angle: 0.04),
    );
  }
}
