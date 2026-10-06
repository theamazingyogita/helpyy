import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:helpyy/knock/knock_detector.dart';
import 'package:sensors_plus/sensors_plus.dart';

final _start = DateTime(2026);

UserAccelerometerEvent _reading(int ms, {double x = 0, double z = 0}) =>
    UserAccelerometerEvent(x, 0, z, _start.add(Duration(milliseconds: ms)));

List<UserAccelerometerEvent> _session(List<int> knocksAt, {int until = 4000}) {
  return [
    for (var ms = 0; ms <= until; ms += 20)
      _reading(ms, z: knocksAt.contains(ms) ? 6 : 0.1),
  ];
}

Future<List<List<int>>> _detect(List<UserAccelerometerEvent> events) =>
    KnockDetector(
      events: () => Stream.fromIterable(events),
    ).sequences().toList();

void main() {
  test('emits the gaps between knocks once the phone goes still', () async {
    final sequences = await _detect(_session([100, 400, 1000]));

    expect(sequences, [
      [300, 600],
    ]);
  });

  test('ignores fewer than three knocks', () async {
    final sequences = await _detect(_session([100, 400]));

    expect(sequences, isEmpty);
  });

  test('counts readings right after a knock as the same knock', () async {
    final sequences = await _detect(_session([100, 120, 140, 400, 700]));

    expect(sequences, [
      [300, 300],
    ]);
  });

  test('splits knocks separated by a long pause into two sequences', () async {
    final sequences = await _detect(
      _session([0, 200, 400, 2000, 2200, 2400], until: 4000),
    );

    expect(sequences, [
      [200, 200],
      [200, 200],
    ]);
  });

  test('ignores shakes that are mostly sideways', () async {
    final events = [
      for (var ms = 0; ms <= 3000; ms += 20)
        _reading(ms, x: ms % 300 == 0 ? 8 : 0, z: ms % 300 == 0 ? 4 : 0),
    ];

    expect(await _detect(events), isEmpty);
  });

  test('reads the threshold on every sample', () async {
    var threshold = 10.0;
    final events = _session([100, 400, 700]);
    final detector = KnockDetector(
      events: () => Stream.fromIterable(events),
      threshold: () => threshold,
    );
    threshold = 2;

    expect(await detector.sequences().toList(), [
      [300, 300],
    ]);
  });

  test('ignores movement that builds up smoothly, however strong', () async {
    final events = [
      for (var ms = 0; ms <= 4000; ms += 20)
        _reading(ms, z: 8 * (1 - ((ms % 1000) - 500).abs() / 500)),
    ];

    expect(await _detect(events), isEmpty);
  });

  test('stops reading the sensor once nobody listens', () async {
    var isListening = false;
    final sensor = StreamController<UserAccelerometerEvent>(
      onListen: () => isListening = true,
      onCancel: () => isListening = false,
    );
    final subscription = KnockDetector(
      events: () => sensor.stream,
    ).sequences().listen((_) {});
    expect(isListening, isTrue);

    await subscription.cancel();

    expect(isListening, isFalse);
  });

  test('passes sensor errors through', () {
    final detector = KnockDetector(
      events: () => Stream.error(UnsupportedError('no sensor')),
    );

    expect(detector.sequences(), emitsError(isUnsupportedError));
  });
}
