import 'package:flutter/material.dart';

import '../../../app/app_colors.dart';

class TestCallButton extends StatelessWidget {
  const TestCallButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final ink = AppColors.of(context).ink;
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.secondary,
        border: Border.all(color: ink, width: 1.5),
        boxShadow: [BoxShadow(color: ink, offset: const Offset(2, 2))],
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              spacing: 6,
              children: [
                Icon(
                  Icons.phone_in_talk,
                  size: 16,
                  color: colorScheme.onSecondary,
                ),
                Text(
                  'Test call',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: colorScheme.onSecondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
