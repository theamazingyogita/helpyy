import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:sensors_plus/sensors_plus.dart';

/// Turns raw accelerometer readings into knock sequences.
///
/// A sequence is the gaps between knocks in milliseconds. It is emitted once
/// the phone has been still for [sequenceEnd] after the last knock.
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
             // A tap lasts about 10ms. At 50Hz most of its peak fell between
             // samples on an iPhone, so read at 100Hz, the most iOS offers.
             samplingPeriod: const Duration(milliseconds: 10),
           ));

  // Putting the phone down or bumping it can easily make one or two knocks.
  static const minKnocks = 3;

  final Stream<UserAccelerometerEvent> Function() _events;

  /// How much the gravity-free acceleration along z, in m/s², must change
  /// from one reading to the next to count as a knock. Read on every sample
  /// so a sensitivity change applies at once.
  final double Function() threshold;

  /// One knock rings through several samples, so readings closer than this
  /// to the previous knock belong to it.
  final Duration minKnockGap;

  final Duration sequenceEnd;

  /// Listens to the sensor only while the returned stream has a listener.
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
      // The first reading is measured from rest.
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

  // A tap on the back moves the phone along z. Walking or swinging the phone
  // moves it along x and y too, so z has to dominate.
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

/// How far each axis moved since the previous reading.
///
/// A tap is a sharp spike that often swings back the other way on the next
/// sample, while holding or walking with the phone changes it smoothly. So
/// the change between samples separates taps from handling much better than
/// the raw acceleration does.
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
