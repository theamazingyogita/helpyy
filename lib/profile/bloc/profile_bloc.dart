import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../auth/data/auth_exception.dart';
import '../../auth/data/auth_repository.dart';
import '../../auth/form_status.dart';
import '../../auth/validation.dart';
import '../../avatar/cartoon_avatar.dart';

part 'profile_event.dart';
part 'profile_state.dart';

/// Edits to the signed in user. The new user reaches the app through
/// AuthRepository changes, so this bloc only tracks progress and errors.
class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  ProfileBloc(this._repository) : super(const ProfileState()) {
    on<ProfileNameSaved>(_onNameSaved);
    on<ProfilePhotoChosen>(
      (event, emit) =>
          _savePhoto(() => _repository.updatePhoto(event.path), emit),
    );
    on<ProfilePhotoRemoved>(
      (_, emit) => _savePhoto(() => _repository.updatePhoto(null), emit),
    );
    on<ProfileAvatarChosen>(
      (event, emit) => _savePhoto(
        () => _repository.useAvatar(CartoonAvatar.urlFor(event.seed)),
        emit,
      ),
    );
  }

  final AuthRepository _repository;

  Future<void> _onNameSaved(
    ProfileNameSaved event,
    Emitter<ProfileState> emit,
  ) async {
    final error = validateName(event.name);
    if (error != null) {
      emit(ProfileState(nameError: error));
      return;
    }
    emit(const ProfileState(status: FormStatus.submitting));
    try {
      await _repository.updateName(event.name);
      emit(const ProfileState(isSaved: true));
    } on AuthException {
      emit(const ProfileState(status: FormStatus.failed));
    }
  }

  Future<void> _savePhoto(
    Future<void> Function() save,
    Emitter<ProfileState> emit,
  ) async {
    emit(const ProfileState(status: FormStatus.submitting));
    try {
      await save();
      emit(const ProfileState());
    } on AuthException {
      emit(const ProfileState(status: FormStatus.failed));
    }
  }
}
