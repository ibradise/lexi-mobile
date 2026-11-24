import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lexi_mobile/core/error/app_failure.dart';
import 'package:lexi_mobile/domain/entities/learning_state.dart';
import 'package:lexi_mobile/domain/entities/review_queue.dart';
import 'package:lexi_mobile/domain/usecases/get_today_review.dart';
import 'package:lexi_mobile/presentation/bloc/review_queue_bloc.dart';
import 'package:lexi_mobile/presentation/bloc/review_queue_event.dart';
import 'package:lexi_mobile/presentation/bloc/review_queue_state.dart';
import 'package:mocktail/mocktail.dart';

class MockGetTodayReview extends Mock implements GetTodayReview {}

void main() {
  late MockGetTodayReview getTodayReview;

  const queue = ReviewQueue(
    totalDue: 1,
    newWords: 0,
    reviewWords: 1,
    queue: [
      ReviewQueueItem(
        wordId: 'word-1',
        word: 'lexicon',
        priority: 0.8,
        knowledgeScore: 0.3,
        status: LearningStatus.learning,
        aiReady: true,
      ),
    ],
  );

  setUp(() {
    getTodayReview = MockGetTodayReview();
  });

  blocTest<ReviewQueueBloc, ReviewQueueState>(
    'loads the review queue',
    build: () {
      when(() => getTodayReview()).thenAnswer((_) async => queue);
      return ReviewQueueBloc(getTodayReview);
    },
    act: (bloc) => bloc.add(const LoadReviewQueue()),
    expect: () => [
      isA<ReviewQueueState>().having(
        (state) => state.isLoading,
        'loading',
        true,
      ),
      isA<ReviewQueueState>()
          .having((state) => state.isLoading, 'loading', false)
          .having((state) => state.queue?.totalDue, 'total due', 1)
          .having((state) => state.queue?.queue.single.word, 'word', 'lexicon'),
    ],
  );

  blocTest<ReviewQueueBloc, ReviewQueueState>(
    'emits a failure when the queue cannot load',
    build: () {
      when(() => getTodayReview()).thenThrow(const NetworkFailure());
      return ReviewQueueBloc(getTodayReview);
    },
    act: (bloc) => bloc.add(const LoadReviewQueue()),
    expect: () => [
      isA<ReviewQueueState>().having(
        (state) => state.isLoading,
        'loading',
        true,
      ),
      isA<ReviewQueueState>()
          .having((state) => state.isLoading, 'loading', false)
          .having((state) => state.failure, 'failure', isA<NetworkFailure>()),
    ],
  );

  blocTest<ReviewQueueBloc, ReviewQueueState>(
    'recognizes an empty queue',
    build: () {
      when(() => getTodayReview()).thenAnswer(
        (_) async => const ReviewQueue(
          totalDue: 0,
          newWords: 0,
          reviewWords: 0,
          queue: [],
        ),
      );
      return ReviewQueueBloc(getTodayReview);
    },
    act: (bloc) => bloc.add(const LoadReviewQueue()),
    skip: 1,
    expect: () => [
      isA<ReviewQueueState>().having((state) => state.isEmpty, 'empty', true),
    ],
  );
}
