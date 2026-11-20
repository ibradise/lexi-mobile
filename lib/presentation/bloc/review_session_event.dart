import 'package:equatable/equatable.dart';

sealed class ReviewSessionEvent extends Equatable {
  const ReviewSessionEvent();

  @override
  List<Object?> get props => const [];
}

final class StartReviewSession extends ReviewSessionEvent {
  const StartReviewSession();
}

final class SelectReviewAnswer extends ReviewSessionEvent {
  const SelectReviewAnswer(this.answer);

  final String answer;

  @override
  List<Object?> get props => [answer];
}

final class SubmitReviewAnswer extends ReviewSessionEvent {
  const SubmitReviewAnswer();
}

final class SkipReviewQuestion extends ReviewSessionEvent {
  const SkipReviewQuestion();
}

final class ContinueReviewSession extends ReviewSessionEvent {
  const ContinueReviewSession();
}

final class RetryReviewSession extends ReviewSessionEvent {
  const RetryReviewSession();
}
