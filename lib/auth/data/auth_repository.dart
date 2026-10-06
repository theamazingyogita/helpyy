import 'app_user.dart';

abstract interface class AuthRepository {
  Stream<AppUser?> get changes;

  Future<AppUser?> currentUser();

  Future<AppUser> signUp({
    required String name,
    required String email,
    required String password,
  });

  Future<AppUser> logIn({required String email, required String password});

  Future<void> logOut();

  Future<AppUser> updateName(String name);

  Future<AppUser> updatePhoto(String? localPath);

  Future<AppUser> useAvatar(String avatarUrl);

  Future<void> sendPasswordReset(String email);

  bool get isResettingPassword;

  Stream<void> get passwordResets;

  Future<AppUser> setNewPassword(String password);
}
