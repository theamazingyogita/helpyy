import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:helpyy/auth/log_in/view/log_in_page.dart';
import 'package:helpyy/auth/widgets/auth_error_banner.dart';
import 'package:helpyy/avatar/cartoon_avatar.dart';
import 'package:helpyy/knock/knock_pattern.dart';
import 'package:helpyy/profile/view/profile_button.dart';
import 'package:helpyy/profile/view/profile_page.dart';
import 'package:helpyy/shell/shell_page.dart';
import 'package:mocktail/mocktail.dart';

import '../helpers/mocks.dart';
import '../helpers/pump_app.dart';

void main() {
  late MockKnockDetector detector;

  setUp(() {
    detector = MockKnockDetector();
    when(() => detector.sequences()).thenAnswer((_) => const Stream.empty());
  });

  Future<void> fill(WidgetTester tester, String label, String text) =>
      tester.enterText(
        find.descendant(
          of: find
              .ancestor(
                of: find.text(label.toUpperCase()),
                matching: find.byType(Column),
              )
              .first,
          matching: find.byType(TextField),
        ),
        text,
      );

  testWidgets('signing up lands on home', (tester) async {
    await tester.pumpHelpyy(detector: detector, signedIn: false);
    await tester.tap(find.text('Sign up'));
    await tester.pumpAndSettle();

    await fill(tester, 'Your name', 'Sam');
    await fill(tester, 'Email address', 'sam@example.com');
    await fill(tester, 'Password', 'password1');
    await tester.tap(find.text('Join helpyy.'));
    await tester.pumpAndSettle();

    expect(find.byType(ShellPage), findsOneWidget);
  });

  testWidgets('sign up shows field errors', (tester) async {
    await tester.pumpHelpyy(detector: detector, signedIn: false);
    await tester.tap(find.text('Sign up'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Join helpyy.'));
    await tester.pump();

    expect(find.text('Required'), findsNWidgets(3));
  });

  testWidgets('wrong password keeps you on log in', (tester) async {
    final app = await tester.pumpHelpyy(detector: detector);
    await app.auth.logOut();
    await tester.pumpAndSettle();
    expect(find.byType(LogInPage), findsOneWidget);

    await fill(tester, 'Email address', 'alex@example.com');
    await fill(tester, 'Password', 'not-it');
    await tester.tap(find.text('Step inside'));
    await tester.pumpAndSettle();

    expect(
      find.text('That password is not right. Check it and try again.'),
      findsOneWidget,
    );

    await fill(tester, 'Password', 'not-it-either');
    await tester.pump();
    expect(find.textContaining('password is not right'), findsNothing);
    expect(find.byType(ShellPage), findsNothing);
  });

  testWidgets('no account offers sign up', (tester) async {
    await tester.pumpHelpyy(detector: detector, signedIn: false);

    await fill(tester, 'Email address', 'nobody@example.com');
    await fill(tester, 'Password', 'password1');
    await tester.tap(find.text('Step inside'));
    await tester.pumpAndSettle();

    expect(find.text('There is no account with this email.'), findsOneWidget);
    await tester.tap(
      find.descendant(
        of: find.byType(AuthErrorBanner),
        matching: find.text('Sign up'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text("Let's get you started."), findsOneWidget);
  });

  testWidgets('picking a character makes it the profile picture', (
    tester,
  ) async {
    final app = await tester.pumpHelpyy(detector: detector);

    await tester.tap(find.byType(ProfileButton));
    await tester.pumpAndSettle();
    expect(find.byType(SvgPicture), findsNothing);
    await tester.tap(find.byTooltip('Change photo'));
    await tester.pumpAndSettle();

    await tester.tap(find.bySemanticsLabel('Character Felix'));
    await tester.pumpAndSettle();

    expect(find.text('Pick a character'), findsNothing);
    expect(find.byType(SvgPicture), findsWidgets);
    final saved = await app.auth.currentUser();
    expect(CartoonAvatar.seedOf(saved?.photoUrl), 'Felix');
  });

  testWidgets('profile shows save only after the name changes', (tester) async {
    await tester.pumpHelpyy(detector: detector);

    await tester.tap(find.byType(ProfileButton));
    await tester.pumpAndSettle();
    expect(find.byType(ProfilePage), findsOneWidget);
    expect(find.text('Save changes'), findsNothing);
    expect(find.text('Log out'), findsNothing);
    expect(find.byTooltip('Change photo'), findsOneWidget);

    await fill(tester, 'Your name', 'Alexa');
    await tester.pump();
    await tester.ensureVisible(find.text('Save changes'));
    await tester.tap(find.text('Save changes'));
    await tester.pumpAndSettle();

    expect(find.text('Saved.'), findsOneWidget);
    expect(find.text('Save changes'), findsNothing);
  });

  testWidgets('log out lives in settings', (tester) async {
    await tester.pumpHelpyy(detector: detector);

    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Log out'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Log out'));
    await tester.pumpAndSettle();

    expect(find.byType(LogInPage), findsOneWidget);
  });

  testWidgets('each account sees only its own signals', (tester) async {
    final app = await tester.pumpHelpyy(
      detector: detector,
      patterns: const [
        KnockPattern(id: '1', callerName: 'Maya', knockCount: 3),
      ],
    );
    expect(find.text('Maya'), findsOneWidget);

    await app.auth.logOut();
    await app.auth.signUp(
      name: 'Sam',
      email: 'sam@example.com',
      password: 'password1',
    );
    await tester.pumpAndSettle();

    expect(find.text('Maya'), findsNothing);
    expect(find.text('nothing yet'), findsOneWidget);
  });
}
