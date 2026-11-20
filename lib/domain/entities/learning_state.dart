enum LearningStatus {
  newWord('NEW', 'New'),
  learning('LEARNING', 'Learning'),
  familiar('FAMILIAR', 'Familiar'),
  strong('STRONG', 'Strong'),
  mastered('MASTERED', 'Mastered');

  const LearningStatus(this.wireValue, this.label);

  final String wireValue;
  final String label;
}

class LearningState {
  const LearningState({
    required this.status,
    required this.knowledgeScore,
    required this.easeFactor,
    required this.intervalDays,
    required this.repetitions,
    this.nextReviewAt,
    this.lastReviewedAt,
  });

  final LearningStatus status;
  final double knowledgeScore;
  final double easeFactor;
  final int intervalDays;
  final int repetitions;
  final DateTime? nextReviewAt;
  final DateTime? lastReviewedAt;
}
