import 'package:flutter_test/flutter_test.dart';
import 'package:lexi_mobile/data/models/vocabulary_word_model.dart';

void main() {
  group('VocabularyWordModel', () {
    test('maps a ready single-word response and derives aiReady', () {
      final model = VocabularyWordModel.fromJson(const {
        'id': 'word-1',
        'word': 'lexicon',
        'aiModel': 'gemini-3.5-flash',
        'aiData': {'meanings': []},
      });

      expect(model.aiReady, isTrue);
      expect(model.toEntity().id, 'word-1');
      expect(model.toEntity().word, 'lexicon');
      expect(model.toEntity().aiReady, isTrue);
    });

    test('maps a pending single-word response', () {
      final model = VocabularyWordModel.fromJson(const {
        'id': 'word-1',
        'word': 'lexicon',
        'aiModel': null,
        'aiData': null,
      });

      expect(model.aiReady, isFalse);
      expect(model.toEntity().aiReady, isFalse);
    });

    test('uses the explicit list aiReady field when present', () {
      final model = VocabularyWordModel.fromJson(const {
        'id': 'word-1',
        'word': 'lexicon',
        'aiReady': true,
      });

      expect(model.aiReady, isTrue);
    });

    test('throws when required fields are missing', () {
      expect(
        () => VocabularyWordModel.fromJson(const {'id': 'word-1'}),
        throwsFormatException,
      );
    });
  });
}
