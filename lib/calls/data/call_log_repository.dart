import 'call_record.dart';

abstract interface class CallLogRepository {
  Stream<List<CallRecord>> get changes;

  Future<List<CallRecord>> load();

  Future<void> add(CallRecord record);

  Future<void> clear();
}
