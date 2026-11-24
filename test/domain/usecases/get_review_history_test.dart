import 'package:flutter_test/flutter_test.dart';
import 'package:lexi_mobile/domain/entities/paginated_result.dart';
import 'package:lexi_mobile/domain/entities/review_history_item.dart';
import 'package:lexi_mobile/domain/entities/review_history_query.dart';
import 'package:lexi_mobile/domain/repositories/review_repository.dart';
import 'package:lexi_mobile/domain/usecases/get_review_history.dart';
import 'package:mocktail/mocktail.dart';

class MockReviewRepository extends Mock implements ReviewRepository {}

void main() {
  late MockReviewRepository repository;

  const result = PaginatedResult<ReviewHistoryItem>(
    items: [],
    page: 1,
    limit: 20,
    total: 0,
    totalPages: 0,
  );

  setUp(() {
    repository = MockReviewRepository();
  });

  test('trims the word filter and bounds pagination', () async {
    when(
      () => repository.getHistory(
        const ReviewHistoryQuery(wordId: 'word-1', page: 1, limit: 100),
      ),
    ).thenAnswer((_) async => result);

    await GetReviewHistory(repository)(
      const ReviewHistoryQuery(wordId: ' word-1 ', page: 0, limit: 500),
    );

    verify(
      () => repository.getHistory(
        const ReviewHistoryQuery(wordId: 'word-1', page: 1, limit: 100),
      ),
    ).called(1);
  });

  test('clears a blank word filter', () async {
    when(() => repository.getHistory(const ReviewHistoryQuery()))
        .thenAnswer((_) async => result);

    await GetReviewHistory(repository)(const ReviewHistoryQuery(wordId: '   '));

    verify(() => repository.getHistory(const ReviewHistoryQuery())).called(1);
  });
}
