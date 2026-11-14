enum ApiExceptionKind { network, timeout, http, parsing }

class ApiException implements Exception {
  const ApiException({
    required this.code,
    required this.message,
    this.kind = ApiExceptionKind.http,
    this.statusCode,
    this.details,
  });

  const ApiException.network({
    this.message = 'Cannot reach the server.',
    this.details,
  }) : code = 'NETWORK_ERROR',
       kind = ApiExceptionKind.network,
       statusCode = null;

  const ApiException.timeout({
    this.message = 'The request timed out.',
    this.details,
  }) : code = 'TIMEOUT',
       kind = ApiExceptionKind.timeout,
       statusCode = null;

  const ApiException.parsing({
    this.message = 'The server returned an unexpected response.',
    this.details,
  }) : code = 'PARSE_ERROR',
       kind = ApiExceptionKind.parsing,
       statusCode = null;

  final String code;
  final String message;
  final ApiExceptionKind kind;
  final int? statusCode;
  final Object? details;

  @override
  String toString() => 'ApiException($code): $message';
}
