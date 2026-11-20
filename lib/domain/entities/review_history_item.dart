import 'review_entry.dart';

class ReviewHistoryItem {
  const ReviewHistoryItem({
    required this.id,
    required this.wordId,
    required this.word,
    required this.exerciseType,
    required this.result,
    this.responseTimeMs,
    this.hintUsed = false,
    this.userAnswer,
    this.correctAnswer,
    this.createdAt,
  });

  final String id;
  final String wordId;
  final String word;
  final String exerciseType;
  final ReviewResult result;
  final int? responseTimeMs;
  final bool hintUsed;
  final String? userAnswer;
  final String? correctAnswer;
  final DateTime? createdAt;
}
