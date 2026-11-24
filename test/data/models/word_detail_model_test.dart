import 'package:flutter_test/flutter_test.dart';
import 'package:lexi_mobile/data/models/word_detail_model.dart';
import 'package:lexi_mobile/domain/entities/review_entry.dart';

void main() {
  group('WordDetailModel', () {
    test('maps AI content and recent reviews', () {
      final model = WordDetailModel.fromJson(const {
        'id': 'word-1',
        'word': 'lexicon',
        'partOfSpeech': 'noun',
        'pronunciation': '/ˈleksɪkɒn/',
        'difficulty': 4,
        'dateAdded': '2026-11-14T09:15:00.000Z',
        'aiModel': 'gemini-3.5-flash',
        'aiUpdatedAt': '2026-11-14T09:15:08.000Z',
        'aiData': {
          'meanings': [
            {'meaning': 'the vocabulary of a language', 'isPrimary': true},
            {'meaning': 'a dictionary', 'isPrimary': false},
          ],
          'examples': [
            {
              'sentence': 'The linguist studied the lexicon.',
              'context': 'academic',
            },
          ],
          'synonyms': ['vocabulary'],
          'antonyms': ['silence'],
          'pronunciation': '/ˈleksɪkɒn/',
          'difficulty': 4,
        },
        'reviews': [
          {
            'id': 'review-1',
            'exerciseType': 'MULTIPLE_CHOICE',
            'result': 'CORRECT',
            'responseTimeMs': 2300,
            'hintUsed': false,
            'createdAt': '2026-11-14T09:20:00.000Z',
          },
        ],
      });

      final entity = model.toEntity();

      expect(entity.aiReady, isTrue);
      expect(entity.aiContent?.meanings.length, 2);
      expect(entity.aiContent?.meanings.first.isPrimary, isTrue);
      expect(entity.aiContent?.examples.single.context, 'academic');
      expect(entity.aiContent?.synonyms, ['vocabulary']);
      expect(entity.reviews.single.result, ReviewResult.correct);
      expect(entity.reviews.single.exerciseType, 'MULTIPLE_CHOICE');
    });

    test('maps pending AI content and defaults missing reviews', () {
      final model = WordDetailModel.fromJson(const {
        'id': 'word-1',
        'word': 'lexicon',
        'aiModel': null,
        'aiData': null,
      });

      final entity = model.toEntity();

      expect(entity.aiReady, isFalse);
      expect(entity.aiContent, isNull);
      expect(entity.reviews, isEmpty);
    });

    test('throws when the word summary is invalid', () {
      expect(
        () => WordDetailModel.fromJson(const {'aiModel': null}),
        throwsFormatException,
      );
    });
  });
}
