part of 'profile_bloc.dart';

sealed class ProfileEvent {
  const ProfileEvent();
}

final class ProfileNameSaved extends ProfileEvent {
  const ProfileNameSaved(this.name);

  final String name;
}

/// A picture was taken or picked. [path] is the file the picker returned.
final class ProfilePhotoChosen extends ProfileEvent {
  const ProfilePhotoChosen(this.path);

  final String path;
}

final class ProfilePhotoRemoved extends ProfileEvent {
  const ProfilePhotoRemoved();
}

/// A ready made character was picked instead of a photo.
final class ProfileAvatarChosen extends ProfileEvent {
  const ProfileAvatarChosen(this.seed);

  final String seed;
}
