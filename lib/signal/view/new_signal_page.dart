import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../widgets/top_bar.dart';
import '../bloc/new_signal_bloc.dart';
import 'widgets/caller_step.dart';
import 'widgets/trigger_step.dart';

class NewSignalPage extends StatelessWidget {
  const NewSignalPage({super.key});

  static Route<void> route() =>
      MaterialPageRoute(builder: (_) => const NewSignalPage());

  @override
  Widget build(BuildContext context) {
    final isIOS = Theme.of(context).platform == TargetPlatform.iOS;
    return BlocProvider(
      create: (context) => NewSignalBloc(
        repository: context.read(),
        detector: context.read(),
        isBackTapOnly: isIOS,
      )..add(const NewSignalStarted()),
      child: const _NewSignalView(),
    );
  }
}

class _NewSignalView extends StatelessWidget {
  const _NewSignalView();

  void _back(BuildContext context) {
    final bloc = context.read<NewSignalBloc>();
    if (bloc.state.step == SignalStep.trigger) {
      Navigator.of(context).pop();
    } else {
      bloc.add(const CallerStepLeft());
    }
  }

  void _onSaveStatus(BuildContext context, NewSignalState state) {
    if (state.saveStatus == SaveStatus.saved) {
      Navigator.of(context).pop();
    } else if (state.saveStatus == SaveStatus.failed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not save the signal.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<NewSignalBloc, NewSignalState>(
      listenWhen: (previous, current) =>
          previous.saveStatus != current.saveStatus,
      listener: _onSaveStatus,
      buildWhen: (previous, current) => previous.step != current.step,
      builder: (context, state) => PopScope(
        canPop: state.step == SignalStep.trigger,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) _back(context);
        },
        child: Scaffold(
          body: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: TopBar(
                    onBack: () => _back(context),
                    trailing: Text(
                      state.step == SignalStep.trigger ? '01 / 02' : '02 / 02',
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ),
                ),
                Expanded(
                  child: state.step == SignalStep.trigger
                      ? const TriggerStep()
                      : const CallerStep(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
