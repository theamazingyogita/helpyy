import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_user.dart';
import 'auth_exception.dart';
import 'auth_repository.dart';

/// Keeps accounts on this device until there is a backend.
class LocalAuthRepository implements AuthRepository {
  LocalAuthRepository(
    this._prefs, {
    Random? random,
    Future<Directory> Function()? photoDirectory,
  }) : _random = random ?? Random.secure(),
       _photoDirectory = photoDirectory ?? getApplicationDocumentsDirectory;

  static const _accountsKey = 'accounts';
  static const _sessionKey = 'session_user_id';

  final SharedPreferences _prefs;
  final Random _random;
  final Future<Directory> Function() _photoDirectory;
  final _changes = StreamController<AppUser?>.broadcast();

  @override
  Stream<AppUser?> get changes => _changes.stream;

  @override
  Future<AppUser?> currentUser() async {
    final id = _prefs.getString(_sessionKey);
    if (id == null) return null;
    for (final account in _accounts()) {
      if (account.user.id == id) return account.user;
    }
    return null;
  }

  @override
  Future<AppUser> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    final accounts = _accounts();
    final normalised = email.trim().toLowerCase();
    if (accounts.any((account) => account.user.email == normalised)) {
      throw const AuthException(AuthFailure.emailTaken);
    }
    final salt = base64Encode([
      for (var i = 0; i < 16; i++) _random.nextInt(256),
    ]);
    final user = AppUser(
      id: '${DateTime.now().microsecondsSinceEpoch}${_random.nextInt(1 << 20)}',
      name: name.trim(),
      email: normalised,
    );
    await _write([
      ...accounts,
      _Account(user: user, salt: salt, hash: _hash(salt, password)),
    ]);
    return _startSession(user);
  }

  @override
  Future<AppUser> logIn({
    required String email,
    required String password,
  }) async {
    final normalised = email.trim().toLowerCase();
    for (final account in _accounts()) {
      if (account.user.email != normalised) continue;
      if (account.hash != _hash(account.salt, password)) {
        throw const AuthException(AuthFailure.wrongPassword);
      }
      return _startSession(account.user);
    }
    throw const AuthException(AuthFailure.noAccount);
  }

  @override
  Future<void> logOut() async {
    await _prefs.remove(_sessionKey);
    _changes.add(null);
  }

  @override
  Future<AppUser> updateName(String name) async {
    final user = await _signedInUser();
    return _saveUser(user.copyWith(name: name.trim()));
  }

  @override
  Future<AppUser> updatePhoto(String? localPath) async {
    final user = await _signedInUser();
    final String? photoUrl;
    try {
      photoUrl = localPath == null ? null : await _keepPhoto(user, localPath);
      final updated = await _saveUser(user.copyWith(photoUrl: () => photoUrl));
      _deletePhoto(user.photoUrl);
      return updated;
    } on FileSystemException {
      throw const AuthException(AuthFailure.unavailable);
    }
  }

  @override
  Future<AppUser> useAvatar(String avatarUrl) async {
    final user = await _signedInUser();
    final updated = await _saveUser(user.copyWith(photoUrl: () => avatarUrl));
    _deletePhoto(user.photoUrl);
    return updated;
  }

  Future<AppUser> _signedInUser() async {
    final user = await currentUser();
    if (user == null) throw const AuthException(AuthFailure.unavailable);
    return user;
  }

  Future<AppUser> _saveUser(AppUser updated) async {
    await _write([
      for (final account in _accounts())
        account.user.id == updated.id ? account.withUser(updated) : account,
    ]);
    _changes.add(updated);
    return updated;
  }

  // The picker hands back a temporary file the OS may clear, so keep a copy.
  // A new name each time so the image cache never shows the old picture.
  Future<String> _keepPhoto(AppUser user, String localPath) async {
    final directory = await _photoDirectory();
    final stamp = DateTime.now().microsecondsSinceEpoch;
    final copy = await File(
      localPath,
    ).copy('${directory.path}/profile_${user.id}_$stamp.jpg');
    return copy.uri.toString();
  }

  void _deletePhoto(String? photoUrl) {
    if (photoUrl == null) return;
    final uri = Uri.parse(photoUrl);
    if (uri.scheme != 'file') return;
    final file = File.fromUri(uri);
    // Leftover files only waste space, so a failed delete is not an error.
    file.delete().ignore();
  }

  Future<AppUser> _startSession(AppUser user) async {
    if (!await _prefs.setString(_sessionKey, user.id)) {
      throw const AuthException(AuthFailure.unavailable);
    }
    _changes.add(user);
    return user;
  }

  List<_Account> _accounts() {
    try {
      return [
        for (final raw
            in _prefs.getStringList(_accountsKey) ?? const <String>[])
          _Account.fromJson(jsonDecode(raw)),
      ];
    } on FormatException {
      throw const AuthException(AuthFailure.unavailable);
    }
  }

  Future<void> _write(List<_Account> accounts) async {
    final saved = await _prefs.setStringList(_accountsKey, [
      for (final account in accounts) jsonEncode(account.toJson()),
    ]);
    if (!saved) throw const AuthException(AuthFailure.unavailable);
  }

  String _hash(String salt, String password) =>
      sha256.convert(utf8.encode('$salt:$password')).toString();

  Future<void> dispose() => _changes.close();
}

class _Account {
  const _Account({required this.user, required this.salt, required this.hash});

  factory _Account.fromJson(Object? json) {
    if (json case {
      'user': final Object user,
      'salt': final String salt,
      'hash': final String hash,
    }) {
      return _Account(user: AppUser.fromJson(user), salt: salt, hash: hash);
    }
    throw FormatException('Not an account', json);
  }

  final AppUser user;
  final String salt;
  final String hash;

  _Account withUser(AppUser user) =>
      _Account(user: user, salt: salt, hash: hash);

  Map<String, Object> toJson() => {
    'user': user.toJson(),
    'salt': salt,
    'hash': hash,
  };
}
