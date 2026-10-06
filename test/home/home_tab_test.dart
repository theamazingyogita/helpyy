import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:helpyy/call/view/call_page.dart';
import 'package:helpyy/knock/knock_pattern.dart';
import 'package:helpyy/signal/view/new_signal_page.dart';
import 'package:mocktail/mocktail.dart';

import '../helpers/mocks.dart';
import '../helpers/pump_app.dart';

void main() {
  const maya = KnockPattern(id: '1', callerName: 'Maya', knockCount: 3);

  late MockKnockDetector detector;
  late StreamController<List<int>> knocks;

  setUp(() {
    detector = MockKnockDetector();
    knocks = StreamController<List<int>>.broadcast();
    when(() => detector.sequences()).thenAnswer((_) => knocks.stream);
  });

  tearDown(() => knocks.close());

  testWidgets('without signals the switch stays off and says why', (
    tester,
  ) async {
    await tester.pumpHelpyy(detector: detector);
    expect(find.text('nothing yet'), findsOneWidget);

    for (var attempt = 0; attempt < 2; attempt++) {
      await tester.tap(find.byType(Switch));
      await tester.pump();
      expect(
        find.text('Add a signal first, then turn listening on.'),
        findsOneWidget,
      );
      expect(tester.widget<Switch>(find.byType(Switch)).value, isFalse);
      ScaffoldMessenger.of(
        tester.element(find.byType(Switch)),
      ).removeCurrentSnackBar();
      await tester.pumpAndSettle();
    }
    verifyNever(() => detector.sequences());
  });

  testWidgets('lists saved signals', (tester) async {
    await tester.pumpHelpyy(detector: detector, patterns: [maya]);

    expect(find.text('Maya'), findsOneWidget);
    expect(find.text('3 TAPS'), findsOneWidget);
    expect(find.text('3 taps → Maya'), findsOneWidget);
  });

  testWidgets('shows an error with retry when storage is corrupt', (
    tester,
  ) async {
    await tester.pumpHelpyy(detector: detector, rawPatterns: ['{oops']);

    expect(find.text('Your saved signals could not be read.'), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
  });

  testWidgets('tapping a saved signal on the phone opens the call', (
    tester,
  ) async {
    await tester.pumpHelpyy(detector: detector, patterns: [maya]);

    await tester.tap(find.byType(Switch));
    await tester.pump();
    knocks.add([200, 300]);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(CallPage), findsOneWidget);
    expect(find.text('Maya'), findsOneWidget);
  });

  testWidgets('swiping down on a test call declines it and logs it', (
    tester,
  ) async {
    final app = await tester.pumpHelpyy(detector: detector, patterns: [maya]);

    await tester.tap(find.text('Test call'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.drag(find.byIcon(Icons.call), const Offset(0, 150));
    await tester.pumpAndSettle();

    expect(find.byType(CallPage), findsNothing);
    expect((await app.data!.callLog.load()).single.answered, isFalse);
  });

  testWidgets('deleting removes the signal', (tester) async {
    final app = await tester.pumpHelpyy(detector: detector, patterns: [maya]);

    await tester.tap(find.byTooltip('Delete'));
    await tester.pump();

    expect(find.text('nothing yet'), findsOneWidget);
    expect(await app.data!.patterns.load(), isEmpty);
  });

  testWidgets('a missing sensor turns listening off with a message', (
    tester,
  ) async {
    when(
      () => detector.sequences(),
    ).thenAnswer((_) => Stream.error(UnsupportedError('no sensor')));
    await tester.pumpHelpyy(detector: detector, patterns: [maya]);

    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();

    expect(
      find.text('This device has no usable motion sensor.'),
      findsOneWidget,
    );
    expect(tester.widget<Switch>(find.byType(Switch)).value, isFalse);
  });

  testWidgets('the calls tab shows logged calls', (tester) async {
    await tester.pumpHelpyy(detector: detector, patterns: [maya]);
    await tester.tap(find.byTooltip('Calls'));
    await tester.pumpAndSettle();
    expect(find.text('no escapes yet, lucky you'), findsOneWidget);

    await tester.tap(find.byTooltip('Home'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Test call'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.drag(find.byIcon(Icons.call), const Offset(0, 150));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Calls'));
    await tester.pumpAndSettle();

    expect(find.text('Declined'), findsOneWidget);
  });

  testWidgets('add a signal opens the new signal flow', (tester) async {
    await tester.pumpHelpyy(detector: detector);

    await tester.tap(find.text('Add a signal'));
    await tester.pumpAndSettle();

    expect(find.byType(NewSignalPage), findsOneWidget);
  });
}
