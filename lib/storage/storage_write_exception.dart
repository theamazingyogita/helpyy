class StorageWriteException implements Exception {
  const StorageWriteException();

  @override
  String toString() => 'StorageWriteException: could not write to storage';
}
