part of 'calls_bloc.dart';

enum CallsStatus { loading, ready, failed }

class CallsState extends Equatable {
  const CallsState({
    this.status = CallsStatus.loading,
    this.records = const [],
  });

  final CallsStatus status;
  final List<CallRecord> records;

  @override
  List<Object> get props => [status, records];
}
