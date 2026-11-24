enum ReviewResult {
  correct('CORRECT', 'Correct'),
  incorrect('INCORRECT', 'Incorrect'),
  partial('PARTIAL', 'Partial'),
  skipped('SKIPPED', 'Skipped');

  const ReviewResult(this.wireValue, this.label);

  final String wireValue;
  final String label;
}

class ReviewEntry {
  const ReviewEntry({
    required this.id,
    required this.exerciseType,
    required this.result,
    this.responseTimeMs,
    this.hintUsed = false,
    this.userAnswer,
    this.correctAnswer,
    this.createdAt,
  });

  final String id;
  final String exerciseType;
  final ReviewResult result;
  final int? responseTimeMs;
  final bool hintUsed;
  final String? userAnswer;
  final String? correctAnswer;
  final DateTime? createdAt;
}
