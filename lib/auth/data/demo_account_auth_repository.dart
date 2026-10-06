import 'dart:async';

import 'app_user.dart';
import 'auth_exception.dart';
import 'auth_repository.dart';
import 'local_auth_repository.dart';

class DemoAccountAuthRepository implements AuthRepository {
  DemoAccountAuthRepository({
    required AuthRepository backend,
    required LocalAuthRepository demo,
  }) : _backend = backend,
       _demo = demo {
    _demo.changes.listen(_changes.add);
    _backend.changes.listen((user) {
      if (!_isDemo) _changes.add(user);
    });
  }

  static const email = 'demo@helpyy.app';
  static const password = 'helpyy123';

  static bool isDemo(AppUser user) => user.email == email;

  final AuthRepository _backend;
  final LocalAuthRepository _demo;
  final _changes = StreamController<AppUser?>.broadcast();
  var _isDemo = false;

  AuthRepository get _active => _isDemo ? _demo : _backend;

  @override
  Stream<AppUser?> get changes => _changes.stream;

  @override
  Future<AppUser?> currentUser() async {
    final demoUser = await _demo.currentUser();
    if (demoUser != null) {
      _isDemo = true;
      return demoUser;
    }
    return _backend.currentUser();
  }

  @override
  Future<AppUser> logIn({required String email, required String password}) {
    if (email.trim().toLowerCase() != DemoAccountAuthRepository.email ||
        password != DemoAccountAuthRepository.password) {
      return _backend.logIn(email: email, password: password);
    }
    return _logInToDemo();
  }

  Future<AppUser> _logInToDemo() async {
    _isDemo = true;
    try {
      return await _demo.logIn(email: email, password: password);
    } on AuthException catch (e) {
      if (e.failure != AuthFailure.noAccount) {
        _isDemo = false;
        rethrow;
      }
      return _demo.signUp(name: 'Demo', email: email, password: password);
    }
  }

  @override
  Future<AppUser> signUp({
    required String name,
    required String email,
    required String password,
  }) => _backend.signUp(name: name, email: email, password: password);

  @override
  Future<void> logOut() async {
    if (!_isDemo) return _backend.logOut();
    await _demo.logOut();
    _isDemo = false;
  }

  @override
  Future<AppUser> updateName(String name) => _active.updateName(name);

  @override
  Future<AppUser> updatePhoto(String? localPath) =>
      _active.updatePhoto(localPath);

  @override
  Future<AppUser> useAvatar(String avatarUrl) => _active.useAvatar(avatarUrl);

  @override
  Future<void> sendPasswordReset(String email) =>
      _backend.sendPasswordReset(email);

  @override
  bool get isResettingPassword => !_isDemo && _backend.isResettingPassword;

  @override
  Stream<void> get passwordResets => _backend.passwordResets;

  @override
  Future<AppUser> setNewPassword(String password) =>
      _backend.setNewPassword(password);
}
