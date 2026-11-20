import '../../domain/entities/review_exercise.dart';
import 'model_utils.dart';

class ReviewExerciseModel {
  const ReviewExerciseModel({
    required this.id,
    required this.type,
    required this.question,
    required this.options,
    required this.correctAnswer,
    this.explanation,
  });

  factory ReviewExerciseModel.fromJson(Map<String, dynamic> json) {
    final options = stringList(json['options']);

    if (options.isEmpty) {
      throw const FormatException('Exercise has no answer options.');
    }

    return ReviewExerciseModel(
      id: requireString(json, 'id'),
      type: requireString(json, 'type'),
      question: requireString(json, 'question'),
      options: options,
      correctAnswer: requireString(json, 'correctAnswer'),
      explanation: optionalString(json['explanation']),
    );
  }

  final String id;
  final String type;
  final String question;
  final List<String> options;
  final String correctAnswer;
  final String? explanation;

  ReviewExercise toEntity() {
    return ReviewExercise(
      id: id,
      type: type,
      question: question,
      options: options,
      correctAnswer: correctAnswer,
      explanation: explanation,
    );
  }
}

class ReviewExerciseSetModel {
  const ReviewExerciseSetModel({
    required this.wordId,
    required this.word,
    required this.exercises,
  });

  factory ReviewExerciseSetModel.fromJson(Map<String, dynamic> json) {
    final exercisesValue = json['exercises'];

    if (exercisesValue is! List) {
      throw const FormatException('Missing exercises.');
    }

    return ReviewExerciseSetModel(
      wordId: requireString(json, 'wordId'),
      word: requireString(json, 'word'),
      exercises: [
        for (final item in exercisesValue)
          if (item is Map<String, dynamic>) ReviewExerciseModel.fromJson(item),
      ],
    );
  }

  final String wordId;
  final String word;
  final List<ReviewExerciseModel> exercises;

  ReviewExerciseSet toEntity() {
    return ReviewExerciseSet(
      wordId: wordId,
      word: word,
      exercises: [for (final exercise in exercises) exercise.toEntity()],
    );
  }
}
