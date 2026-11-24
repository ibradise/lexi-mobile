import 'package:flutter_test/flutter_test.dart';
import 'package:lexi_mobile/data/models/learning_state_model.dart';
import 'package:lexi_mobile/domain/entities/learning_state.dart';

void main() {
  group('LearningStateModel', () {
    test('maps a backend learning state', () {
      final model = LearningStateModel.fromJson(const {
        'status': 'LEARNING',
        'knowledgeScore': 0.42,
        'easeFactor': 2.5,
        'intervalDays': 3,
        'repetitions': 2,
        'nextReviewAt': '2026-11-21T09:15:00.000Z',
        'lastReviewedAt': '2026-11-18T09:15:00.000Z',
      });

      final entity = model.toEntity();

      expect(entity.status, LearningStatus.learning);
      expect(entity.knowledgeScore, 0.42);
      expect(entity.intervalDays, 3);
      expect(entity.repetitions, 2);
      expect(entity.nextReviewAt, isNotNull);
      expect(entity.lastReviewedAt, isNotNull);
    });

    test(
      'defaults unknown statuses to new and missing numbers to defaults',
      () {
        final model = LearningStateModel.fromJson(const {'status': 'UNKNOWN'});

        expect(model.status, LearningStatus.newWord);
        expect(model.knowledgeScore, 0);
        expect(model.easeFactor, 2.5);
        expect(model.intervalDays, 0);
        expect(model.repetitions, 0);
        expect(model.nextReviewAt, isNull);
      },
    );
  });
}
