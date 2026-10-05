import 'call_record.dart';

/// The signed in user's call history.
abstract interface class CallLogRepository {
  /// Emits the full log, newest first, after every change.
  Stream<List<CallRecord>> get changes;

  /// Newest first. Throws [FormatException] if stored data is unreadable.
  Future<List<CallRecord>> load();

  /// Throws [StorageWriteException].
  Future<void> add(CallRecord record);

  /// Throws [StorageWriteException].
  Future<void> clear();
}
