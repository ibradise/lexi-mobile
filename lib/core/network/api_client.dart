import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import 'api_exception.dart';
import 'api_response.dart';

class ApiClient {
  factory ApiClient({required http.Client client, String? baseUrl}) {
    return ApiClient._(
      client,
      _normalizeBaseUrl(baseUrl ?? AppConfig.apiBaseUrl),
    );
  }

  ApiClient._(this._client, this._baseUrl);

  final http.Client _client;
  final String _baseUrl;

  Future<ApiResponse> get(
    String path, {
    Map<String, dynamic>? query,
    Duration? timeout,
  }) {
    return _send('GET', path, query: query, timeout: timeout);
  }

  Future<ApiResponse> post(String path, {Object? body, Duration? timeout}) {
    return _send('POST', path, body: body, timeout: timeout);
  }

  Future<ApiResponse> delete(String path, {Duration? timeout}) {
    return _send('DELETE', path, timeout: timeout);
  }

  void close() {
    _client.close();
  }

  Future<ApiResponse> _send(
    String method,
    String path, {
    Map<String, dynamic>? query,
    Object? body,
    Duration? timeout,
  }) async {
    final request = http.Request(method, _buildUri(path, query))
      ..headers['Accept'] = 'application/json';

    if (body != null) {
      request.headers['Content-Type'] = 'application/json';
      request.body = jsonEncode(body);
    }

    final effectiveTimeout = timeout ?? AppConfig.requestTimeout;

    late final http.StreamedResponse streamedResponse;
    try {
      streamedResponse = await _client.send(request).timeout(effectiveTimeout);
    } on TimeoutException catch (error) {
      throw ApiException.timeout(details: error);
    } on SocketException catch (error) {
      throw ApiException.network(details: error);
    } on http.ClientException catch (error) {
      throw ApiException.network(details: error);
    }

    late final http.Response response;
    try {
      response = await http.Response.fromStream(streamedResponse)
          .timeout(effectiveTimeout);
    } on TimeoutException catch (error) {
      throw ApiException.timeout(details: error);
    } on http.ClientException catch (error) {
      throw ApiException.network(details: error);
    }

    final isSuccess = response.statusCode >= 200 && response.statusCode < 300;
    final rawBody = response.body.trim();

    if (rawBody.isEmpty) {
      if (isSuccess) {
        return const ApiResponse();
      }
      throw ApiException(
        code: 'HTTP_${response.statusCode}',
        message: 'Request failed with status ${response.statusCode}.',
        statusCode: response.statusCode,
      );
    }

    Object? decoded;
    try {
      decoded = jsonDecode(rawBody);
    } on FormatException catch (error) {
      if (!isSuccess) {
        throw ApiException(
          code: 'HTTP_${response.statusCode}',
          message: 'Request failed with status ${response.statusCode}.',
          statusCode: response.statusCode,
          details: error,
        );
      }
      throw ApiException.parsing(details: error);
    }

    if (decoded is! Map<String, dynamic>) {
      if (!isSuccess) {
        throw ApiException(
          code: 'HTTP_${response.statusCode}',
          message: 'Request failed with status ${response.statusCode}.',
          statusCode: response.statusCode,
          details: decoded,
        );
      }
      throw ApiException.parsing(details: decoded);
    }

    final success = decoded['success'];

    if (success != true) {
      final errorValue = decoded['error'];
      final error = errorValue is Map<String, dynamic>
          ? errorValue
          : const <String, dynamic>{};
      final code = error['code'];
      final message = error['message'];

      throw ApiException(
        code: code is String ? code : 'HTTP_${response.statusCode}',
        message: message is String
            ? message
            : 'Request failed with status ${response.statusCode}.',
        statusCode: response.statusCode,
        details: error['details'],
      );
    }

    if (!isSuccess) {
      throw ApiException(
        code: 'HTTP_${response.statusCode}',
        message: 'Request failed with status ${response.statusCode}.',
        statusCode: response.statusCode,
      );
    }

    final metaValue = decoded['meta'];

    return ApiResponse(
      data: decoded['data'],
      meta: metaValue is Map<String, dynamic>
          ? PageMeta.fromJson(metaValue)
          : null,
    );
  }

  Uri _buildUri(String path, Map<String, dynamic>? query) {
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    final uri = Uri.parse('$_baseUrl$normalizedPath');

    if (query == null || query.isEmpty) {
      return uri;
    }

    final queryParameters = <String, String>{};
    for (final entry in query.entries) {
      if (entry.value == null) {
        continue;
      }
      queryParameters[entry.key] = entry.value.toString();
    }

    return uri.replace(
      queryParameters: {...uri.queryParameters, ...queryParameters},
    );
  }

  static String _normalizeBaseUrl(String value) {
    var normalized = value.trim();
    while (normalized.endsWith('/')) {
      normalized = normalized.substring(0, normalized.length - 1);
    }
    return normalized;
  }
}
