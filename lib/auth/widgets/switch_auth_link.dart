import 'package:flutter/material.dart';

import '../../widgets/text_link.dart';
import '../../widgets/brand_text.dart';

/// "Already on helpyy? Log in" style line at the bottom of auth screens.
class SwitchAuthLink extends StatelessWidget {
  const SwitchAuthLink({
    super.key,
    required this.question,
    required this.action,
    required this.onPressed,
  });

  final String question;
  final String action;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        BrandText(question, style: Theme.of(context).textTheme.bodyMedium),
        TextLink(label: action, onPressed: onPressed),
      ],
    );
  }
}
