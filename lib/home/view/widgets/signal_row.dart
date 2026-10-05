import 'package:flutter/material.dart';

import '../../../knock/knock_pattern.dart';
import '../../../widgets/circle_icon.dart';
import '../../../widgets/eyebrow.dart';
import '../../../widgets/pattern_dots.dart';
import 'test_call_button.dart';

class SignalRow extends StatelessWidget {
  const SignalRow({
    super.key,
    required this.pattern,
    required this.onTest,
    required this.onDelete,
  });

  final KnockPattern pattern;
  final VoidCallback onTest;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final rhythm = pattern.rhythm;
    final trigger = rhythm == null
        ? '${pattern.knockCount} taps'
        : 'Rhythm · ${pattern.knockCount} knocks';
    final delay = pattern.delaySeconds == 0
        ? 'rings right away'
        : 'rings after ${pattern.delaySeconds}s';

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 14,
        children: [
          CircleIcon(
            rhythm == null ? Icons.touch_app_outlined : Icons.graphic_eq,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 2,
              children: [
                Eyebrow(trigger),
                Text(pattern.callerName, style: textTheme.titleMedium),
                Text(delay, style: textTheme.bodySmall),
                if (rhythm != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: PatternDots(intervals: rhythm),
                  ),
                const SizedBox(height: 10),
                TestCallButton(onPressed: onTest),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Delete',
            icon: const Icon(Icons.delete_outline),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}
