import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:helpyy/calls/data/call_record.dart';
import 'package:helpyy/calls/data/supabase_call_log_repository.dart';
import 'package:helpyy/knock/data/supabase_pattern_repository.dart';
import 'package:helpyy/knock/knock_pattern.dart';
import 'package:helpyy/ringtone/ringtone.dart';
import 'package:helpyy/settings/data/local_settings_repository.dart';
import 'package:helpyy/settings/data/supabase_settings_repository.dart';
import 'package:helpyy/settings/motion_sensitivity.dart';
import 'package:helpyy/storage/storage_write_exception.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'fake_supabase.dart';

void main() {
  group('SupabasePatternRepository', () {
    test('loads signals in their saved order', () async {
      final server = FakeSupabase(
        (_) => FakeSupabase.json([
          {
            'id': 'a',
            'caller_name': 'Mom',
            'knock_count': 3,
            'rhythm': [200, 300],
            'delay_seconds': 5,
          },
          {
            'id': 'b',
            'caller_name': 'Boss',
            'knock_count': 2,
            'rhythm': null,
            'delay_seconds': 0,
          },
        ]),
      );

      final patterns = await SupabasePatternRepository(server.client).load();

      expect(patterns, const [
        KnockPattern(
          id: 'a',
          callerName: 'Mom',
          knockCount: 3,
          rhythm: [200, 300],
          delaySeconds: 5,
        ),
        KnockPattern(id: 'b', callerName: 'Boss', knockCount: 2),
      ]);
      final url = server.requests.single.url;
      expect(url.path, '/rest/v1/knock_patterns');
      expect(url.queryParameters['order'], startsWith('position.asc'));
    });

    test('a bad row fails like unreadable local data', () {
      final server = FakeSupabase(
        (_) => FakeSupabase.json([
          {'id': 'a', 'caller_name': 'Mom'},
        ]),
      );

      expect(
        SupabasePatternRepository(server.client).load(),
        throwsFormatException,
      );
    });

    test('being offline fails the load with a FormatException', () {
      final server = FakeSupabase((_) => throw http.ClientException('down'));

      expect(
        SupabasePatternRepository(server.client).load(),
        throwsFormatException,
      );
    });

    test('save replaces every signal in one call', () async {
      final server = FakeSupabase((_) => FakeSupabase.json(null));

      await SupabasePatternRepository(
        server.client,
      ).save(const [KnockPattern(id: 'b', callerName: 'Boss', knockCount: 2)]);

      final request = server.requests.single;
      expect(request.method, 'POST');
      expect(request.url.path, '/rest/v1/rpc/replace_knock_patterns');
      expect(jsonDecode(request.body), {
        'patterns': [
          {
            'id': 'b',
            'callerName': 'Boss',
            'knockCount': 2,
            'rhythm': null,
            'delaySeconds': 0,
          },
        ],
      });
    });

    test('a refused write is a StorageWriteException', () {
      final server = FakeSupabase(
        (_) => FakeSupabase.json({
          'message': 'new row violates row-level security policy',
          'code': '42501',
        }, status: 403),
      );

      expect(
        SupabasePatternRepository(
          server.client,
        ).add(const KnockPattern(id: 'c', callerName: 'Dad', knockCount: 3)),
        throwsA(isA<StorageWriteException>()),
      );
    });
  });

  group('SupabaseCallLogRepository', () {
    test('loads newest first in the phone time zone', () async {
      final server = FakeSupabase(
        (_) => FakeSupabase.json([
          {
            'caller_name': 'Mom',
            'started_at': '2026-10-06T08:30:00+00:00',
            'answered': true,
            'talk_time_seconds': 65,
          },
        ]),
      );

      final records = await SupabaseCallLogRepository(
        server.client,
        userId: 'u1',
      ).load();

      expect(records.single.talkTime, const Duration(seconds: 65));
      expect(records.single.startedAt.isUtc, isFalse);
      expect(
        records.single.startedAt,
        DateTime.utc(2026, 10, 6, 8, 30).toLocal(),
      );
      final url = server.requests.single.url;
      expect(url.queryParameters['order'], startsWith('started_at.desc'));
      expect(url.queryParameters['limit'], '50');
    });

    test('adding a call stores it and announces the new log', () async {
      final record = CallRecord(
        callerName: 'Boss',
        startedAt: DateTime.utc(2026, 10, 6, 9),
        answered: false,
      );
      final server = FakeSupabase(
        (request) => request.method == 'GET'
            ? FakeSupabase.json([
                {
                  'caller_name': 'Boss',
                  'started_at': '2026-10-06T09:00:00+00:00',
                  'answered': false,
                  'talk_time_seconds': 0,
                },
              ])
            : FakeSupabase.json(null, status: 201),
      );
      final log = SupabaseCallLogRepository(server.client, userId: 'u1');
      final announced = log.changes.first;

      await log.add(record);

      expect((await announced).single.callerName, 'Boss');
      expect(jsonDecode(server.requests.first.body), {
        'caller_name': 'Boss',
        'started_at': '2026-10-06T09:00:00.000Z',
        'answered': false,
        'talk_time_seconds': 0,
      });
    });

    test('clear deletes only this user and announces an empty log', () async {
      final server = FakeSupabase((_) => FakeSupabase.json(null));
      final log = SupabaseCallLogRepository(server.client, userId: 'u1');
      final announced = log.changes.first;

      await log.clear();

      expect(await announced, isEmpty);
      final request = server.requests.single;
      expect(request.method, 'DELETE');
      expect(request.url.queryParameters['user_id'], 'eq.u1');
    });
  });

  group('SupabaseSettingsRepository', () {
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
    });

    SupabaseSettingsRepository build(FakeSupabase server) =>
        SupabaseSettingsRepository(
          server.client,
          LocalSettingsRepository(prefs, userId: 'u1'),
          userId: 'u1',
        );

    test('refresh brings the saved sensitivity to this phone', () async {
      final server = FakeSupabase(
        (_) => FakeSupabase.json({'motion_sensitivity': 'high'}),
      );
      final settings = build(server);
      expect(settings.sensitivity, MotionSensitivity.medium);

      await settings.refresh();

      expect(settings.sensitivity, MotionSensitivity.high);
    });

    test('saving keeps a device copy and upserts the row', () async {
      final server = FakeSupabase((_) => FakeSupabase.json(null, status: 201));
      final settings = build(server);

      await settings.saveSensitivity(MotionSensitivity.low);

      expect(settings.sensitivity, MotionSensitivity.low);
      final request = server.requests.single;
      expect(request.method, 'POST');
      expect(request.url.path, '/rest/v1/user_settings');
      expect(
        request.headers['Prefer'],
        contains('resolution=merge-duplicates'),
      );
      expect(
        jsonDecode(request.body),
        containsPair('motion_sensitivity', 'low'),
      );
    });

    test('a failed save still changes this phone, and says so', () async {
      final server = FakeSupabase((_) => throw http.ClientException('down'));
      final settings = build(server);

      await expectLater(
        settings.saveSensitivity(MotionSensitivity.low),
        throwsA(isA<StorageWriteException>()),
      );
      expect(settings.sensitivity, MotionSensitivity.low);
    });

    test('the ringtone stays on the phone', () async {
      final server = FakeSupabase((_) => FakeSupabase.json(null));
      final settings = build(server);

      await settings.saveRingtone(Ringtone.bundled.last);

      expect(settings.ringtone, Ringtone.bundled.last);
      expect(server.requests, isEmpty);
    });
  });
}
