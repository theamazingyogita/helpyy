import 'package:flutter_bloc/flutter_bloc.dart';

import '../../storage/storage_write_exception.dart';
import '../data/intro_repository.dart';

part 'intro_event.dart';

class IntroBloc extends Bloc<IntroEvent, bool> {
  IntroBloc(this._repository) : super(!_repository.hasSeenIntro) {
    on<IntroFinished>(_onFinished);
  }

  final IntroRepository _repository;

  Future<void> _onFinished(IntroFinished event, Emitter<bool> emit) async {
    emit(false);
    await _repository.markSeen().onError<StorageWriteException>((_, _) {});
  }
}
