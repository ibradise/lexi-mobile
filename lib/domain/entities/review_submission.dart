class ReviewSubmission {
  const ReviewSubmission({
    required this.wordId,
    required this.exerciseId,
    this.userAnswer,
    this.responseTimeMs,
    this.hintUsed = false,
    this.skipped = false,
    this.submissionId,
  });

  final String wordId;
  final String exerciseId;
  final String? userAnswer;
  final int? responseTimeMs;
  final bool hintUsed;
  final bool skipped;
  final String? submissionId;

  ReviewSubmission copyWith({
    String? exerciseId,
    String? userAnswer,
    int? responseTimeMs,
    bool? hintUsed,
    bool? skipped,
    String? submissionId,
  }) {
    return ReviewSubmission(
      wordId: wordId,
      exerciseId: exerciseId ?? this.exerciseId,
      userAnswer: userAnswer ?? this.userAnswer,
      responseTimeMs: responseTimeMs ?? this.responseTimeMs,
      hintUsed: hintUsed ?? this.hintUsed,
      skipped: skipped ?? this.skipped,
      submissionId: submissionId ?? this.submissionId,
    );
  }
}
