import 'package:flutter/material.dart';

class TriggerOption extends StatelessWidget {
  const TriggerOption({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
    this.child,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: colorScheme.outlineVariant)),
        ),
        child: Column(
          spacing: 16,
          children: [
            Row(
              spacing: 14,
              children: [
                Container(
                  width: 48,
                  height: 60,
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: colorScheme.outline, width: 1.5),
                  ),
                  child: Icon(icon, size: 22),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 2,
                    children: [
                      Text(title, style: textTheme.titleMedium),
                      Text(subtitle, style: textTheme.bodySmall),
                    ],
                  ),
                ),
                Icon(
                  isSelected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  color: isSelected ? colorScheme.primary : colorScheme.outline,
                ),
              ],
            ),
            if (isSelected) ?child,
          ],
        ),
      ),
    );
  }
}
