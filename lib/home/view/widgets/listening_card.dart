import 'package:flutter/material.dart';

import '../../../app/app_colors.dart';
import '../../../knock/knock_pattern.dart';
import '../../../widgets/eyebrow.dart';
import '../../../widgets/handwritten.dart';
import '../../../widgets/brand_text.dart';

class ListeningCard extends StatelessWidget {
  const ListeningCard({
    super.key,
    required this.patterns,
    required this.isListening,
    required this.onToggled,
  });

  final List<KnockPattern> patterns;
  final bool isListening;
  final ValueChanged<bool> onToggled;

  String get _summary => switch (patterns) {
    [] => 'No signal yet',
    [final only] when only.rhythm == null =>
      '${only.knockCount} taps → ${only.callerName}',
    [final only] => 'Rhythm → ${only.callerName}',
    _ => '${patterns.length} signals',
  };

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final ink = AppColors.of(context).ink;
    final onCard = colorScheme.onPrimary;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.primary,
        border: Border.all(color: ink, width: 1.5),
        boxShadow: [BoxShadow(color: ink, offset: const Offset(4, 4))],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 8, 6),
            child: Row(
              spacing: 8,
              children: [
                Icon(
                  Icons.circle,
                  size: 8,
                  color: isListening ? colorScheme.secondary : onCard,
                ),
                Expanded(
                  child: Eyebrow(
                    isListening ? 'Helpyy is listening' : 'Helpyy is paused',
                    color: onCard,
                  ),
                ),
                Switch(value: isListening, onChanged: onToggled),
              ],
            ),
          ),
          Divider(color: ink, height: 1.5, thickness: 1.5),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              spacing: 18,
              children: [
                Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    color: colorScheme.secondary,
                    shape: BoxShape.circle,
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 4,
                    children: [
                      Eyebrow('Your signal', color: onCard),
                      Handwritten(_summary, fontSize: 30, color: onCard),
                      BrandText(
                        switch (Theme.of(context).platform) {
                          TargetPlatform.android =>
                            'Tap the back of your phone. helpyy keeps '
                                'listening in the background.',
                          TargetPlatform.iOS =>
                            'Tap the back with helpyy open, or set up Back '
                                'Tap in Settings to call from anywhere.',
                          _ =>
                            'Keep helpyy open and tap the back of your phone.',
                        },
                        style: Theme.of(
                          context,
                        ).textTheme.bodySmall?.copyWith(color: onCard),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
