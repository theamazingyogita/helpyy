part of 'profile_bloc.dart';

class ProfileState extends Equatable {
  const ProfileState({
    this.status = FormStatus.idle,
    this.nameError,
    this.isSaved = false,
  });

  final FormStatus status;
  final FieldError? nameError;

  final bool isSaved;

  @override
  List<Object?> get props => [status, nameError, isSaved];
}
