import 'package:flutter/material.dart';

/// Underlined text action, like "Skip" or "Cancel".
class TextLink extends StatelessWidget {
  const TextLink({super.key, required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurface;
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(foregroundColor: color),
      child: Text(
        label,
        style: TextStyle(
          decoration: TextDecoration.underline,
          decorationColor: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
