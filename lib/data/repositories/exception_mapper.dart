import '../../core/error/app_failure.dart';
import '../../core/network/api_exception.dart';
import '../../core/utils/app_logger.dart';

AppFailure mapExceptionToFailure(Object error, [StackTrace? stackTrace]) {
  if (error is! ApiException) {
    if (stackTrace != null) {
      logError('Unexpected data-layer error', error, stackTrace);
    }
    return UnknownFailure(details: error);
  }

  switch (error.code) {
    case 'VALIDATION_ERROR':
    case 'INVALID_EXERCISE':
      return ValidationFailure(
        code: error.code,
        message: error.message,
        details: error.details,
      );
    case 'NOT_FOUND':
      return NotFoundFailure(
        code: error.code,
        message: error.message,
        details: error.details,
      );
    case 'AI_NOT_READY':
      return AiNotReadyFailure(
        code: error.code,
        message: error.message,
        details: error.details,
      );
    case 'DUPLICATE_WORD':
      return DuplicateWordFailure(
        code: error.code,
        message: error.message,
        details: error.details,
        existingWordId: _existingWordId(error.details),
      );
    case 'CONFLICT':
      return ConflictFailure(
        code: error.code,
        message: error.message,
        details: error.details,
      );
    case 'TIMEOUT':
      return const NetworkFailure(
        code: 'TIMEOUT',
        message: 'The request timed out. Please try again.',
      );
    case 'NETWORK_ERROR':
      return const NetworkFailure();
    case 'PARSE_ERROR':
      return const UnknownFailure(
        code: 'PARSE_ERROR',
        message:
            'The server returned an unexpected response. Please try again.',
      );
  }

  if (error.statusCode == 400) {
    return ValidationFailure(
      code: error.code,
      message: error.message,
      details: error.details,
    );
  }

  if (error.statusCode == 404) {
    return NotFoundFailure(
      code: error.code,
      message: error.message,
      details: error.details,
    );
  }

  if (error.statusCode == 409) {
    return ConflictFailure(
      code: error.code,
      message: error.message,
      details: error.details,
    );
  }

  if ((error.statusCode ?? 0) >= 500) {
    return UnknownFailure(
      code: error.code,
      message: 'The server is unavailable. Please try again later.',
      details: error.details,
    );
  }

  return UnknownFailure(
    code: error.code,
    message: error.message,
    details: error.details,
  );
}

String? _existingWordId(Object? details) {
  if (details is Map) {
    final id = details['id'];
    if (id is String) {
      return id;
    }
  }
  return null;
}
