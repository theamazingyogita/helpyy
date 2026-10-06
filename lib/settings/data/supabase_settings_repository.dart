import 'package:supabase_flutter/supabase_flutter.dart';

import '../../ringtone/ringtone.dart';
import '../../storage/supabase_calls.dart';
import '../motion_sensitivity.dart';
import 'local_settings_repository.dart';
import 'settings_repository.dart';

class SupabaseSettingsRepository implements SettingsRepository {
  SupabaseSettingsRepository(
    this._client,
    this._cache, {
    required String userId,
  }) : _userId = userId;

  final SupabaseClient _client;
  final LocalSettingsRepository _cache;
  final String _userId;

  @override
  MotionSensitivity get sensitivity => _cache.sensitivity;

  @override
  Ringtone? get ringtone => _cache.ringtone;

  @override
  Future<void> saveSensitivity(MotionSensitivity value) async {
    await _cache.saveSensitivity(value);
    await _upsert({'motion_sensitivity': value.name});
  }

  @override
  Future<void> saveRingtone(Ringtone value) => _cache.saveRingtone(value);

  Future<void> refresh() async {
    final row = await readRemote(
      () => _client
          .from('user_settings')
          .select('motion_sensitivity')
          .maybeSingle(),
    );
    if (row == null) return;
    for (final value in MotionSensitivity.values) {
      if (value.name == row['motion_sensitivity']) {
        await _cache.saveSensitivity(value);
      }
    }
  }

  Future<void> _upsert(Map<String, Object?> values) => writeRemote(
    () => _client.from('user_settings').upsert({
      'user_id': _userId,
      ...values,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }),
  );
}
