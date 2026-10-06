import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../ringtone/ringtone.dart';
import '../../ringtone/ringtone_player.dart';
import '../../storage/storage_write_exception.dart';
import '../data/settings_repository.dart';
import '../motion_sensitivity.dart';

part 'settings_event.dart';
part 'settings_state.dart';

class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  SettingsBloc(this._repository, {required RingtonePlayer player})
    : _player = player,
      super(
        SettingsState(
          sensitivity: _repository.sensitivity,
          ringtone: _repository.ringtone,
        ),
      ) {
    on<SensitivityChosen>(_onSensitivityChosen);
    on<RingtoneChosen>(_onRingtoneChosen);
    on<RingtonePickerOpened>(_onRingtonePickerOpened);
  }

  final SettingsRepository _repository;
  final RingtonePlayer _player;

  Future<void> _onSensitivityChosen(
    SensitivityChosen event,
    Emitter<SettingsState> emit,
  ) async {
    final previous = state.sensitivity;
    emit(state.copyWith(sensitivity: event.value));
    try {
      await _repository.saveSensitivity(event.value);
    } on StorageWriteException {
      emit(state.copyWith(sensitivity: previous, saveFailed: true));
    }
  }

  Future<void> _onRingtoneChosen(
    RingtoneChosen event,
    Emitter<SettingsState> emit,
  ) async {
    await _player
        .play(event.ringtone, loop: false)
        .onError<PlatformException>((_, _) {});
    await _save(event.ringtone, emit);
  }

  Future<void> _onRingtonePickerOpened(
    RingtonePickerOpened event,
    Emitter<SettingsState> emit,
  ) async {
    final Ringtone? picked;
    try {
      picked = await _player.pick(state.ringtone);
    } on PlatformException {
      emit(state.copyWith(pickerFailed: true));
      return;
    }
    if (picked != null) await _save(picked, emit);
  }

  Future<void> _save(Ringtone ringtone, Emitter<SettingsState> emit) async {
    final previous = state.ringtone;
    emit(state.copyWith(ringtone: () => ringtone));
    try {
      await _repository.saveRingtone(ringtone);
    } on StorageWriteException {
      emit(state.copyWith(ringtone: () => previous, saveFailed: true));
    }
  }

  @override
  Future<void> close() async {
    await _player.stop().onError<PlatformException>((_, _) {});
    return super.close();
  }
}
