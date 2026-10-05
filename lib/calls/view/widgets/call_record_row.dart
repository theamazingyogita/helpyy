import 'package:flutter/material.dart';

import '../../../widgets/initial_avatar.dart';
import '../../data/call_record.dart';

class CallRecordRow extends StatelessWidget {
  const CallRecordRow({super.key, required this.record});

  final CallRecord record;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final localizations = MaterialLocalizations.of(context);
    final when =
        '${localizations.formatShortDate(record.startedAt)}, '
        '${localizations.formatTimeOfDay(TimeOfDay.fromDateTime(record.startedAt))}';
    final talk = record.talkTime;
    final outcome = record.answered
        ? 'Answered · ${talk.inMinutes}:${(talk.inSeconds % 60).toString().padLeft(2, '0')}'
        : 'Declined';

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
      ),
      child: Row(
        spacing: 14,
        children: [
          InitialAvatar(name: record.callerName, size: 40),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(record.callerName, style: textTheme.titleMedium),
                Text(when, style: textTheme.bodySmall),
              ],
            ),
          ),
          Text(outcome, style: textTheme.labelMedium),
        ],
      ),
    );
  }
}
