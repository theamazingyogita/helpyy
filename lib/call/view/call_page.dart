import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../app/app_colors.dart';
import '../../knock/knock_pattern.dart';
import '../../settings/data/settings_repository.dart';
import '../bloc/call_bloc.dart';
import 'widgets/countdown_view.dart';
import 'widgets/phone_call_view.dart';

/// Pops with true when the call was saved to history, false when saving
/// failed, and null when it was cancelled before ringing.
class CallPage extends StatelessWidget {
  const CallPage({super.key, required this.pattern});

  static Route<bool> route(KnockPattern pattern) => PageRouteBuilder(
    opaque: true,
    pageBuilder: (_, _, _) => CallPage(pattern: pattern),
    transitionsBuilder: (_, animation, _, child) =>
        FadeTransition(opacity: animation, child: child),
  );

  final KnockPattern pattern;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => CallBloc(
        callerName: pattern.callerName,
        delaySeconds: pattern.delaySeconds,
        log: context.read(),
        ringtones: context.read(),
        ringtone: context.read<SettingsRepository>().ringtone,
      ),
      child: _CallView(callerName: pattern.callerName),
    );
  }
}

class _CallView extends StatelessWidget {
  const _CallView({required this.callerName});

  final String callerName;

  void _onEnded(BuildContext context, CallState state) {
    Navigator.of(context).pop(state.wasCancelled ? null : !state.historyFailed);
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return BlocConsumer<CallBloc, CallState>(
      listenWhen: (previous, current) =>
          previous.phase != current.phase && current.phase == CallPhase.ended,
      listener: _onEnded,
      buildWhen: (_, current) => current.phase != CallPhase.ended,
      builder: (context, state) {
        final isCountdown = state.phase == CallPhase.countdown;
        return AnnotatedRegion(
          value: isCountdown
              ? SystemUiOverlayStyle.dark
              : SystemUiOverlayStyle.light,
          child: Scaffold(
            backgroundColor: isCountdown
                ? Theme.of(context).colorScheme.secondary
                : colors.callBackground,
            body: SafeArea(
              child: isCountdown
                  ? CountdownView(secondsLeft: state.secondsLeft)
                  : PhoneCallView(callerName: callerName, state: state),
            ),
          ),
        );
      },
    );
  }
}
