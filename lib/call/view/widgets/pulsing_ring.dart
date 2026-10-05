import 'package:flutter/material.dart';

/// Rings that keep spreading out from behind [child], like the answer button
/// of an incoming call. Still when the system asks for reduced motion.
class PulsingRing extends StatefulWidget {
  const PulsingRing({super.key, required this.color, required this.child});

  final Color color;
  final Widget child;

  @override
  State<PulsingRing> createState() => _PulsingRingState();
}

class _PulsingRingState extends State<PulsingRing>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        // Two rings half a beat apart, so one is always on its way out.
        for (final lag in const [0.0, 0.5])
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                final t = _controller.isAnimating
                    ? (_controller.value + lag) % 1
                    : 1.0;
                return Transform.scale(
                  scale: 1 + t * 0.7,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: widget.color.withValues(alpha: (1 - t) * 0.45),
                    ),
                  ),
                );
              },
            ),
          ),
        widget.child,
      ],
    );
  }
}
