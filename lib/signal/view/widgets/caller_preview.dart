import 'package:flutter/material.dart';

import '../../../app/app_colors.dart';
import '../../../widgets/initial_avatar.dart';

class CallerPreview extends StatelessWidget {
  const CallerPreview({super.key, required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final ink = AppColors.of(context).ink;
    final shown = name.isEmpty ? 'Caller' : name;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.primary,
        border: Border.all(color: ink, width: 1.5),
        boxShadow: [BoxShadow(color: ink, offset: const Offset(4, 4))],
      ),
      child: Row(
        spacing: 16,
        children: [
          InitialAvatar(name: shown),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                shown,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: colorScheme.onPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                'mobile',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: colorScheme.onPrimary),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
