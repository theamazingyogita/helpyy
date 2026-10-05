import 'package:flutter_bloc/flutter_bloc.dart';

import '../../storage/storage_write_exception.dart';
import '../data/intro_repository.dart';

part 'intro_event.dart';

/// State is true while the intro should be shown.
class IntroBloc extends Bloc<IntroEvent, bool> {
  IntroBloc(this._repository) : super(!_repository.hasSeenIntro) {
    on<IntroFinished>(_onFinished);
  }

  final IntroRepository _repository;

  Future<void> _onFinished(IntroFinished event, Emitter<bool> emit) async {
    emit(false);
    try {
      await _repository.markSeen();
    } on StorageWriteException {
      // Nothing for the user to do. They see the intro again next launch.
    }
  }
}
