# Accounts and data

## What it does
Sign up, log in, profile (rename, log out). Each account has its own
signals, call history and settings. Everything is stored on the device
for now, behind interfaces so a backend can replace it later.

## Flow
1. AuthBloc handles AuthStarted: it restores the saved session from AuthRepository.
2. Signed out: the intro shows once (IntroBloc), then LogInPage. Get started
   and Skip both end on LogInPage, and its link opens SignUpPage.
3. SignUpBloc and LogInBloc handle the Submitted event, validate fields, then call AuthRepository. On
   success the repository emits the user on `changes` and AuthBloc moves to
   signedIn.
4. TickleApp wraps the navigator in SignedInScope for that user, so every
   screen, pushed ones included, gets that user's repositories.
5. On log out or account change, pushed routes are cleared and ShellPage is
   rebuilt for the new user.

## Forgot password
Log in has a "Forgot password?" link to ForgotPasswordPage, which sends a
reset email through AuthRepository.sendPasswordReset. It always says the
email is on its way, so nobody can test which addresses have accounts.

The link opens helpyy (com.helpyy.helpyy://login-callback). Supabase marks
the session as a password recovery, SupabaseAuthRepository sets
isResettingPassword and emits on passwordResets, and AuthBloc moves to
AuthStatus.resettingPassword, which shows NewPasswordPage in place of
everything else. Saving checks validateNewPassword, calls setNewPassword and
signs in. Cancel logs out of the recovery session.

## Emails
supabase/templates holds the branded confirmation and reset emails, sent
from theweirdyoyo@gmail.com through Gmail SMTP (supabase/config.toml). The
Gmail app password is passed at push time, never stored. The Site URL and
the allowed redirect are both the app link, so every email link opens the
app.

## Input rules
lib/auth/validation.dart holds the rules and the matching input formatters
for every auth field. Names: 2 to 40 characters, letters in any script with
spaces, apostrophes, hyphens and dots, no leading or doubled spaces. Email:
no spaces, at most 254 characters, a practical format check. New passwords:
8 to 72 characters (bcrypt's limit) with a letter and a number. Log in only
checks a password was typed, so older accounts still get in.

## Profile picture
The camera badge on the profile opens a sheet: a row of ready made
characters, then take a photo, choose from library, and remove. Characters
come from DiceBear's Adventurer style (lib/avatar/cartoon_avatar.dart,
packages dicebear_core, dicebear_styles, drawn with flutter_svg). A picked
character is stored as the user's photoUrl, `avatar:<seed>`, through
AuthRepository.useAvatar, and InitialAvatar draws it anywhere the user's
picture shows. Adventurer is CC BY 4.0. Its credit is in the dicebear_styles
licence, which Settings > Licenses shows on Flutter's licence page.

## Backend: Supabase
main.dart initialises Supabase (lib/app/supabase_config.dart, publishable
key only) and builds the app on the Supabase repositories:

- SupabaseAuthRepository: Supabase Auth for accounts. Name and picture live
  in `profiles`, created by a trigger on sign up from the name in user
  metadata. Photos upload to the public `avatars` bucket under the user's id.
  With email confirmation on, sign up shows "check your email" and the user
  logs in after tapping the link.
- SupabasePatternRepository: `knock_patterns`. save() calls the
  `replace_knock_patterns` function so the whole list changes in one
  transaction.
- SupabaseCallLogRepository: `call_records`, newest 50.
- SupabaseSettingsRepository: `user_settings`, through a copy on the device
  because the detector reads sensitivity on every sample. The ringtone stays
  on the device.

Every table has row level security limiting rows to their owner, and grants
only to `authenticated`. Schema: supabase/migrations. Read failures surface
as FormatException and write failures as StorageWriteException, so the
screens handle offline the same way as unreadable local data.

The Local* repositories stay for tests. Accounts made before Supabase lived
only on the phone and are not moved over.
