import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../app/app_colors.dart';

/// Page indicator that follows the swipe. The current page is a long pill.
/// As you leave it, it curls up into a ball and shrinks back to a dot, while
/// the next dot puffs up like a balloon and then stretches into the pill.
class BalloonDots extends StatelessWidget {
  const BalloonDots({super.key, required this.controller, required this.count});

  final PageController controller;
  final int count;

  static const _dot = 10.0;
  static const _balloon = 18.0;
  static const _pill = 40.0;

  double get _page {
    if (!controller.hasClients || !controller.position.haveDimensions) return 0;
    return controller.page ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final page = _page;
        return SizedBox(
          height: _balloon + 6,
          child: Row(
            spacing: 8,
            children: [
              for (var i = 0; i < count; i++)
                _Balloon(focus: 1 - (page - i).abs().clamp(0.0, 1.0)),
            ],
          ),
        );
      },
    );
  }
}

class _Balloon extends StatelessWidget {
  const _Balloon({required this.focus});

  /// 0 when far from this page, 1 when it is the current page.
  final double focus;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final ink = AppColors.of(context).ink;

    final double width;
    final double height;
    if (focus < 0.5) {
      // Inflate: a round dot that overshoots slightly, like a puff of air.
      final t = Curves.easeOutBack.transform(focus / 0.5);
      width = height =
          BalloonDots._dot + (BalloonDots._balloon - BalloonDots._dot) * t;
    } else {
      // Stretch: the balloon squashes a little as it pulls into a pill.
      final t = Curves.easeOutBack.transform((focus - 0.5) / 0.5);
      width =
          BalloonDots._balloon + (BalloonDots._pill - BalloonDots._balloon) * t;
      height = BalloonDots._balloon - 6 * math.sin(t.clamp(0, 1) * math.pi / 2);
    }

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Color.lerp(colorScheme.surface, colorScheme.secondary, focus),
        borderRadius: BorderRadius.circular(height / 2),
        border: Border.all(color: ink, width: 1.5),
        boxShadow: focus > 0.5
            ? [BoxShadow(color: ink, offset: Offset(2 * focus, 2 * focus))]
            : null,
      ),
    );
  }
}
