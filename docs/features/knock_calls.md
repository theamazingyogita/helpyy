# Knock calls

## What it does
The user saves signals. A signal is either a number of taps (3 to 8) or a
custom knock rhythm on the back of the phone, plus a caller name and a delay
(now, 5s, 10s). While listening is on and helpyy is open, tapping a saved
signal shows a countdown (if there is a delay) and then a fake incoming call.
Every call that rang is logged on the Calls tab. Each saved signal has a
Test call button that rings its call straight away.

## Flow
First launch:
1. IntroBloc reads has_seen_intro. If false, OnboardingPage shows 3 slides.
2. Get started or Skip adds IntroFinished and opens sign up.

New signal (NewSignalPage, two steps on one NewSignalBloc):
1. Trigger step. Tap count is picked with a stepper, custom rhythm is recorded
   from KnockDetector. If any saved signal overlaps (KnockPattern.overlaps),
   Next is disabled.
2. Caller step. Name and delay, then Save signal writes through
   PatternRepository.add and the page pops.
3. HomeBloc reloads and resumes listening if it was on.

Calling:
1. HomeBloc listens to KnockDetector.sequences() while the switch is on.
2. KnockDetector reads the gravity free accelerometer at 100Hz. A reading is
   a knock when z jumps from the previous reading by more than the
   sensitivity threshold, and that jump beats the x and y jumps by 1.5x.
   Using the jump rather than the raw value tells sharp taps from smooth
   handling. The sensor is only read while someone listens.
   After 1.2s without knocks the gaps are emitted (3 or more knocks).
3. The first signal whose matches() accepts the gaps sets incomingCall and
   HomeTab pushes CallPage.
4. CallBloc counts down, then rings: RingtonePlayer plays the user's tone on
   a loop and the phone vibrates every 2s. If the tone cannot play the call
   still vibrates. Answer starts a talk timer. Decline or End writes a CallRecord to CallLogRepository and
   pops. Cancel during the countdown pops without logging.
5. CallsBloc listens to CallLogRepository.changes, so the Calls tab updates.

Outside the app:
- Android: while listening is on, HomeBloc starts ListeningService through
  BackgroundListening. HelpyyApplication owns the Flutter engine, so Dart and
  the knock detector keep running after the user leaves the app, and a
  partial wake lock keeps readings coming with the screen off. When a call
  rings and helpyy is not in front, BackgroundChannel posts a full screen
  call notification that opens MainActivity over the lock screen.
- iOS: apps cannot read the sensor in the background, so signals are limited
  to a double or triple tap (NewSignalBloc.isBackTapOnly, no rhythms) and
  ring through iPhone Back Tap. Two App Intents in AppDelegate.swift, "Double
  tap escape call" and "Triple tap escape call", open helpyy and pass the
  count over BackTapShortcuts. HomeBloc rings the tap count signal with that
  count, whether listening is on or not. Settings shows the setup steps.

Ringing controls follow the platform. iOS: Decline and a pulsing Answer
button. Android: SwipeToAnswer, drag up to answer or down to decline, with a
hop and wiggle while idle. Both stay still when the system asks for reduced
motion.

Settings: motion sensitivity Low/Medium/High maps to jumps of 4, 2.5 and
1.6 m/s².
KnockDetector reads it on every sample so a change applies immediately.

Ringtone (lib/ringtone/, native code in MainActivity.kt, RingtoneChannel.kt
and AppDelegate.swift, channel `helpyy/ringtone`):
- Android plays the phone's default ringtone until the user picks another
  in the system ringtone picker. A tone that has since gone falls back to the
  default.
- iOS gives apps no access to the phone's ringtones, so the user picks one of
  three bundled tones (assets/ringtones/), which previews once. The ring
  switch silences it like a real call.
- The choice is saved per user in SettingsRepository.

Debug logging: AppBlocObserver prints every bloc event and state change, and
KnockDetector prints each knock, each finished sequence and any movement
that was too soft to count, with its x, y and z.

## Files
- lib/knock/ detector, pattern model, pattern repository, Back Tap channel
- lib/background/ Android background listening channel
- android/.../HelpyyApplication.kt, ListeningService.kt, BackgroundChannel.kt
- lib/signal/ new signal flow
- lib/home/ dashboard tab
- lib/call/ countdown and call screen
- lib/calls/ call history data and tab
- lib/settings/ sensitivity, ringtone and privacy note
- lib/ringtone/ ringtone model and player
- lib/onboarding/ intro screens and IntroBloc
- lib/shell/shell_page.dart bottom navigation
- lib/widgets/ shared design pieces (TopBar, InkButton, Eyebrow, ...)
- lib/app/ theme, colours, app root

## States
HomeStatus: loading, ready, loadFailed, deleteFailed, sensorUnavailable
NewSignalState: step, record status, clashes, save status
CallPhase: countdown, ringing, answered, ended
CallsStatus: loading, ready, failed

## Edge cases
- No signals: turning listening on is refused with a snackbar, every time.
- Last signal deleted while listening: listening turns off.
- Corrupt stored data: home shows an error with Try again.
- No accelerometer: listening turns off with a snackbar, recorder says so.
- Knocks during a call or while adding a signal are ignored.
- History write fails: the call still ends and home shows a snackbar.

## Limits
- iOS: only double and triple tap signals work outside the app, and only
  after the user sets up Back Tap. Older iOS signals with rhythms or other
  counts still work while helpyy is open.
- Android: background listening ends if the user force stops helpyy or the
  phone maker's battery saver kills it. Android 14+ may only allow the call
  as a heads up notification unless full screen notifications are allowed.
  The phone does not vibrate for a background call beyond the notification.
- The call is a helpyy screen, not the system call UI.
- iOS cannot ring with the user's own ringtone, only bundled ones.
- Character art is not in yet. IllustrationSlot only shows the handwritten
  caption until it is.
