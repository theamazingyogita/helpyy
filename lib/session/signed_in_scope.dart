import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../auth/data/app_user.dart';
import '../knock/knock_detector.dart';
import '../settings/data/settings_repository.dart';
import 'user_repositories.dart';

/// Provides the signed in user's repositories to everything below it.
///
/// Give it a key from the user id so switching accounts builds fresh
/// repositories and never shows one user's data to another.
class SignedInScope extends StatefulWidget {
  const SignedInScope({
    super.key,
    required this.user,
    required this.repositoriesFor,
    required this.detectorFor,
    required this.child,
  });

  final AppUser user;
  final UserRepositories Function(AppUser user) repositoriesFor;
  final KnockDetector Function(SettingsRepository settings) detectorFor;
  final Widget child;

  @override
  State<SignedInScope> createState() => _SignedInScopeState();
}

class _SignedInScopeState extends State<SignedInScope> {
  late final UserRepositories _repositories = widget.repositoriesFor(
    widget.user,
  );
  late final KnockDetector _detector = widget.detectorFor(
    _repositories.settings,
  );

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: _repositories.patterns),
        RepositoryProvider.value(value: _repositories.callLog),
        RepositoryProvider.value(value: _repositories.settings),
        RepositoryProvider.value(value: _detector),
      ],
      child: widget.child,
    );
  }
}
