import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/call_log_repository.dart';
import '../data/call_record.dart';

part 'calls_event.dart';
part 'calls_state.dart';

class CallsBloc extends Bloc<CallsEvent, CallsState> {
  CallsBloc(this._repository) : super(const CallsState()) {
    on<CallsStarted>(_onStarted);
  }

  final CallLogRepository _repository;

  Future<void> _onStarted(CallsStarted event, Emitter<CallsState> emit) async {
    try {
      final records = await _repository.load();
      emit(CallsState(status: CallsStatus.ready, records: records));
    } on FormatException {
      emit(const CallsState(status: CallsStatus.failed));
    }
    await emit.forEach(
      _repository.changes,
      onData: (records) =>
          CallsState(status: CallsStatus.ready, records: records),
    );
  }
}
