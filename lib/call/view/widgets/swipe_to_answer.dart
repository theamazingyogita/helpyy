import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

import '../../../app/app_colors.dart';

/// Android's incoming call control: drag the button up to answer or down to
/// decline. While idle it hops and wiggles to show it can be dragged.
class SwipeToAnswer extends StatefulWidget {
  const SwipeToAnswer({
    super.key,
    required this.onAnswered,
    required this.onDeclined,
  });

  final VoidCallback onAnswered;
  final VoidCallback onDeclined;

  @override
  State<SwipeToAnswer> createState() => _SwipeToAnswerState();
}

class _SwipeToAnswerState extends State<SwipeToAnswer>
    with TickerProviderStateMixin {
  static const _travel = 110.0;
  static const _commitAt = 80.0;
  static const _buttonSize = 76.0;

  // Room for the idle hop. A drag paints over the labels and arrows, which
  // fade out of its way, so the control stays short enough for small phones.
  static const _buttonSlot = _buttonSize + 24;

  late final _hint = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  );

  // Up is negative, the way Flutter's y axis runs.
  late final _offset = AnimationController.unbounded(vsync: this);

  var _isDone = false;

  bool get _reduceMotion => MediaQuery.disableAnimationsOf(context);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion ? _hint.stop() : _resumeHint();
  }

  @override
  void dispose() {
    _hint.dispose();
    _offset.dispose();
    super.dispose();
  }

  void _resumeHint() {
    if (!_isDone && !_hint.isAnimating) _hint.repeat();
  }

  void _onDragStart(DragStartDetails _) {
    _hint
      ..stop()
      ..value = 0;
  }

  void _onDragUpdate(DragUpdateDetails details) {
    if (_isDone) return;
    _offset.value = (_offset.value + details.delta.dy).clamp(-_travel, _travel);
  }

  void _onDragEnd(DragEndDetails _) {
    if (_isDone) return;
    if (_offset.value <= -_commitAt) return _finish(widget.onAnswered);
    if (_offset.value >= _commitAt) return _finish(widget.onDeclined);
    _offset
        .animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutBack,
        )
        .whenComplete(() {
          if (mounted && !_reduceMotion) _resumeHint();
        });
  }

  void _finish(VoidCallback action) {
    _isDone = true;
    _hint.stop();
    action();
  }

  // A short hop at the start of each beat, then a rest.
  double _hintLift(double t) {
    if (t > 0.35) return 0;
    return -math.sin(t / 0.35 * math.pi) * 16;
  }

  double _hintWiggle(double t) {
    if (t > 0.35) return 0;
    return math.sin(t / 0.35 * math.pi * 4) * 0.25;
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final labelStyle = Theme.of(
      context,
    ).textTheme.labelMedium?.copyWith(color: colors.onCall);

    return Semantics(
      label: 'Incoming call',
      customSemanticsActions: {
        const CustomSemanticsAction(label: 'Answer'): widget.onAnswered,
        const CustomSemanticsAction(label: 'Decline'): widget.onDeclined,
      },
      child: AnimatedBuilder(
        animation: Listenable.merge([_hint, _offset]),
        builder: (context, _) {
          final drag = _offset.value;
          final towardsDecline = (drag / _commitAt).clamp(0.0, 1.0);
          final towardsAnswer = (-drag / _commitAt).clamp(0.0, 1.0);
          final idle = drag == 0;
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Opacity(
                opacity: 1 - towardsDecline,
                child: Text('Swipe up to answer', style: labelStyle),
              ),
              _Chevrons(
                progress: _hint.value,
                color: colors.onCall,
                opacity: 1 - math.max(towardsAnswer, towardsDecline),
              ),
              SizedBox(
                height: _buttonSlot,
                child: Center(
                  child: Transform.translate(
                    offset: Offset(0, idle ? _hintLift(_hint.value) : drag),
                    child: GestureDetector(
                      onVerticalDragStart: _onDragStart,
                      onVerticalDragUpdate: _onDragUpdate,
                      onVerticalDragEnd: _onDragEnd,
                      child: Container(
                        width: _buttonSize,
                        height: _buttonSize,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color.lerp(
                            colors.accept,
                            colors.decline,
                            towardsDecline,
                          ),
                        ),
                        child: Transform.rotate(
                          // Turns into the hang up handset on the way down.
                          angle: idle
                              ? _hintWiggle(_hint.value)
                              : towardsDecline * math.pi * 0.75,
                          child: Icon(
                            Icons.call,
                            size: 34,
                            color: colors.onCall,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Opacity(
                opacity: 1 - towardsAnswer,
                child: Text('Swipe down to decline', style: labelStyle),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Three arrows above the button that light up bottom to top.
class _Chevrons extends StatelessWidget {
  const _Chevrons({
    required this.progress,
    required this.color,
    required this.opacity,
  });

  final double progress;
  final Color color;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: opacity,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 2; i >= 0; i--)
            Icon(
              Icons.keyboard_arrow_up,
              size: 18,
              color: color.withValues(alpha: _brightness(i)),
            ),
        ],
      ),
    );
  }

  double _brightness(int index) {
    final peak = 0.2 + index * 0.15;
    final distance = (progress - peak).abs();
    return (1 - distance * 4).clamp(0.25, 1.0);
  }
}
