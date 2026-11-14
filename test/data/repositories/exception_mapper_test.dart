import 'package:flutter_test/flutter_test.dart';
import 'package:lexi_mobile/core/error/app_failure.dart';
import 'package:lexi_mobile/core/network/api_exception.dart';
import 'package:lexi_mobile/data/repositories/exception_mapper.dart';

void main() {
  group('mapExceptionToFailure', () {
    test('maps validation errors', () {
      final failure = mapExceptionToFailure(
        const ApiException(
          code: 'VALIDATION_ERROR',
          message: 'Word is required',
          statusCode: 400,
        ),
      );

      expect(failure, isA<ValidationFailure>());
      expect(failure.message, 'Word is required');
      expect(failure.code, 'VALIDATION_ERROR');
    });

    test('maps invalid exercises to a validation failure', () {
      final failure = mapExceptionToFailure(
        const ApiException(
          code: 'INVALID_EXERCISE',
          message: 'Exercise not found for this word',
          statusCode: 400,
        ),
      );

      expect(failure, isA<ValidationFailure>());
      expect(failure.code, 'INVALID_EXERCISE');
    });

    test('maps not found errors', () {
      final failure = mapExceptionToFailure(
        const ApiException(
          code: 'NOT_FOUND',
          message: 'Word not found',
          statusCode: 404,
        ),
      );

      expect(failure, isA<NotFoundFailure>());
    });

    test('maps AI not ready errors', () {
      final failure = mapExceptionToFailure(
        const ApiException(
          code: 'AI_NOT_READY',
          message: 'AI content is not ready for this word',
          statusCode: 409,
        ),
      );

      expect(failure, isA<AiNotReadyFailure>());
    });

    test('maps duplicate words and preserves the existing word id', () {
      final failure = mapExceptionToFailure(
        const ApiException(
          code: 'DUPLICATE_WORD',
          message: 'Word already exists',
          statusCode: 409,
          details: {'id': 'word-1'},
        ),
      );

      expect(failure, isA<DuplicateWordFailure>());
      expect((failure as DuplicateWordFailure).existingWordId, 'word-1');
    });

    test('maps generic conflict errors', () {
      final failure = mapExceptionToFailure(
        const ApiException(
          code: 'CONFLICT',
          message: 'Resource already exists',
          statusCode: 409,
        ),
      );

      expect(failure, isA<ConflictFailure>());
      expect(failure, isNot(isA<DuplicateWordFailure>()));
    });

    test('maps timeouts to a network failure', () {
      final failure = mapExceptionToFailure(const ApiException.timeout());

      expect(failure, isA<NetworkFailure>());
      expect(failure.code, 'TIMEOUT');
    });

    test('maps network errors to a network failure', () {
      final failure = mapExceptionToFailure(const ApiException.network());

      expect(failure, isA<NetworkFailure>());
      expect(failure.code, 'NETWORK_ERROR');
    });

    test('maps parse errors to an unknown failure', () {
      final failure = mapExceptionToFailure(const ApiException.parsing());

      expect(failure, isA<UnknownFailure>());
      expect(failure.code, 'PARSE_ERROR');
    });

    test('maps unknown status codes to an unknown failure', () {
      final failure = mapExceptionToFailure(
        const ApiException(
          code: 'UNEXPECTED',
          message: 'Unexpected response',
          statusCode: 500,
        ),
      );

      expect(failure, isA<UnknownFailure>());
    });

    test('maps non-ApiException errors to an unknown failure', () {
      final failure = mapExceptionToFailure(StateError('boom'));

      expect(failure, isA<UnknownFailure>());
      expect(failure.details, isA<StateError>());
    });
  });
}
