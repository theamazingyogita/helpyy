import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:helpyy/knock/knock_pattern.dart';
import 'package:helpyy/signal/view/new_signal_page.dart';
import 'package:mocktail/mocktail.dart';

import '../helpers/mocks.dart';
import '../helpers/pump_app.dart';

void main() {
  late MockKnockDetector detector;
  late StreamController<List<int>> knocks;

  setUp(() {
    detector = MockKnockDetector();
    knocks = StreamController<List<int>>.broadcast();
    when(() => detector.sequences()).thenAnswer((_) => knocks.stream);
  });

  tearDown(() => knocks.close());

  Future<void> open(WidgetTester tester) async {
    await tester.scrollUntilVisible(
      find.text('Add a signal'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add a signal'));
    await tester.pumpAndSettle();
  }

  testWidgets('saves a tap count signal with a caller', (tester) async {
    final app = await tester.pumpHelpyy(detector: detector);
    await open(tester);

    await tester.tap(find.byTooltip('More taps'));
    await tester.pump();
    expect(find.text('4 taps'), findsOneWidget);
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();

    expect(find.text('Who should call you?'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'Maya');
    await tester.tap(find.text('Now'));
    await tester.pump();
    await tester.tap(find.text('Save signal'));
    await tester.pumpAndSettle();

    expect(find.byType(NewSignalPage), findsNothing);
    final saved = (await app.data!.patterns.load()).single;
    expect(saved.callerName, 'Maya');
    expect(saved.knockCount, 4);
    expect(saved.delaySeconds, 0);
  });

  testWidgets('records a custom rhythm', (tester) async {
    await tester.pumpHelpyy(detector: detector);
    await open(tester);

    await tester.tap(find.text('Custom rhythm'));
    await tester.pump();
    expect(find.textContaining('Knock your rhythm'), findsOneWidget);

    knocks.add([200, 600]);
    await tester.pumpAndSettle();

    expect(find.text('got it, 3 knocks'), findsOneWidget);
  });

  testWidgets('blocks a trigger that a saved signal already uses', (
    tester,
  ) async {
    await tester.pumpHelpyy(
      detector: detector,
      patterns: const [KnockPattern(id: '1', callerName: 'Mom', knockCount: 3)],
    );
    await open(tester);

    expect(find.textContaining('already uses this'), findsOneWidget);
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(find.text('Who should call you?'), findsNothing);
  });

  testWidgets('back on the caller step returns to the trigger step', (
    tester,
  ) async {
    await tester.pumpHelpyy(detector: detector);
    await open(tester);

    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();

    expect(find.text('What feels natural?'), findsOneWidget);
  });

  testWidgets(
    'on iPhone only double or triple taps are offered, no rhythm',
    (tester) async {
      await tester.pumpHelpyy(detector: detector);
      await open(tester);

      expect(find.text('Custom rhythm'), findsNothing);
      expect(find.textContaining('Back Tap'), findsOneWidget);
      await tester.tap(find.byTooltip('Fewer taps'));
      await tester.pump();
      expect(find.text('2 taps'), findsOneWidget);
      expect(
        tester
            .widget<IconButton>(find.widgetWithIcon(IconButton, Icons.remove))
            .onPressed,
        isNull,
      );
    },
    variant: TargetPlatformVariant.only(TargetPlatform.iOS),
  );
}
