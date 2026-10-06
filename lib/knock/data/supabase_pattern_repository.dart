import 'package:supabase_flutter/supabase_flutter.dart';

import '../../storage/supabase_calls.dart';
import '../knock_pattern.dart';
import 'pattern_repository.dart';

class SupabasePatternRepository implements PatternRepository {
  SupabasePatternRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<List<KnockPattern>> load() => readRemote(() async {
    final rows = await _client
        .from('knock_patterns')
        .select('id, caller_name, knock_count, rhythm, delay_seconds')
        .order('position', ascending: true);
    return [for (final row in rows) _fromRow(row)];
  });

  @override
  Future<void> save(List<KnockPattern> patterns) => writeRemote(
    () => _client.rpc(
      'replace_knock_patterns',
      params: {
        'patterns': [for (final p in patterns) p.toJson()],
      },
    ),
  );

  @override
  Future<void> add(KnockPattern pattern) => writeRemote(
    () => _client.from('knock_patterns').insert({
      'id': pattern.id,
      'caller_name': pattern.callerName,
      'knock_count': pattern.knockCount,
      'rhythm': pattern.rhythm,
      'delay_seconds': pattern.delaySeconds,
    }),
  );

  KnockPattern _fromRow(Map<String, dynamic> row) => KnockPattern.fromJson({
    'id': row['id'],
    'callerName': row['caller_name'],
    'knockCount': row['knock_count'],
    'rhythm': row['rhythm'],
    'delaySeconds': row['delay_seconds'],
  });
}
