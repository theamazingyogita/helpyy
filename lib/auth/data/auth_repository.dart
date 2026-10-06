import 'app_user.dart';
import 'auth_exception.dart';

/// Accounts and the signed in session.
///
/// [LocalAuthRepository] keeps accounts on the device. A backend version
/// implements this same interface and is swapped in where the app is built,
/// nothing else changes.
abstract interface class AuthRepository {
  /// Emits the signed in user, or null, whenever it changes.
  Stream<AppUser?> get changes;

  /// Restores the session saved from a previous launch.
  Future<AppUser?> currentUser();

  /// Throws [AuthException].
  Future<AppUser> signUp({
    required String name,
    required String email,
    required String password,
  });

  /// Throws [AuthException].
  Future<AppUser> logIn({required String email, required String password});

  Future<void> logOut();

  /// Throws [AuthException].
  Future<AppUser> updateName(String name);

  /// Sets the profile picture from a file on the device, or removes it when
  /// [localPath] is null. A backend version uploads the file.
  /// Throws [AuthException].
  Future<AppUser> updatePhoto(String? localPath);

  /// Sets the profile picture to a character from CartoonAvatar.urlFor.
  /// Throws [AuthException].
  Future<AppUser> useAvatar(String avatarUrl);

  /// Emails a link for choosing a new password. Completes the same way
  /// whether or not an account exists, so the email cannot be probed.
  /// Throws [AuthException].
  Future<void> sendPasswordReset(String email);

  /// True while the user has opened a reset link and not yet picked a new
  /// password. [passwordResets] emits when it turns true.
  bool get isResettingPassword;

  Stream<void> get passwordResets;

  /// Saves the new password for the reset in progress and signs in.
  /// Throws [AuthException].
  Future<AppUser> setNewPassword(String password);
}
