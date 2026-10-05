import 'package:flutter/material.dart';

import '../../widgets/screen_heading.dart';

class AuthHeading extends StatelessWidget {
  const AuthHeading({super.key, required this.eyebrow, required this.title});

  final String eyebrow;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      spacing: 12,
      children: [
        Expanded(
          child: ScreenHeading(eyebrow: eyebrow, title: title),
        ),
        // Mascot art goes here once we have it.
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.secondary,
            shape: BoxShape.circle,
          ),
        ),
      ],
    );
  }
}
