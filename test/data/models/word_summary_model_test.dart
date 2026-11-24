import 'package:flutter_test/flutter_test.dart';
import 'package:lexi_mobile/data/models/word_summary_model.dart';
import 'package:lexi_mobile/domain/entities/learning_state.dart';

void main() {
  group('WordSummaryModel', () {
    test('maps a ready library item with learning state', () {
      final model = WordSummaryModel.fromJson(const {
        'id': 'word-1',
        'word': 'lexicon',
        'partOfSpeech': 'noun',
        'pronunciation': '/ˈleksɪkɒn/',
        'difficulty': 4,
        'sourceContext': 'A sentence.',
        'sourceUrl': 'https://example.com',
        'sourceTitle': 'Example',
        'dateAdded': '2026-11-14T09:15:00.000Z',
        'aiReady': true,
        'learningState': {
          'status': 'FAMILIAR',
          'knowledgeScore': 0.55,
          'easeFactor': 2.5,
          'intervalDays': 2,
          'repetitions': 3,
          'nextReviewAt': null,
          'lastReviewedAt': null,
        },
      });

      final entity = model.toEntity();

      expect(entity.id, 'word-1');
      expect(entity.word, 'lexicon');
      expect(entity.partOfSpeech, 'noun');
      expect(entity.difficulty, 4);
      expect(entity.aiReady, isTrue);
      expect(entity.dateAdded, isNotNull);
      expect(entity.learningState?.status, LearningStatus.familiar);
      expect(entity.learningState?.knowledgeScore, 0.55);
    });

    test('derives pending AI from a null aiModel', () {
      final model = WordSummaryModel.fromJson(const {
        'id': 'word-1',
        'word': 'lexicon',
        'aiModel': null,
      });

      expect(model.aiReady, isFalse);
      expect(model.toEntity().difficulty, 3);
      expect(model.toEntity().learningState, isNull);
    });

    test('throws when required fields are missing', () {
      expect(
        () => WordSummaryModel.fromJson(const {'word': 'lexicon'}),
        throwsFormatException,
      );
    });
  });
}
