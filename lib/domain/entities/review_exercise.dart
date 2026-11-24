class ReviewExercise {
  const ReviewExercise({
    required this.id,
    required this.type,
    required this.question,
    required this.options,
    required this.correctAnswer,
    this.explanation,
  });

  final String id;
  final String type;
  final String question;
  final List<String> options;
  final String correctAnswer;
  final String? explanation;
}

class ReviewExerciseSet {
  const ReviewExerciseSet({
    required this.wordId,
    required this.word,
    required this.exercises,
  });

  final String wordId;
  final String word;
  final List<ReviewExercise> exercises;

  ReviewExercise? get firstExercise =>
      exercises.isEmpty ? null : exercises.first;
}
