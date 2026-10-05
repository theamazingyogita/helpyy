/// Lets queued bloc events and stream deliveries run.
Future<void> settle() => Future<void>.delayed(Duration.zero);
