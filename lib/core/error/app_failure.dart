sealed class AppFailure implements Exception {
  const AppFailure({required this.code, required this.message, this.details});

  final String code;
  final String message;
  final Object? details;

  @override
  String toString() => '$runtimeType($code): $message';
}

final class NetworkFailure extends AppFailure {
  const NetworkFailure({
    super.code = 'NETWORK_ERROR',
    super.message = 'Cannot reach Lexi. Check your connection and try again.',
    super.details,
  });
}

final class ValidationFailure extends AppFailure {
  const ValidationFailure({
    super.code = 'VALIDATION_ERROR',
    required super.message,
    super.details,
  });
}

final class NotFoundFailure extends AppFailure {
  const NotFoundFailure({
    super.code = 'NOT_FOUND',
    super.message = 'The requested item was not found.',
    super.details,
  });
}

final class AiNotReadyFailure extends AppFailure {
  const AiNotReadyFailure({
    super.code = 'AI_NOT_READY',
    super.message =
        'AI content is still being generated. Please try again shortly.',
    super.details,
  });
}

class ConflictFailure extends AppFailure {
  const ConflictFailure({
    super.code = 'CONFLICT',
    super.message = 'This action conflicts with the current state.',
    super.details,
  });
}

final class DuplicateWordFailure extends ConflictFailure {
  const DuplicateWordFailure({
    super.code = 'DUPLICATE_WORD',
    super.message = 'This word already exists.',
    super.details,
    this.existingWordId,
  });

  final String? existingWordId;
}

final class UnknownFailure extends AppFailure {
  const UnknownFailure({
    super.code = 'UNKNOWN_ERROR',
    super.message = 'Something went wrong. Please try again.',
    super.details,
  });
}
