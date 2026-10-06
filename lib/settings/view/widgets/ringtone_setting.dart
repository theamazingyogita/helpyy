import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../ringtone/ringtone.dart';
import '../../../widgets/box_choice.dart';
import '../../../widgets/circle_icon.dart';
import '../../bloc/settings_bloc.dart';

class RingtoneSetting extends StatelessWidget {
  const RingtoneSetting({super.key, required this.ringtone});

  final Ringtone? ringtone;

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<SettingsBloc>();
    if (Theme.of(context).platform == TargetPlatform.iOS) {
      return BoxChoice(
        options: Ringtone.bundled,
        selected: ringtone ?? Ringtone.bundled.first,
        labelOf: (tone) => tone.title,
        onSelected: (tone) => bloc.add(RingtoneChosen(tone)),
      );
    }
    final textTheme = Theme.of(context).textTheme;
    return InkWell(
      onTap: () => bloc.add(const RingtonePickerOpened()),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          border: Border.symmetric(
            horizontal: BorderSide(
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
          ),
        ),
        child: Row(
          spacing: 14,
          children: [
            const CircleIcon(Icons.music_note),
            Expanded(
              child: Text(
                ringtone?.title ?? 'Phone default',
                style: textTheme.titleMedium,
              ),
            ),
            Text('Change', style: textTheme.labelMedium),
          ],
        ),
      ),
    );
  }
}
