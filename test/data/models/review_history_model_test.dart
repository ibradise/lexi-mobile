import 'package:flutter_test/flutter_test.dart';
import 'package:lexi_mobile/data/models/review_history_model.dart';
import 'package:lexi_mobile/domain/entities/review_entry.dart';

void main() {
  const payload = {
    'id': 'review-1',
    'wordId': 'word-1',
    'exerciseType': 'MULTIPLE_CHOICE',
    'result': 'CORRECT',
    'responseTimeMs': 2300,
    'userAnswer': 'vocabulary',
    'correctAnswer': 'vocabulary',
    'hintUsed': true,
    'createdAt': '2026-11-14T09:20:00.000Z',
    'word': {'word': 'lexicon'},
  };

  test('maps a history item and its word relation', () {
    final item = ReviewHistoryItemModel.fromJson(payload).toEntity();

    expect(item.id, 'review-1');
    expect(item.wordId, 'word-1');
    expect(item.word, 'lexicon');
    expect(item.result, ReviewResult.correct);
    expect(item.responseTimeMs, 2300);
    expect(item.hintUsed, isTrue);
    expect(item.createdAt, DateTime.utc(2026, 11, 14, 9, 20));
  });

  test('throws when the word relation is missing', () {
    expect(
      () => ReviewHistoryItemModel.fromJson({...payload, 'word': null}),
      throwsFormatException,
    );
  });

  test('maps page metadata and items to a paginated result', () {
    const page = ReviewHistoryPageModel(
      items: [
        ReviewHistoryItemModel(
          id: 'review-1',
          wordId: 'word-1',
          word: 'lexicon',
          exerciseType: 'MULTIPLE_CHOICE',
          result: ReviewResult.incorrect,
        ),
      ],
      page: 2,
      limit: 20,
      total: 21,
      totalPages: 2,
    );

    final result = page.toEntity();

    expect(result.items.single.word, 'lexicon');
    expect(result.page, 2);
    expect(result.total, 21);
    expect(result.hasMore, isFalse);
  });
}
