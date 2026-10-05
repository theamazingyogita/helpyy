import 'package:equatable/equatable.dart';

class CallRecord extends Equatable {
  const CallRecord({
    required this.callerName,
    required this.startedAt,
    required this.answered,
    this.talkTime = Duration.zero,
  });

  factory CallRecord.fromJson(Object? json) {
    if (json case {
      'callerName': final String callerName,
      'startedAt': final String startedAt,
      'answered': final bool answered,
      'talkSeconds': final int talkSeconds,
    }) {
      return CallRecord(
        callerName: callerName,
        startedAt: DateTime.parse(startedAt),
        answered: answered,
        talkTime: Duration(seconds: talkSeconds),
      );
    }
    throw FormatException('Not a call record', json);
  }

  final String callerName;
  final DateTime startedAt;
  final bool answered;
  final Duration talkTime;

  Map<String, Object> toJson() => {
    'callerName': callerName,
    'startedAt': startedAt.toIso8601String(),
    'answered': answered,
    'talkSeconds': talkTime.inSeconds,
  };

  @override
  List<Object> get props => [callerName, startedAt, answered, talkTime];
}
