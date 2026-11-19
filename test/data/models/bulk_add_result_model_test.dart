import 'package:flutter_test/flutter_test.dart';
import 'package:lexi_mobile/data/models/bulk_add_result_model.dart';

void main() {
  group('BulkAddResultModel', () {
    test('maps added, duplicate, and invalid entries', () {
      final model = BulkAddResultModel.fromJson(const {
        'added': [
          {'id': 'word-1', 'word': 'lexicon', 'status': 'PENDING'},
          {'id': 'word-2', 'word': 'syntax', 'status': 'PENDING'},
        ],
        'duplicates': ['semantics'],
        'invalid': ['a-very-long-token'],
      });

      expect(model.added, hasLength(2));
      expect(model.added.first.word, 'lexicon');
      expect(model.duplicates, ['semantics']);
      expect(model.invalid, ['a-very-long-token']);

      final entity = model.toEntity();
      expect(entity.added.first.id, 'word-1');
      expect(entity.added.first.word, 'lexicon');
      expect(entity.duplicates, ['semantics']);
      expect(entity.invalid, ['a-very-long-token']);
    });

    test('keeps non-string invalid entries displayable', () {
      final model = BulkAddResultModel.fromJson(const {
        'added': [],
        'duplicates': [],
        'invalid': [42],
      });

      expect(model.invalid, ['42']);
    });

    test('throws when the added list is missing', () {
      expect(
        () => BulkAddResultModel.fromJson(const {
          'duplicates': [],
          'invalid': [],
        }),
        throwsFormatException,
      );
    });
  });
}
