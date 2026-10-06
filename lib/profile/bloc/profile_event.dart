part of 'profile_bloc.dart';

sealed class ProfileEvent {
  const ProfileEvent();
}

final class ProfileNameSaved extends ProfileEvent {
  const ProfileNameSaved(this.name);

  final String name;
}

final class ProfilePhotoChosen extends ProfileEvent {
  const ProfilePhotoChosen(this.path);

  final String path;
}

final class ProfilePhotoRemoved extends ProfileEvent {
  const ProfilePhotoRemoved();
}

final class ProfileAvatarChosen extends ProfileEvent {
  const ProfileAvatarChosen(this.seed);

  final String seed;
}
