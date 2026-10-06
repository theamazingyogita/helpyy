import 'package:flutter/material.dart';

import '../app/app_colors.dart';
import 'brand_text.dart';

class InkButton extends StatelessWidget {
  const InkButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.color,
    this.foreground,
    this.icon = Icons.arrow_forward,
  });

  final String label;
  final VoidCallback? onPressed;
  final Color? color;
  final Color? foreground;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final ink = AppColors.of(context).ink;
    final isEnabled = onPressed != null;
    final background = isEnabled
        ? color ?? colorScheme.primary
        : colorScheme.outlineVariant;
    final textColor = foreground ?? colorScheme.onPrimary;

    return Semantics(
      button: true,
      enabled: isEnabled,
      child: Container(
        decoration: BoxDecoration(
          color: background,
          border: Border.all(color: ink, width: 1.5),
          boxShadow: isEnabled
              ? [BoxShadow(color: ink, offset: const Offset(4, 4))]
              : null,
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: onPressed,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              child: Row(
                children: [
                  Expanded(
                    child: BrandText(
                      label,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: textColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Icon(icon, color: textColor, size: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
