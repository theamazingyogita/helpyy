import 'package:flutter_test/flutter_test.dart';
import 'package:helpyy/calls/data/local_call_log_repository.dart';
import 'package:helpyy/calls/data/call_record.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  CallRecord record(int minute) => CallRecord(
    callerName: 'Maya',
    startedAt: DateTime(2026, 10, 6, 14, minute),
    answered: minute.isEven,
    talkTime: Duration(seconds: minute),
  );

  Future<LocalCallLogRepository> repository([
    Map<String, Object>? values,
  ]) async {
    SharedPreferences.setMockInitialValues(values ?? {});
    return LocalCallLogRepository(
      await SharedPreferences.getInstance(),
      userId: 'u1',
    );
  }

  test('adds newest first and announces the change', () async {
    final log = await repository();
    final changes = <List<CallRecord>>[];
    log.changes.listen(changes.add);

    await log.add(record(1));
    await log.add(record(2));
    await Future<void>.delayed(Duration.zero);

    expect(await log.load(), [record(2), record(1)]);
    expect(changes.last, [record(2), record(1)]);
  });

  test('keeps only the most recent entries', () async {
    final log = await repository();
    for (var i = 0; i < LocalCallLogRepository.maxEntries + 5; i++) {
      await log.add(record(i % 60));
    }
    expect(await log.load(), hasLength(LocalCallLogRepository.maxEntries));
  });

  test('clear empties the log', () async {
    final log = await repository();
    await log.add(record(1));
    await log.clear();
    expect(await log.load(), isEmpty);
  });

  test('throws FormatException for corrupt data', () async {
    final log = await repository({
      'user:u1:call_log': ['nope'],
    });
    expect(log.load(), throwsFormatException);
  });
}
