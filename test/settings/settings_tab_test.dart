import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:helpyy/ringtone/ringtone.dart';
import 'package:mocktail/mocktail.dart';

import '../helpers/mocks.dart';
import '../helpers/pump_app.dart';

void main() {
  late MockRingtonePlayer player;

  setUp(() => player = silentRingtonePlayer());

  /// Opens settings scrolled down to [control].
  Future<void> openSettings(WidgetTester tester, String control) async {
    await tester.pumpHelpyy(detector: MockKnockDetector(), ringtones: player);
    final isApple = defaultTargetPlatform == TargetPlatform.iOS;
    await tester.tap(
      isApple ? find.byIcon(CupertinoIcons.gear) : find.byTooltip('Settings'),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text(control),
      200,
      // Tabs stay alive in an IndexedStack, and settings is the last one.
      scrollable: find.byType(Scrollable).last,
    );
  }

  testWidgets(
    'on iPhone picks one of the bundled tones',
    (tester) async {
      await openSettings(tester, 'Chime');

      expect(find.text('RINGTONE'), findsOneWidget);
      expect(find.text('Phone default'), findsNothing);
      await tester.tap(find.text('Chime'));
      await tester.pump();

      verify(() => player.play(Ringtone.bundled.last, loop: false)).called(1);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.iOS),
  );

  testWidgets(
    'on Android opens the system picker and shows the choice',
    (tester) async {
      when(() => player.pick(any())).thenAnswer(
        (_) async =>
            const Ringtone(id: 'content://media/7', title: 'Beep Once'),
      );
      await openSettings(tester, 'Phone default');

      await tester.tap(find.text('Phone default'));
      await tester.pump();

      expect(find.text('Beep Once'), findsOneWidget);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.android),
  );

  testWidgets('licenses opens the licence page', (tester) async {
    await openSettings(tester, 'Licenses');

    await tester.tap(find.text('Licenses'));
    await tester.pumpAndSettle();

    expect(find.byType(LicensePage), findsOneWidget);
  });

  testWidgets(
    'on iPhone explains how to set up Back Tap',
    (tester) async {
      await openSettings(tester, 'BACK TAP');

      expect(find.textContaining('Shortcuts app'), findsOneWidget);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.iOS),
  );

  testWidgets(
    'on Android there is no Back Tap guide',
    (tester) async {
      await openSettings(tester, 'Licenses');

      expect(find.text('BACK TAP'), findsNothing);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.android),
  );
}
