import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../call/view/call_page.dart';
import '../../profile/view/profile_button.dart';
import '../../signal/view/new_signal_page.dart';
import '../../widgets/app_logo.dart';
import '../../widgets/eyebrow.dart';
import '../../widgets/handwritten.dart';
import '../../widgets/ink_button.dart';
import '../bloc/home_bloc.dart';
import '../greeting.dart';
import 'widgets/listening_card.dart';
import 'widgets/signal_row.dart';

class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => HomeBloc(
        repository: context.read(),
        detector: context.read(),
        background: context.read(),
        backTap: context.read(),
      )..add(const HomeStarted()),
      child: const _HomeView(),
    );
  }
}

class _HomeView extends StatelessWidget {
  const _HomeView();

  Future<void> _showCall(BuildContext context, HomeState state) async {
    final pattern = state.incomingCall;
    if (pattern == null) return;
    final bloc = context.read<HomeBloc>();
    final messenger = ScaffoldMessenger.of(context);
    final saved = await Navigator.of(context).push(CallPage.route(pattern));
    bloc.add(const HomeCallEnded());
    if (saved == false) {
      messenger.showSnackBar(
        const SnackBar(content: Text('The call was not saved to history.')),
      );
    }
  }

  Future<void> _addSignal(BuildContext context) async {
    final bloc = context.read<HomeBloc>()
      ..add(const HomeSignalEditingStarted());
    await Navigator.of(context).push(NewSignalPage.route());
    bloc.add(const HomeSignalEditingFinished());
  }

  void _showProblem(BuildContext context, HomeState state) {
    final message = switch (state.status) {
      HomeStatus.deleteFailed => 'Could not delete that signal.',
      HomeStatus.sensorUnavailable =>
        'This device has no usable motion sensor.',
      HomeStatus.noSignals => 'Add a signal first, then turn listening on.',
      HomeStatus.noBackTapSignal =>
        'None of your signals uses that Back Tap. Add a tap count signal for '
            'it.',
      _ => null,
    };
    if (message == null) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<HomeBloc, HomeState>(
          listenWhen: (previous, current) =>
              previous.incomingCall != current.incomingCall,
          listener: _showCall,
        ),
        BlocListener<HomeBloc, HomeState>(
          listenWhen: (previous, current) => previous.status != current.status,
          listener: _showProblem,
        ),
      ],
      child: SafeArea(
        bottom: false,
        child: BlocBuilder<HomeBloc, HomeState>(
          builder: (context, state) => switch (state.status) {
            HomeStatus.loading => const Center(
              child: CircularProgressIndicator(),
            ),
            HomeStatus.loadFailed => const _LoadFailed(),
            _ => _Dashboard(
              state: state,
              onAddSignal: () => _addSignal(context),
            ),
          },
        ),
      ),
    );
  }
}

class _Dashboard extends StatelessWidget {
  const _Dashboard({required this.state, required this.onAddSignal});

  final HomeState state;
  final VoidCallback onAddSignal;

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<HomeBloc>();
    final colorScheme = Theme.of(context).colorScheme;
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 4,
                children: [
                  Eyebrow(greetingFor(DateTime.now())),
                  const AppLogo(),
                ],
              ),
            ),
            const ProfileButton(),
          ],
        ),
        const SizedBox(height: 24),
        ListeningCard(
          patterns: state.patterns,
          isListening: state.isListening,
          onToggled: (isOn) => bloc.add(HomeListeningToggled(isOn)),
        ),
        const SizedBox(height: 32),
        Row(
          children: [
            const Eyebrow('Your escape plan'),
            const Spacer(),
            Handwritten(
              state.patterns.isEmpty ? 'nothing yet' : 'ready to go',
              fontSize: 17,
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Divider(),
        if (state.patterns.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Text(
              'Add a signal, pick who calls, and tap it on the back of your '
              'phone when you need out.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          )
        else
          for (final pattern in state.patterns)
            SignalRow(
              pattern: pattern,
              onTest: () => bloc.add(HomeTestCallRequested(pattern)),
              onDelete: () => bloc.add(HomeSignalDeleted(pattern)),
            ),
        const SizedBox(height: 24),
        InkButton(
          label: 'Add a signal',
          icon: Icons.add,
          color: colorScheme.secondary,
          foreground: colorScheme.onSecondary,
          onPressed: onAddSignal,
        ),
      ],
    );
  }
}

class _LoadFailed extends StatelessWidget {
  const _LoadFailed();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: 16,
          children: [
            const Text('Your saved signals could not be read.'),
            InkButton(
              label: 'Try again',
              onPressed: () =>
                  context.read<HomeBloc>().add(const HomeStarted()),
            ),
          ],
        ),
      ),
    );
  }
}
