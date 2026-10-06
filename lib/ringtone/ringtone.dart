import 'package:equatable/equatable.dart';

class Ringtone extends Equatable {
  const Ringtone({required this.id, required this.title});

  static const bundled = [
    Ringtone(id: 'assets/ringtones/classic.wav', title: 'Classic'),
    Ringtone(id: 'assets/ringtones/marimba.wav', title: 'Marimba'),
    Ringtone(id: 'assets/ringtones/chime.wav', title: 'Chime'),
  ];

  final String id;
  final String title;

  Map<String, dynamic> toJson() => {'id': id, 'title': title};

  @override
  List<Object> get props => [id, title];
}
