import 'package:flutter_test/flutter_test.dart';
import 'package:lexi_mobile/data/models/dashboard_model.dart';

void main() {
  const payload = {
    'todayReview': {
      'due': 8,
      'newWords': 4,
      'needAttention': 2,
      'becomingStrong': 3,
    },
    'weakestWords': [
      {'wordId': 'word-1', 'word': 'lexicon', 'knowledgeScore': 0.15},
    ],
    'stats': {
      'totalWords': 42,
      'new': 4,
      'learning': 12,
      'familiar': 10,
      'strong': 9,
      'mastered': 7,
      'reviewsToday': 5,
      'accuracyLast7Days': 0.8,
      'currentStreak': 3,
    },
  };

  test('parses dashboard data into entities', () {
    final data = DashboardModel.fromJson(payload).toEntity();

    expect(data.todayReview.due, 8);
    expect(data.todayReview.newWords, 4);
    expect(data.todayReview.needAttention, 2);
    expect(data.todayReview.becomingStrong, 3);
    expect(data.weakestWords.single.word, 'lexicon');
    expect(data.weakestWords.single.knowledgeScore, 0.15);
    expect(data.stats.totalWords, 42);
    expect(data.stats.newWords, 4);
    expect(data.stats.learning, 12);
    expect(data.stats.reviewsToday, 5);
    expect(data.stats.accuracyLast7Days, 0.8);
    expect(data.stats.currentStreak, 3);
    expect(data.isLibraryEmpty, isFalse);
  });

  test('recognizes an empty library', () {
    final data = DashboardModel.fromJson({
      'todayReview': {
        'due': 0,
        'newWords': 0,
        'needAttention': 0,
        'becomingStrong': 0,
      },
      'weakestWords': [],
      'stats': {
        'totalWords': 0,
        'new': 0,
        'learning': 0,
        'familiar': 0,
        'strong': 0,
        'mastered': 0,
        'reviewsToday': 0,
        'accuracyLast7Days': 0,
        'currentStreak': 0,
      },
    }).toEntity();

    expect(data.isLibraryEmpty, isTrue);
  });

  test('requires todayReview and stats', () {
    expect(
      () => DashboardModel.fromJson({'weakestWords': []}),
      throwsFormatException,
    );
  });

  test('requires weakestWords to be a list', () {
    expect(
      () => DashboardModel.fromJson({
        'todayReview': {
          'due': 0,
          'newWords': 0,
          'needAttention': 0,
          'becomingStrong': 0,
        },
        'weakestWords': null,
        'stats': {
          'totalWords': 0,
          'new': 0,
          'learning': 0,
          'familiar': 0,
          'strong': 0,
          'mastered': 0,
          'reviewsToday': 0,
          'accuracyLast7Days': 0,
          'currentStreak': 0,
        },
      }),
      throwsFormatException,
    );
  });
}
