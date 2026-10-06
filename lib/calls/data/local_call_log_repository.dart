import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../storage/storage_write_exception.dart';
import 'call_log_repository.dart';
import 'call_record.dart';

class LocalCallLogRepository implements CallLogRepository {
  LocalCallLogRepository(this._prefs, {required String userId})
    : _key = 'user:$userId:call_log';

  static const maxEntries = 50;

  final SharedPreferences _prefs;
  final String _key;
  final _changes = StreamController<List<CallRecord>>.broadcast();

  @override
  Stream<List<CallRecord>> get changes => _changes.stream;

  @override
  Future<List<CallRecord>> load() async => [
    for (final raw in _prefs.getStringList(_key) ?? const <String>[])
      CallRecord.fromJson(jsonDecode(raw)),
  ];

  @override
  Future<void> add(CallRecord record) async {
    final records = [record, ...await load()].take(maxEntries).toList();
    await _write(records);
  }

  @override
  Future<void> clear() => _write(const []);

  Future<void> _write(List<CallRecord> records) async {
    final saved = await _prefs.setStringList(_key, [
      for (final record in records) jsonEncode(record.toJson()),
    ]);
    if (!saved) throw const StorageWriteException();
    _changes.add(records);
  }

  Future<void> dispose() => _changes.close();
}
