import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../widgets/ink_button.dart';
import '../../../widgets/screen_heading.dart';
import '../../bloc/new_signal_bloc.dart';
import 'rhythm_recorder.dart';
import 'tap_count_stepper.dart';
import 'trigger_option.dart';

class TriggerStep extends StatelessWidget {
  const TriggerStep({super.key});

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<NewSignalBloc>();
    return BlocBuilder<NewSignalBloc, NewSignalState>(
      builder: (context, state) => Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              children: [
                const ScreenHeading(
                  eyebrow: 'Choose a trigger',
                  title: 'What feels natural?',
                  body:
                      'Pick taps you can make on the back of your phone '
                      'without anyone noticing.',
                ),
                const SizedBox(height: 20),
                const Divider(),
                TriggerOption(
                  icon: Icons.touch_app_outlined,
                  title: 'Tap count',
                  subtitle: bloc.isBackTapOnly
                      ? 'A double or triple tap, so it works with iPhone '
                            'Back Tap even when helpyy is closed'
                      : 'Tap the back of your phone a set number of times',
                  isSelected: !state.useRhythm,
                  onTap: () =>
                      bloc.add(const TriggerKindChosen(useRhythm: false)),
                  child: TapCountStepper(
                    count: state.tapCount,
                    min: bloc.minTaps,
                    max: bloc.maxTaps,
                    onChanged: (count) => bloc.add(TapCountChanged(count)),
                  ),
                ),
                if (!bloc.isBackTapOnly)
                  TriggerOption(
                    icon: Icons.graphic_eq,
                    title: 'Custom rhythm',
                    subtitle: 'Knock your own secret pattern',
                    isSelected: state.useRhythm,
                    onTap: () =>
                        bloc.add(const TriggerKindChosen(useRhythm: true)),
                    child: RhythmRecorder(
                      state: state,
                      onRetry: () => bloc.add(const RhythmRetried()),
                    ),
                  ),
              ],
            ),
          ),
          if (state.clashes)
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
              child: Text(
                'One of your saved signals already uses this. '
                'Pick something different.',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
            child: InkButton(
              label: 'Next',
              onPressed: state.canContinue
                  ? () => bloc.add(const TriggerConfirmed())
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}
