import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' show ClientException;
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

import 'app_user.dart';
import 'auth_exception.dart';
import 'auth_repository.dart';

/// Accounts in Supabase Auth, with the name and picture in the profiles
/// table and photos in the avatars bucket. See supabase/migrations.
class SupabaseAuthRepository implements AuthRepository {
  SupabaseAuthRepository(this._client) {
    _client.auth.onAuthStateChange.listen(_onAuthChange);
  }

  /// Where the links in the sign up and password reset emails lead. It opens helpyy
  /// (see CFBundleURLTypes and the Android intent filter), and
  /// supabase_flutter signs the user in from it. It has to be listed under
  /// Redirect URLs in the Supabase dashboard.
  static const emailRedirect = 'com.helpyy.helpyy://login-callback';

  static const _bucket = 'avatars';

  final supabase.SupabaseClient _client;
  final _changes = StreamController<AppUser?>.broadcast();
  final _passwordResets = StreamController<void>.broadcast();
  var _isResettingPassword = false;

  @override
  Stream<AppUser?> get changes => _changes.stream;

  @override
  Future<AppUser?> currentUser() async {
    final user = _client.auth.currentUser;
    if (user == null) return null;
    return _guard(() => _load(user));
  }

  @override
  Future<AppUser> signUp({
    required String name,
    required String email,
    required String password,
  }) {
    return _guard(() async {
      final response = await _client.auth.signUp(
        email: email.trim().toLowerCase(),
        password: password,
        data: {'name': name.trim()},
        emailRedirectTo: emailRedirect,
      );
      final user = response.user;
      // With email confirmation on there is no session until the link in
      // the email is tapped.
      if (response.session == null || user == null) {
        throw const AuthException(AuthFailure.confirmEmail);
      }
      return _announce(await _load(user));
    });
  }

  @override
  Future<AppUser> logIn({required String email, required String password}) {
    return _guard(() async {
      final response = await _client.auth.signInWithPassword(
        email: email.trim().toLowerCase(),
        password: password,
      );
      final user = response.user;
      if (user == null) throw const AuthException(AuthFailure.unavailable);
      return _announce(await _load(user));
    });
  }

  /// The signed out event from Supabase updates [changes].
  @override
  Future<void> logOut() {
    _isResettingPassword = false;
    return _client.auth.signOut();
  }

  @override
  Future<AppUser> updateName(String name) =>
      _guard(() => _updateProfile({'name': name.trim()}));

  @override
  Future<AppUser> updatePhoto(String? localPath) {
    return _guard(() async {
      if (localPath == null) return _replacePhoto(null);
      final uid = _signedInId();
      // A new name each time so no cache shows the old picture.
      final path = '$uid/${DateTime.now().microsecondsSinceEpoch}.jpg';
      await _client.storage
          .from(_bucket)
          .upload(
            path,
            File(localPath),
            fileOptions: const supabase.FileOptions(contentType: 'image/jpeg'),
          );
      return _replacePhoto(_client.storage.from(_bucket).getPublicUrl(path));
    });
  }

  @override
  Future<AppUser> useAvatar(String avatarUrl) =>
      _guard(() => _replacePhoto(avatarUrl));

  @override
  Future<void> sendPasswordReset(String email) => _guard(
    () => _client.auth.resetPasswordForEmail(
      email.trim().toLowerCase(),
      redirectTo: emailRedirect,
    ),
  );

  @override
  bool get isResettingPassword => _isResettingPassword;

  @override
  Stream<void> get passwordResets => _passwordResets.stream;

  @override
  Future<AppUser> setNewPassword(String password) {
    return _guard(() async {
      final response = await _client.auth.updateUser(
        supabase.UserAttributes(password: password),
      );
      final user = response.user;
      if (user == null) throw const AuthException(AuthFailure.unavailable);
      _isResettingPassword = false;
      return _announce(await _load(user));
    });
  }

  Future<AppUser> _replacePhoto(String? photoUrl) async {
    final before = await _load(_signedInUser());
    final updated = await _updateProfile({'photo_url': photoUrl});
    await _deleteUploaded(before.photoUrl);
    return updated;
  }

  // Leftover files only waste space, so a failed delete is not an error.
  Future<void> _deleteUploaded(String? photoUrl) async {
    final marker = '/$_bucket/';
    if (photoUrl == null || !photoUrl.contains(marker)) return;
    final path = photoUrl.substring(photoUrl.indexOf(marker) + marker.length);
    try {
      await _client.storage.from(_bucket).remove([path]);
    } on supabase.StorageException {
      return;
    }
  }

  Future<AppUser> _updateProfile(Map<String, Object?> changes) async {
    await _client
        .from('profiles')
        .update({...changes, 'updated_at': DateTime.now().toIso8601String()})
        .eq('id', _signedInId());
    return _announce(await _load(_signedInUser()));
  }

  Future<AppUser> _load(supabase.User user) async {
    final row = await _client
        .from('profiles')
        .select('name, photo_url')
        .eq('id', user.id)
        .maybeSingle();
    return AppUser(
      id: user.id,
      name: row?['name'] as String? ?? '',
      email: user.email ?? '',
      photoUrl: row?['photo_url'] as String?,
    );
  }

  // Sessions also start and end without a call from here: a tapped
  // confirmation link signs in, an expired session signs out.
  Future<void> _onAuthChange(supabase.AuthState change) async {
    switch (change.event) {
      case supabase.AuthChangeEvent.signedOut:
        _changes.add(null);
      // A reset link opens a session meant only for choosing a password, so
      // the user is not announced as signed in until they have.
      case supabase.AuthChangeEvent.passwordRecovery:
        _isResettingPassword = true;
        _passwordResets.add(null);
      case supabase.AuthChangeEvent.signedIn:
        final user = change.session?.user;
        if (user == null) return;
        try {
          _announce(await _guard(() => _load(user)));
        } on AuthException {
          // The profile could not load. The app opens signed in on its next
          // start, when currentUser runs again.
          return;
        }
      default:
        return;
    }
  }

  AppUser _announce(AppUser user) {
    _changes.add(user);
    return user;
  }

  supabase.User _signedInUser() =>
      _client.auth.currentUser ??
      (throw const AuthException(AuthFailure.unavailable));

  String _signedInId() => _signedInUser().id;

  /// Turns every Supabase and network failure into an [AuthException] the
  /// screens already know how to show.
  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on supabase.AuthException catch (e) {
      throw AuthException(_failureFor(e));
    } on supabase.PostgrestException {
      throw const AuthException(AuthFailure.unavailable);
    } on supabase.StorageException {
      throw const AuthException(AuthFailure.unavailable);
    } on SocketException {
      throw const AuthException(AuthFailure.unavailable);
    } on ClientException {
      throw const AuthException(AuthFailure.unavailable);
    } on FileSystemException {
      throw const AuthException(AuthFailure.unavailable);
    }
  }

  AuthFailure _failureFor(supabase.AuthException e) => switch (e.code) {
    'user_already_exists' || 'email_exists' => AuthFailure.emailTaken,
    'invalid_credentials' => AuthFailure.badCredentials,
    'email_not_confirmed' => AuthFailure.confirmEmail,
    'weak_password' => AuthFailure.weakPassword,
    'same_password' => AuthFailure.samePassword,
    'over_email_send_rate_limit' => AuthFailure.tooManyEmails,
    _ => AuthFailure.unavailable,
  };
}
