import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../auth/bloc/auth_bloc.dart';
import '../../widgets/initial_avatar.dart';
import 'profile_page.dart';

class ProfileButton extends StatelessWidget {
  const ProfileButton({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.select((AuthBloc bloc) => bloc.state.user);
    if (user == null) return const SizedBox.shrink();
    return Semantics(
      button: true,
      label: 'Profile',
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () => Navigator.of(context).push(ProfilePage.route(user)),
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Theme.of(context).colorScheme.outline),
          ),
          child: InitialAvatar(
            name: user.name,
            photoUrl: user.photoUrl,
            size: 44,
          ),
        ),
      ),
    );
  }
}
