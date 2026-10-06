import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:sensors_plus/sensors_plus.dart';

class KnockDetector {
  KnockDetector({
    Stream<UserAccelerometerEvent> Function()? events,
    double Function()? threshold,
    this.minKnockGap = const Duration(milliseconds: 120),
    this.sequenceEnd = const Duration(milliseconds: 1200),
  }) : threshold = threshold ?? (() => 2.5),
       _events =
           events ??
           (() => userAccelerometerEventStream(
             samplingPeriod: const Duration(milliseconds: 10),
           ));

  static const minKnocks = 3;

  final Stream<UserAccelerometerEvent> Function() _events;

  final double Function() threshold;

  final Duration minKnockGap;

  final Duration sequenceEnd;

  Stream<List<int>> sequences() {
    final knocks = <DateTime>[];
    UserAccelerometerEvent? previous;
    StreamSubscription<UserAccelerometerEvent>? readings;
    late final StreamController<List<int>> controller;

    void onReading(UserAccelerometerEvent event) {
      final time = event.timestamp;
      if (knocks.isNotEmpty && time.difference(knocks.last) > sequenceEnd) {
        _log('sequence of ${knocks.length}, gaps ${_gaps(knocks)}');
        if (knocks.length >= minKnocks) controller.add(_gaps(knocks));
        knocks.clear();
      }
      final last = previous ?? UserAccelerometerEvent(0, 0, 0, event.timestamp);
      previous = event;
      final isNewKnock =
          knocks.isEmpty || time.difference(knocks.last) >= minKnockGap;
      final jump = _Jump(event, last);
      if (_isKnock(jump) && isNewKnock) {
        knocks.add(time);
        _log('knock ${knocks.length} $jump needs z>${threshold()}');
      } else if (isNewKnock && jump.z > threshold() * 0.6) {
        _log('too soft $jump needs z>${threshold()}');
      }
    }

    controller = StreamController(
      onListen: () => readings = _events().listen(
        onReading,
        onError: controller.addError,
        onDone: controller.close,
      ),
      onCancel: () => readings?.cancel(),
    );
    return controller.stream;
  }

  bool _isKnock(_Jump jump) {
    final sideways = jump.x > jump.y ? jump.x : jump.y;
    return jump.z > threshold() && jump.z > sideways * 1.5;
  }

  void _log(String message) {
    if (kDebugMode) debugPrint('[KnockDetector] $message');
  }

  List<int> _gaps(List<DateTime> knocks) => [
    for (var i = 1; i < knocks.length; i++)
      knocks[i].difference(knocks[i - 1]).inMilliseconds,
  ];
}

class _Jump {
  _Jump(UserAccelerometerEvent now, UserAccelerometerEvent before)
    : x = (now.x - before.x).abs(),
      y = (now.y - before.y).abs(),
      z = (now.z - before.z).abs();

  final double x;
  final double y;
  final double z;

  @override
  String toString() =>
      'jump x=${x.toStringAsFixed(2)} y=${y.toStringAsFixed(2)} '
      'z=${z.toStringAsFixed(2)}';
}
