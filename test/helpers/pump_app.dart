import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:helpyy/app/tickle_app.dart';
import 'package:helpyy/auth/data/app_user.dart';
import 'package:helpyy/background/background_listening.dart';
import 'package:helpyy/auth/data/local_auth_repository.dart';
import 'package:helpyy/knock/back_tap_shortcuts.dart';
import 'package:helpyy/knock/knock_detector.dart';
import 'package:helpyy/knock/knock_pattern.dart';
import 'package:helpyy/onboarding/data/intro_repository.dart';
import 'package:helpyy/ringtone/ringtone_player.dart';
import 'package:helpyy/session/user_repositories.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'mocks.dart';

class PumpedApp {
  const PumpedApp(this.auth, this.user, this.data);

  final LocalAuthRepository auth;

  /// Null when the app was started signed out.
  final AppUser? user;
  final UserRepositories? data;
}

extension PumpApp on WidgetTester {
  /// Starts the real app on local storage. By default a user is signed in
  /// with [patterns] saved.
  Future<PumpedApp> pumpHelpyy({
    required KnockDetector detector,
    List<KnockPattern> patterns = const [],
    List<String>? rawPatterns,
    bool hasSeenIntro = true,
    bool signedIn = true,
    RingtonePlayer? ringtones,
    BackgroundListening? background,
    BackTapShortcuts? backTap,
  }) async {
    SharedPreferences.setMockInitialValues({'has_seen_intro': hasSeenIntro});
    final prefs = await SharedPreferences.getInstance();
    final auth = LocalAuthRepository(prefs);
    AppUser? user;
    UserRepositories? data;
    if (signedIn) {
      user = await auth.signUp(
        name: 'Alex',
        email: 'alex@example.com',
        password: 'password1',
      );
      data = UserRepositories.local(prefs, user);
      await prefs.setStringList(
        'user:${user.id}:knock_patterns',
        rawPatterns ?? [for (final p in patterns) jsonEncode(p.toJson())],
      );
    }
    await pumpWidget(
      TickleApp(
        auth: auth,
        intro: IntroRepository(prefs),
        repositoriesFor: (user) => UserRepositories.local(prefs, user),
        detectorFor: (_) => detector,
        ringtones: ringtones ?? silentRingtonePlayer(),
        background: background ?? quietBackgroundListening(),
        backTap: backTap ?? _noBackTaps(),
      ),
    );
    await pumpAndSettle();
    return PumpedApp(auth, user, data);
  }
}

MockBackTapShortcuts _noBackTaps() {
  final backTap = MockBackTapShortcuts();
  when(backTap.taps).thenAnswer((_) => const Stream.empty());
  return backTap;
}
