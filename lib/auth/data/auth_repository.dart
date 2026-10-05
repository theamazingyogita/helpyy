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
}
