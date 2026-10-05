import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../storage/supabase_calls.dart';
import 'call_log_repository.dart';
import 'call_record.dart';

/// Call history in the call_records table, limited to the signed in user by
/// row level security.
class SupabaseCallLogRepository implements CallLogRepository {
  SupabaseCallLogRepository(this._client, {required String userId})
    : _userId = userId;

  // The Calls tab only ever shows recent calls.
  static const maxEntries = 50;

  final SupabaseClient _client;
  final String _userId;
  final _changes = StreamController<List<CallRecord>>.broadcast();

  @override
  Stream<List<CallRecord>> get changes => _changes.stream;

  /// Also throws [FormatException] when the server cannot be reached.
  @override
  Future<List<CallRecord>> load() => readRemote(() async {
    final rows = await _client
        .from('call_records')
        .select('caller_name, started_at, answered, talk_time_seconds')
        .order('started_at', ascending: false)
        .limit(maxEntries);
    return [for (final row in rows) _fromRow(row)];
  });

  @override
  Future<void> add(CallRecord record) async {
    await writeRemote(
      () => _client.from('call_records').insert({
        'caller_name': record.callerName,
        'started_at': record.startedAt.toUtc().toIso8601String(),
        'answered': record.answered,
        'talk_time_seconds': record.talkTime.inSeconds,
      }),
    );
    await _announce();
  }

  @override
  Future<void> clear() async {
    await writeRemote(
      () => _client.from('call_records').delete().eq('user_id', _userId),
    );
    _changes.add(const []);
  }

  // The write already succeeded, so a failed refresh only delays the Calls
  // tab until its next load.
  Future<void> _announce() async {
    try {
      _changes.add(await load());
    } on FormatException {
      return;
    }
  }

  CallRecord _fromRow(Map<String, dynamic> row) {
    if (row case {
      'caller_name': final String callerName,
      'started_at': final String startedAt,
      'answered': final bool answered,
      'talk_time_seconds': final int talkSeconds,
    }) {
      return CallRecord(
        callerName: callerName,
        // Stored in UTC, shown in the phone's time zone.
        startedAt: DateTime.parse(startedAt).toLocal(),
        answered: answered,
        talkTime: Duration(seconds: talkSeconds),
      );
    }
    throw FormatException('Not a call record', row);
  }
}
