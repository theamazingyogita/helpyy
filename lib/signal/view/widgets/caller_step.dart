import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../widgets/box_choice.dart';
import '../../../widgets/eyebrow.dart';
import '../../../widgets/ink_button.dart';
import '../../../widgets/screen_heading.dart';
import '../../bloc/new_signal_bloc.dart';
import 'caller_preview.dart';

class CallerStep extends StatefulWidget {
  const CallerStep({super.key});

  @override
  State<CallerStep> createState() => _CallerStepState();
}

class _CallerStepState extends State<CallerStep> {
  final _name = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<NewSignalBloc>();
    return ValueListenableBuilder(
      valueListenable: _name,
      builder: (context, name, _) => Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              children: [
                const ScreenHeading(
                  eyebrow: 'Make it believable',
                  title: 'Who should call you?',
                ),
                const SizedBox(height: 24),
                CallerPreview(name: name.text.trim()),
                const SizedBox(height: 28),
                const Eyebrow('Caller name'),
                const SizedBox(height: 8),
                TextField(
                  controller: _name,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(hintText: 'Maya'),
                ),
                const SizedBox(height: 28),
                const Eyebrow('Call arrives after'),
                const SizedBox(height: 8),
                BlocSelector<NewSignalBloc, NewSignalState, int>(
                  selector: (state) => state.delaySeconds,
                  builder: (context, delay) => BoxChoice(
                    options: const [0, 5, 10],
                    selected: delay,
                    labelOf: (seconds) =>
                        seconds == 0 ? 'Now' : '$seconds seconds',
                    onSelected: (seconds) => bloc.add(CallDelayChosen(seconds)),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
            child: BlocSelector<NewSignalBloc, NewSignalState, bool>(
              selector: (state) => state.saveStatus == SaveStatus.saving,
              builder: (context, isSaving) => InkButton(
                label: 'Save signal',
                onPressed: name.text.trim().isEmpty || isSaving
                    ? null
                    : () => bloc.add(SignalSaved(name.text)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
