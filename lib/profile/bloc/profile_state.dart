part of 'profile_bloc.dart';

class ProfileState extends Equatable {
  const ProfileState({
    this.status = FormStatus.idle,
    this.nameError,
    this.isSaved = false,
  });

  final FormStatus status;
  final FieldError? nameError;

  /// True right after a successful save, so the page can confirm it.
  final bool isSaved;

  @override
  List<Object?> get props => [status, nameError, isSaved];
}
