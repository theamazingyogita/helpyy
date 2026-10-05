import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

class AppUser extends Equatable {
  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    this.photoUrl,
  });

  factory AppUser.fromJson(Object? json) {
    if (json case {
      'id': final String id,
      'name': final String name,
      'email': final String email,
    }) {
      return AppUser(
        id: id,
        name: name,
        email: email,
        photoUrl: switch (json['photoUrl']) {
          final String url => url,
          _ => null,
        },
      );
    }
    throw FormatException('Not a user', json);
  }

  final String id;
  final String name;
  final String email;

  /// A file:// URI while photos live on the device, an https URL once they
  /// come from a backend.
  final String? photoUrl;

  AppUser copyWith({String? name, ValueGetter<String?>? photoUrl}) => AppUser(
    id: id,
    name: name ?? this.name,
    email: email,
    photoUrl: photoUrl != null ? photoUrl() : this.photoUrl,
  );

  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'photoUrl': photoUrl,
  };

  @override
  List<Object?> get props => [id, name, email, photoUrl];
}
