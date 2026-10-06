import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/app_colors.dart';
import '../../../widgets/initial_avatar.dart';
import '../../bloc/call_bloc.dart';
import 'round_call_button.dart';
import 'swipe_to_answer.dart';

class PhoneCallView extends StatelessWidget {
  const PhoneCallView({
    super.key,
    required this.callerName,
    required this.state,
  });

  final String callerName;
  final CallState state;

  String _talkTime(Duration elapsed) {
    final minutes = elapsed.inMinutes.toString().padLeft(2, '0');
    final seconds = (elapsed.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final textTheme = Theme.of(context).textTheme;
    final bloc = context.read<CallBloc>();
    final isRinging = state.phase == CallPhase.ringing;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 80, 24, 48),
      child: Column(
        children: [
          InitialAvatar(name: callerName, size: 120),
          const SizedBox(height: 24),
          Text(
            callerName,
            textAlign: TextAlign.center,
            style: textTheme.displaySmall?.copyWith(color: colors.onCall),
          ),
          const SizedBox(height: 6),
          Text(
            isRinging ? 'mobile' : _talkTime(state.elapsed),
            style: textTheme.titleSmall?.copyWith(
              color: colors.onCall.withValues(alpha: 0.75),
            ),
          ),
          const Spacer(),
          if (isRinging && Theme.of(context).platform != TargetPlatform.iOS)
            SwipeToAnswer(
              onAnswered: () => bloc.add(const CallAnswered()),
              onDeclined: () => bloc.add(const CallHungUp()),
            )
          else
            Row(
              children: [
                Expanded(
                  child: RoundCallButton(
                    label: isRinging ? 'Decline' : 'End',
                    icon: Icons.call_end,
                    color: colors.decline,
                    onPressed: () => bloc.add(const CallHungUp()),
                  ),
                ),
                if (isRinging)
                  Expanded(
                    child: RoundCallButton(
                      label: 'Answer',
                      icon: Icons.call,
                      color: colors.accept,
                      isPulsing: true,
                      onPressed: () => bloc.add(const CallAnswered()),
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}
