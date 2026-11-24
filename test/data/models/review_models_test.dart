import 'package:flutter_test/flutter_test.dart';
import 'package:lexi_mobile/data/models/review_exercise_model.dart';
import 'package:lexi_mobile/data/models/review_queue_model.dart';
import 'package:lexi_mobile/data/models/review_submission_result_model.dart';
import 'package:lexi_mobile/domain/entities/learning_state.dart';
import 'package:lexi_mobile/domain/entities/review_entry.dart';

void main() {
  group('ReviewQueueModel', () {
    test('maps queue counts and items', () {
      final model = ReviewQueueModel.fromJson(const {
        'totalDue': 3,
        'newWords': 1,
        'reviewWords': 2,
        'queue': [
          {
            'wordId': 'word-1',
            'word': 'lexicon',
            'priority': 0.9,
            'knowledgeScore': 0.2,
            'status': 'LEARNING',
            'aiReady': true,
          },
          {
            'wordId': 'word-2',
            'word': 'syntax',
            'priority': 0.4,
            'knowledgeScore': 0,
            'status': 'NEW',
            'aiReady': false,
          },
        ],
      });

      final entity = model.toEntity();

      expect(entity.totalDue, 3);
      expect(entity.newWords, 1);
      expect(entity.reviewWords, 2);
      expect(entity.queue.first.word, 'lexicon');
      expect(entity.queue.first.status, LearningStatus.learning);
      expect(entity.queue.first.aiReady, isTrue);
      expect(entity.queue.last.status, LearningStatus.newWord);
      expect(entity.queue.last.aiReady, isFalse);
    });

    test('throws when the queue is missing', () {
      expect(
        () => ReviewQueueModel.fromJson(const {'totalDue': 0}),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('ReviewExerciseSetModel', () {
    test('maps exercises and their options', () {
      final model = ReviewExerciseSetModel.fromJson(const {
        'wordId': 'word-1',
        'word': 'lexicon',
        'exercises': [
          {
            'id': 'word-1-ex-0',
            'type': 'MULTIPLE_CHOICE',
            'question': 'What does lexicon mean?',
            'options': ['vocabulary', 'flower'],
            'correctAnswer': 'vocabulary',
            'explanation': 'A lexicon is vocabulary.',
          },
        ],
      });

      final entity = model.toEntity();

      expect(entity.wordId, 'word-1');
      expect(entity.word, 'lexicon');
      expect(entity.exercises.single.options, ['vocabulary', 'flower']);
      expect(entity.exercises.single.correctAnswer, 'vocabulary');
      expect(entity.firstExercise, isNotNull);
    });

    test('throws when options are empty', () {
      expect(
        () => ReviewExerciseSetModel.fromJson(const {
          'wordId': 'word-1',
          'word': 'lexicon',
          'exercises': [
            {
              'id': 'word-1-ex-0',
              'type': 'MULTIPLE_CHOICE',
              'question': 'What does lexicon mean?',
              'options': [],
              'correctAnswer': 'vocabulary',
            },
          ],
        }),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('ReviewSubmissionResultModel', () {
    test('maps the review, learning state, and score breakdown', () {
      final model = ReviewSubmissionResultModel.fromJson(const {
        'review': {
          'id': 'review-1',
          'exerciseType': 'MULTIPLE_CHOICE',
          'result': 'CORRECT',
          'responseTimeMs': 2300,
          'userAnswer': 'vocabulary',
          'correctAnswer': 'vocabulary',
          'hintUsed': false,
        },
        'learningState': {
          'status': 'STRONG',
          'knowledgeScore': 0.68,
          'easeFactor': 2.5,
          'intervalDays': 1,
          'repetitions': 1,
        },
        'scoreBreakdown': {
          'accuracy': 1,
          'interval': 0.033,
          'responseTime': 0.77,
          'hint': 1,
          'repetition': 0.125,
        },
      });

      final entity = model.toEntity();

      expect(entity.review.result, ReviewResult.correct);
      expect(entity.review.correctAnswer, 'vocabulary');
      expect(entity.learningState.status, LearningStatus.strong);
      expect(entity.scoreBreakdown.accuracy, 1);
      expect(entity.scoreBreakdown.repetition, 0.125);
    });

    test('throws when the response is incomplete', () {
      expect(
        () => ReviewSubmissionResultModel.fromJson(const {
          'review': {'id': 'review-1'},
        }),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
