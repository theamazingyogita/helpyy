import 'dart:io';

import 'package:http/http.dart' show ClientException;
import 'package:supabase_flutter/supabase_flutter.dart';

import 'storage_write_exception.dart';

/// Runs a Supabase read and reports any failure the way the repository
/// interfaces promise: as a [FormatException], which the screens show as
/// "could not be read" with a retry.
Future<T> readRemote<T>(Future<T> Function() read) async {
  try {
    return await read();
  } on PostgrestException catch (e) {
    throw FormatException('Could not load: ${e.message}');
  } on SocketException catch (e) {
    throw FormatException('Offline: ${e.message}');
  } on ClientException catch (e) {
    throw FormatException('Offline: ${e.message}');
  }
}

/// Runs a Supabase write and reports any failure as a
/// [StorageWriteException].
Future<T> writeRemote<T>(Future<T> Function() write) async {
  try {
    return await write();
  } on PostgrestException {
    throw const StorageWriteException();
  } on SocketException {
    throw const StorageWriteException();
  } on ClientException {
    throw const StorageWriteException();
  }
}
