import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import '../../auth/bloc/auth_bloc.dart';
import '../../auth/data/app_user.dart';
import '../../auth/form_status.dart';
import '../../auth/validation.dart';
import '../../auth/widgets/labeled_field.dart';
import '../../avatar/cartoon_avatar.dart';
import '../../widgets/ink_button.dart';
import '../../widgets/screen_heading.dart';
import '../../widgets/top_bar.dart';
import '../bloc/profile_bloc.dart';
import 'widgets/editable_avatar.dart';
import 'widgets/photo_options_sheet.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key, required this.user, this.picker});

  static Route<void> route(AppUser user) =>
      MaterialPageRoute(builder: (_) => ProfilePage(user: user));

  final AppUser user;

  /// Swappable for tests. Defaults to the platform picker.
  final ImagePicker? picker;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ProfileBloc(context.read()),
      child: _ProfileView(user: user, picker: picker ?? ImagePicker()),
    );
  }
}

class _ProfileView extends StatefulWidget {
  const _ProfileView({required this.user, required this.picker});

  final AppUser user;
  final ImagePicker picker;

  @override
  State<_ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<_ProfileView> {
  late final _name = TextEditingController(text: widget.user.name);
  late final _email = TextEditingController(text: widget.user.email);

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    super.dispose();
  }

  Future<void> _editPhoto(AppUser user) async {
    final bloc = context.read<ProfileBloc>();
    final messenger = ScaffoldMessenger.of(context);
    final choice = await showPhotoOptions(
      context,
      hasPhoto: user.photoUrl != null,
      currentSeed: CartoonAvatar.seedOf(user.photoUrl),
    );
    switch (choice) {
      case null:
        return;
      case RemovePhoto():
        bloc.add(const ProfilePhotoRemoved());
      case PickAvatar(:final seed):
        bloc.add(ProfileAvatarChosen(seed));
      case PickFrom(:final source):
        try {
          final file = await widget.picker.pickImage(
            source: source,
            maxWidth: 800,
            imageQuality: 85,
          );
          if (file != null) bloc.add(ProfilePhotoChosen(file.path));
        } on PlatformException {
          messenger.showSnackBar(
            const SnackBar(
              content: Text(
                'helpyy cannot use the camera or photos. Allow access in '
                'Settings.',
              ),
            ),
          );
        }
    }
  }

  void _onState(BuildContext context, ProfileState state) {
    final message = switch (state) {
      ProfileState(isSaved: true) => 'Saved.',
      ProfileState(status: FormStatus.failed) => 'Could not save your changes.',
      _ => null,
    };
    if (message == null) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<ProfileBloc>();
    // Follow the live user so a saved name or photo shows straight away.
    final user =
        context.select((AuthBloc auth) => auth.state.user) ?? widget.user;
    return Scaffold(
      body: SafeArea(
        child: BlocConsumer<ProfileBloc, ProfileState>(
          listener: _onState,
          builder: (context, state) {
            final isBusy = state.status == FormStatus.submitting;
            return ListView(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              children: [
                TopBar(onBack: Navigator.of(context).pop),
                const SizedBox(height: 16),
                const ScreenHeading(eyebrow: 'That is you', title: 'Profile.'),
                const SizedBox(height: 28),
                Center(
                  child: EditableAvatar(
                    name: user.name,
                    photoUrl: user.photoUrl,
                    isBusy: isBusy,
                    onEdit: () => _editPhoto(user),
                  ),
                ),
                const SizedBox(height: 28),
                LabeledField(
                  label: 'Your name',
                  controller: _name,
                  error: state.nameError,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.done,
                  inputFormatters: nameInputFormatters,
                ),
                const SizedBox(height: 24),
                LabeledField(
                  label: 'Email address',
                  controller: _email,
                  enabled: false,
                ),
                // Only offer saving once there is something to save.
                ValueListenableBuilder(
                  valueListenable: _name,
                  builder: (context, name, _) => name.text.trim() == user.name
                      ? const SizedBox.shrink()
                      : Padding(
                          padding: const EdgeInsets.only(top: 28),
                          child: InkButton(
                            label: 'Save changes',
                            onPressed: isBusy
                                ? null
                                : () => bloc.add(ProfileNameSaved(name.text)),
                          ),
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
