import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../auth/data/app_user.dart';
import '../calls/data/call_log_repository.dart';
import '../calls/data/local_call_log_repository.dart';
import '../calls/data/supabase_call_log_repository.dart';
import '../knock/data/local_pattern_repository.dart';
import '../knock/data/pattern_repository.dart';
import '../knock/data/supabase_pattern_repository.dart';
import '../settings/data/local_settings_repository.dart';
import '../settings/data/settings_repository.dart';
import '../settings/data/supabase_settings_repository.dart';

/// Everything that belongs to one signed in user.
///
/// The app uses [UserRepositories.supabase]. [UserRepositories.local] keeps
/// it all on the device, which the tests use.
class UserRepositories {
  const UserRepositories({
    required this.patterns,
    required this.callLog,
    required this.settings,
  });

  factory UserRepositories.local(SharedPreferences prefs, AppUser user) {
    return UserRepositories(
      patterns: LocalPatternRepository(prefs, userId: user.id),
      callLog: LocalCallLogRepository(prefs, userId: user.id),
      settings: LocalSettingsRepository(prefs, userId: user.id),
    );
  }

  factory UserRepositories.supabase(
    SupabaseClient client,
    SharedPreferences prefs,
    AppUser user,
  ) {
    final settings = SupabaseSettingsRepository(
      client,
      LocalSettingsRepository(prefs, userId: user.id),
      userId: user.id,
    );
    // Offline the device copy is used, so a failed refresh needs no
    // handling here.
    settings.refresh().ignore();
    return UserRepositories(
      patterns: SupabasePatternRepository(client),
      callLog: SupabaseCallLogRepository(client, userId: user.id),
      settings: settings,
    );
  }

  final PatternRepository patterns;
  final CallLogRepository callLog;
  final SettingsRepository settings;
}
