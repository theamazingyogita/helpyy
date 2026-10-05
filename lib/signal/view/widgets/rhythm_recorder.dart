import 'package:flutter/material.dart';

import '../../../widgets/handwritten.dart';
import '../../../widgets/pattern_dots.dart';
import '../../../widgets/text_link.dart';
import '../../bloc/new_signal_bloc.dart';

class RhythmRecorder extends StatelessWidget {
  const RhythmRecorder({super.key, required this.state, required this.onRetry});

  final NewSignalState state;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return switch (state.recordStatus) {
      RecordStatus.captured => Column(
        spacing: 8,
        children: [
          PatternDots(intervals: state.rhythm),
          Row(
            children: [
              Handwritten('got it, ${state.rhythm.length + 1} knocks'),
              const Spacer(),
              TextLink(label: 'Try again', onPressed: onRetry),
            ],
          ),
        ],
      ),
      RecordStatus.sensorUnavailable => Text(
        'This device has no usable motion sensor.',
        style: textTheme.bodyMedium,
      ),
      _ => Text(
        'Knock your rhythm on the back of your phone, then hold it still.',
        style: textTheme.bodyMedium,
      ),
    };
  }
}
