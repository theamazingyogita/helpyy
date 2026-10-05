import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../profile/view/profile_summary.dart';
import '../../widgets/box_choice.dart';
import '../../widgets/eyebrow.dart';
import '../../widgets/screen_heading.dart';
import '../../widgets/text_link.dart';
import '../bloc/settings_bloc.dart';
import '../motion_sensitivity.dart';
import 'widgets/back_tap_guide.dart';
import 'widgets/log_out_row.dart';
import 'widgets/privacy_note.dart';
import 'widgets/ringtone_setting.dart';

class SettingsTab extends StatelessWidget {
  const SettingsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => SettingsBloc(context.read(), player: context.read()),
      child: BlocConsumer<SettingsBloc, SettingsState>(
        listenWhen: (_, current) => current.saveFailed || current.pickerFailed,
        listener: (context, state) =>
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  state.pickerFailed
                      ? 'Could not open the ringtone list.'
                      : 'Could not save that setting.',
                ),
              ),
            ),
        builder: (context, state) => SafeArea(
          bottom: false,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
            children: [
              const ScreenHeading(eyebrow: 'Make it yours', title: 'Settings.'),
              const SizedBox(height: 16),
              const ProfileSummary(),
              const SizedBox(height: 28),
              const Eyebrow('Motion sensitivity'),
              const SizedBox(height: 10),
              BoxChoice(
                options: MotionSensitivity.values,
                selected: state.sensitivity,
                labelOf: (value) => value.label,
                onSelected: (value) =>
                    context.read<SettingsBloc>().add(SensitivityChosen(value)),
              ),
              const SizedBox(height: 8),
              Text(
                'Turn it up if soft taps are missed, down if bumps set off '
                'calls.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 28),
              const Eyebrow('Ringtone'),
              const SizedBox(height: 10),
              RingtoneSetting(ringtone: state.ringtone),
              if (Theme.of(context).platform == TargetPlatform.iOS) ...[
                const SizedBox(height: 28),
                const Eyebrow('Back Tap'),
                const SizedBox(height: 10),
                const BackTapGuide(),
              ],
              const SizedBox(height: 32),
              const PrivacyNote(),
              const SizedBox(height: 32),
              const Eyebrow('Account'),
              const SizedBox(height: 8),
              const LogOutRow(),
              const SizedBox(height: 24),
              // Shows every package licence, including the credit the
              // Adventurer characters need.
              Center(
                child: TextLink(
                  label: 'Licenses',
                  onPressed: () => showLicensePage(
                    context: context,
                    applicationName: 'helpyy',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
