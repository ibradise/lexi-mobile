import 'package:flutter_test/flutter_test.dart';
import 'package:lexi_mobile/core/error/app_failure.dart';
import 'package:lexi_mobile/core/network/api_exception.dart';
import 'package:lexi_mobile/data/datasources/review_remote_data_source.dart';
import 'package:lexi_mobile/data/models/review_history_model.dart';
import 'package:lexi_mobile/data/repositories/review_repository_impl.dart';
import 'package:lexi_mobile/domain/entities/review_entry.dart';
import 'package:lexi_mobile/domain/entities/review_history_query.dart';
import 'package:mocktail/mocktail.dart';

class MockReviewRemoteDataSource extends Mock
    implements ReviewRemoteDataSource {}

void main() {
  late MockReviewRemoteDataSource remoteDataSource;
  late ReviewRepositoryImpl repository;

  const page = ReviewHistoryPageModel(
    items: [
      ReviewHistoryItemModel(
        id: 'review-1',
        wordId: 'word-1',
        word: 'lexicon',
        exerciseType: 'MULTIPLE_CHOICE',
        result: ReviewResult.correct,
      ),
    ],
    page: 1,
    limit: 20,
    total: 1,
    totalPages: 1,
  );

  setUpAll(() {
    registerFallbackValue(const ReviewHistoryQuery());
  });

  setUp(() {
    remoteDataSource = MockReviewRemoteDataSource();
    repository = ReviewRepositoryImpl(remoteDataSource);
  });

  test('maps a history page to domain entities', () async {
    when(() => remoteDataSource.getHistory(const ReviewHistoryQuery()))
        .thenAnswer((_) async => page);

    final result = await repository.getHistory(const ReviewHistoryQuery());

    expect(result.items.single.word, 'lexicon');
    expect(result.items.single.result, ReviewResult.correct);
    expect(result.total, 1);
  });

  test('translates remote failures into AppFailure', () async {
    when(() => remoteDataSource.getHistory(any())).thenThrow(
      const ApiException(
        code: 'VALIDATION_ERROR',
        message: 'Invalid page',
        statusCode: 400,
      ),
    );

    await expectLater(
      repository.getHistory(const ReviewHistoryQuery()),
      throwsA(isA<ValidationFailure>()),
    );
  });
}
