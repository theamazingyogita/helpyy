part of 'home_bloc.dart';

enum HomeStatus {
  loading,
  ready,
  loadFailed,
  deleteFailed,
  sensorUnavailable,

  /// The switch was turned on with no signal saved.
  noSignals,

  /// A Back Tap came in that no tap count signal uses.
  noBackTapSignal,
}

class HomeState extends Equatable {
  const HomeState({
    this.status = HomeStatus.loading,
    this.patterns = const [],
    this.isListening = false,
    this.incomingCall,
  });

  final HomeStatus status;
  final List<KnockPattern> patterns;
  final bool isListening;

  /// Set when a fake call should be shown, cleared once it ends.
  final KnockPattern? incomingCall;

  HomeState copyWith({
    HomeStatus? status,
    List<KnockPattern>? patterns,
    bool? isListening,
    ValueGetter<KnockPattern?>? incomingCall,
  }) {
    return HomeState(
      status: status ?? this.status,
      patterns: patterns ?? this.patterns,
      isListening: isListening ?? this.isListening,
      incomingCall: incomingCall != null ? incomingCall() : this.incomingCall,
    );
  }

  @override
  List<Object?> get props => [status, patterns, isListening, incomingCall];
}
