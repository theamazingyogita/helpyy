import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../auth/bloc/auth_bloc.dart';
import '../background/background_listening.dart';
import '../auth/data/app_user.dart';
import '../auth/data/auth_repository.dart';
import '../auth/log_in/view/log_in_page.dart';
import '../auth/new_password/view/new_password_page.dart';
import '../knock/back_tap_shortcuts.dart';
import '../knock/knock_detector.dart';
import '../onboarding/bloc/intro_bloc.dart';
import '../onboarding/data/intro_repository.dart';
import '../onboarding/view/onboarding_page.dart';
import '../ringtone/ringtone_player.dart';
import '../session/signed_in_scope.dart';
import '../session/user_repositories.dart';
import '../settings/data/settings_repository.dart';
import '../shell/shell_page.dart';
import '../widgets/app_logo.dart';
import 'app_theme.dart';

class TickleApp extends StatefulWidget {
  const TickleApp({
    super.key,
    required this.auth,
    required this.intro,
    required this.repositoriesFor,
    required this.detectorFor,
    this.ringtones = const RingtonePlayer(),
    this.background = const BackgroundListening(),
    this.backTap = const BackTapShortcuts(),
  });

  final AuthRepository auth;
  final IntroRepository intro;
  final UserRepositories Function(AppUser user) repositoriesFor;
  final KnockDetector Function(SettingsRepository settings) detectorFor;
  final RingtonePlayer ringtones;
  final BackgroundListening background;
  final BackTapShortcuts backTap;

  @override
  State<TickleApp> createState() => _TickleAppState();
}

class _TickleAppState extends State<TickleApp> {
  final _navigator = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: widget.auth),
        RepositoryProvider.value(value: widget.ringtones),
        RepositoryProvider.value(value: widget.background),
        RepositoryProvider.value(value: widget.backTap),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (_) => AuthBloc(widget.auth)..add(const AuthStarted()),
          ),
          BlocProvider(create: (_) => IntroBloc(widget.intro)),
        ],
        child: BlocListener<AuthBloc, AuthState>(
          listenWhen: (previous, current) =>
              previous.status != current.status ||
              previous.user?.id != current.user?.id,
          listener: (_, _) =>
              _navigator.currentState?.popUntil((route) => route.isFirst),
          child: MaterialApp(
            title: 'helpyy',
            navigatorKey: _navigator,
            debugShowCheckedModeBanner: false,
            theme: buildAppTheme(),
            builder: (context, navigator) =>
                BlocSelector<AuthBloc, AuthState, AppUser?>(
                  selector: (auth) => auth.user,
                  builder: (context, user) => user == null
                      ? navigator ?? const SizedBox.shrink()
                      : SignedInScope(
                          key: ValueKey(user.id),
                          user: user,
                          repositoriesFor: widget.repositoriesFor,
                          detectorFor: widget.detectorFor,
                          child: navigator ?? const SizedBox.shrink(),
                        ),
                ),
            home: BlocBuilder<AuthBloc, AuthState>(
              builder: (context, auth) => switch (auth.status) {
                AuthStatus.signedIn => ShellPage(key: ValueKey(auth.user?.id)),
                AuthStatus.resettingPassword => const NewPasswordPage(),
                AuthStatus.checking => const Scaffold(
                  body: Center(child: AppLogo(fontSize: 44)),
                ),
                AuthStatus.signedOut => BlocBuilder<IntroBloc, bool>(
                  builder: (context, showIntro) =>
                      showIntro ? const OnboardingPage() : const LogInPage(),
                ),
              },
            ),
          ),
        ),
      ),
    );
  }
}
