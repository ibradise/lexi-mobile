import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:lexi_mobile/core/network/api_client.dart';
import 'package:lexi_mobile/core/network/api_exception.dart';

void main() {
  group('ApiClient', () {
    test(
      'parses a successful envelope, query parameters, and pagination meta',
      () async {
        final client = MockClient((request) async {
          expect(request.method, 'GET');
          expect(request.url.path, '/api/vocabulary');
          expect(request.url.queryParameters['search'], 'test');
          expect(request.url.queryParameters['page'], '2');
          expect(request.url.queryParameters.containsKey('empty'), isFalse);
          expect(request.headers['Accept'], 'application/json');

          return http.Response(
            jsonEncode({
              'success': true,
              'data': [
                {'id': 'word-1', 'word': 'lexicon'},
              ],
              'error': null,
              'meta': {'page': 2, 'limit': 20, 'total': 1, 'totalPages': 1},
            }),
            200,
          );
        });

        final api = ApiClient(
          client: client,
          baseUrl: 'https://example.com/api/',
        );

        final response = await api.get(
          '/vocabulary',
          query: {'search': 'test', 'page': 2, 'empty': null},
        );

        expect(response.data, [
          {'id': 'word-1', 'word': 'lexicon'},
        ]);
        expect(response.meta?.page, 2);
        expect(response.meta?.limit, 20);
        expect(response.meta?.total, 1);
        expect(response.meta?.totalPages, 1);
      },
    );

    test('throws an ApiException for an error envelope', () async {
      final client = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'success': false,
            'data': null,
            'error': {
              'code': 'DUPLICATE_WORD',
              'message': 'Word already exists',
              'details': {'id': 'word-1'},
            },
            'meta': null,
          }),
          409,
        );
      });

      final api = ApiClient(client: client, baseUrl: 'https://example.com/api');

      await expectLater(
        api.post('/vocabulary', body: {'word': 'lexicon'}),
        throwsA(
          isA<ApiException>()
              .having((error) => error.code, 'code', 'DUPLICATE_WORD')
              .having((error) => error.statusCode, 'statusCode', 409)
              .having(
                (error) => (error.details as Map)['id'],
                'existing id',
                'word-1',
              ),
        ),
      );
    });

    test('maps a non-2xx non-JSON response to an HTTP exception', () async {
      final client = MockClient((request) async {
        return http.Response('server error', 500);
      });

      final api = ApiClient(client: client, baseUrl: 'https://example.com/api');

      await expectLater(
        api.get('/vocabulary'),
        throwsA(
          isA<ApiException>()
              .having((error) => error.code, 'code', 'HTTP_500')
              .having((error) => error.statusCode, 'statusCode', 500),
        ),
      );
    });

    test('throws a parsing exception for malformed JSON', () async {
      final client = MockClient((request) async {
        return http.Response('{', 200);
      });

      final api = ApiClient(client: client, baseUrl: 'https://example.com/api');

      await expectLater(
        api.get('/vocabulary'),
        throwsA(
          isA<ApiException>().having(
            (error) => error.code,
            'code',
            'PARSE_ERROR',
          ),
        ),
      );
    });

    test(
      'throws a timeout exception when the request exceeds its timeout',
      () async {
        final client = MockClient((request) async {
          await Future<void>.delayed(const Duration(milliseconds: 50));
          return http.Response(
            jsonEncode({
              'success': true,
              'data': null,
              'error': null,
              'meta': null,
            }),
            200,
          );
        });

        final api = ApiClient(
          client: client,
          baseUrl: 'https://example.com/api',
        );

        await expectLater(
          api.get('/vocabulary', timeout: const Duration(milliseconds: 5)),
          throwsA(
            isA<ApiException>().having(
              (error) => error.code,
              'code',
              'TIMEOUT',
            ),
          ),
        );
      },
    );

    test('sends a JSON POST body with the correct headers', () async {
      final client = MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.headers['Content-Type'], startsWith('application/json'));
        expect(jsonDecode(request.body), {'word': 'lexicon'});

        return http.Response(
          jsonEncode({
            'success': true,
            'data': {'id': 'word-1'},
            'error': null,
            'meta': null,
          }),
          201,
        );
      });

      final api = ApiClient(client: client, baseUrl: 'https://example.com/api');

      final response = await api.post('/vocabulary', body: {'word': 'lexicon'});

      expect((response.data as Map)['id'], 'word-1');
    });

    test('returns an empty response for a 204 with no body', () async {
      final client = MockClient((request) async {
        return http.Response('', 204);
      });

      final api = ApiClient(client: client, baseUrl: 'https://example.com/api');

      final response = await api.delete('/vocabulary/word-1');

      expect(response.data, isNull);
      expect(response.meta, isNull);
    });
  });
}
