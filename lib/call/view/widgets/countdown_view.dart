import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/app_theme.dart';
import '../../../widgets/eyebrow.dart';
import '../../../widgets/text_link.dart';
import '../../../widgets/top_bar.dart';
import '../../bloc/call_bloc.dart';

class CountdownView extends StatelessWidget {
  const CountdownView({super.key, required this.secondsLeft});

  final int secondsLeft;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          TopBar(
            trailing: TextLink(
              label: 'Cancel',
              onPressed: () =>
                  context.read<CallBloc>().add(const CallCancelled()),
            ),
          ),
          const Spacer(),
          const Eyebrow('Call on the way'),
          const SizedBox(height: 20),
          Container(
            width: 150,
            height: 150,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: colorScheme.outline, width: 1.5),
            ),
            child: Text(
              '$secondsLeft',
              style: TextStyle(
                fontFamily: handwritingFont,
                fontSize: 84,
                height: 1,
                color: colorScheme.onSecondary,
              ),
            ),
          ),
          const SizedBox(height: 28),
          Text('Act natural.', style: textTheme.headlineLarge),
          const SizedBox(height: 8),
          Text(
            'Your escape call is about to arrive.',
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSecondary,
            ),
          ),
          const Spacer(flex: 2),
        ],
      ),
    );
  }
}
