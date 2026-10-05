import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../auth/bloc/auth_bloc.dart';
import '../../widgets/initial_avatar.dart';
import 'profile_page.dart';

/// Avatar, name and email row that opens the profile. Used in Settings.
class ProfileSummary extends StatelessWidget {
  const ProfileSummary({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.select((AuthBloc bloc) => bloc.state.user);
    if (user == null) return const SizedBox.shrink();
    final textTheme = Theme.of(context).textTheme;
    return InkWell(
      onTap: () => Navigator.of(context).push(ProfilePage.route(user)),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Theme.of(context).colorScheme.outline),
          ),
        ),
        child: Row(
          spacing: 16,
          children: [
            InitialAvatar(name: user.name, photoUrl: user.photoUrl, size: 60),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(user.name, style: textTheme.titleLarge),
                  Text(user.email, style: textTheme.bodySmall),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward),
          ],
        ),
      ),
    );
  }
}
