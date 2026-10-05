part of 'new_signal_bloc.dart';

enum SignalStep { trigger, caller }

enum RecordStatus { idle, listening, captured, sensorUnavailable }

enum SaveStatus { idle, saving, saved, failed }

class NewSignalState extends Equatable {
  const NewSignalState({
    this.step = SignalStep.trigger,
    this.useRhythm = false,
    this.tapCount = 3,
    this.rhythm = const [],
    this.recordStatus = RecordStatus.idle,
    this.clashes = false,
    this.delaySeconds = 5,
    this.saveStatus = SaveStatus.idle,
  });

  final SignalStep step;
  final bool useRhythm;
  final int tapCount;
  final List<int> rhythm;
  final RecordStatus recordStatus;

  /// The chosen trigger would also set off a signal that is already saved.
  final bool clashes;

  final int delaySeconds;
  final SaveStatus saveStatus;

  bool get canContinue =>
      !clashes && (!useRhythm || recordStatus == RecordStatus.captured);

  NewSignalState copyWith({
    SignalStep? step,
    bool? useRhythm,
    int? tapCount,
    List<int>? rhythm,
    RecordStatus? recordStatus,
    bool? clashes,
    int? delaySeconds,
    SaveStatus? saveStatus,
  }) {
    return NewSignalState(
      step: step ?? this.step,
      useRhythm: useRhythm ?? this.useRhythm,
      tapCount: tapCount ?? this.tapCount,
      rhythm: rhythm ?? this.rhythm,
      recordStatus: recordStatus ?? this.recordStatus,
      clashes: clashes ?? this.clashes,
      delaySeconds: delaySeconds ?? this.delaySeconds,
      saveStatus: saveStatus ?? this.saveStatus,
    );
  }

  @override
  List<Object> get props => [
    step,
    useRhythm,
    tapCount,
    rhythm,
    recordStatus,
    clashes,
    delaySeconds,
    saveStatus,
  ];
}
