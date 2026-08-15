sealed class AppFailure implements Exception {
  const AppFailure(this.message, {this.cause});

  final String message;
  final Object? cause;

  @override
  String toString() => '$runtimeType: $message';
}

final class StorageFailure extends AppFailure {
  const StorageFailure(super.message, {super.cause});
}

final class DatabaseFailure extends AppFailure {
  const DatabaseFailure(super.message, {super.cause});
}

final class ProcessingFailure extends AppFailure {
  const ProcessingFailure(super.message, {super.cause});
}
