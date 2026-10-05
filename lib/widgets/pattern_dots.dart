import 'package:flutter/material.dart';

/// Draws a knock rhythm as dots spaced by the gaps between knocks.
class PatternDots extends StatelessWidget {
  const PatternDots({super.key, required this.intervals});

  final List<int> intervals;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return Row(
      children: [
        _Dot(color: color),
        for (final gap in intervals) ...[
          Expanded(
            flex: gap,
            child: Divider(
              height: 2,
              thickness: 2,
              color: color.withValues(alpha: 0.3),
            ),
          ),
          _Dot(color: color),
        ],
      ],
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
