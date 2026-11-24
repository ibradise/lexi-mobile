import '../../domain/entities/paginated_result.dart';
import '../../domain/entities/review_entry.dart';
import '../../domain/entities/review_history_item.dart';
import 'model_utils.dart';

class ReviewHistoryItemModel {
  const ReviewHistoryItemModel({
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

  factory ReviewHistoryItemModel.fromJson(Map<String, dynamic> json) {
    final wordValue = json['word'];

    if (wordValue is! Map<String, dynamic>) {
      throw const FormatException('Missing review history word.');
    }

    return ReviewHistoryItemModel(
      id: requireString(json, 'id'),
      wordId: requireString(json, 'wordId'),
      word: requireString(wordValue, 'word'),
      exerciseType: requireString(json, 'exerciseType'),
      result: _parseResult(json['result']),
      responseTimeMs: json['responseTimeMs'] is num
          ? (json['responseTimeMs'] as num).toInt()
          : null,
      hintUsed: json['hintUsed'] == true,
      userAnswer: optionalString(json['userAnswer']),
      correctAnswer: optionalString(json['correctAnswer']),
      createdAt: optionalDate(json['createdAt']),
    );
  }

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

  ReviewHistoryItem toEntity() {
    return ReviewHistoryItem(
      id: id,
      wordId: wordId,
      word: word,
      exerciseType: exerciseType,
      result: result,
      responseTimeMs: responseTimeMs,
      hintUsed: hintUsed,
      userAnswer: userAnswer,
      correctAnswer: correctAnswer,
      createdAt: createdAt,
    );
  }

  static ReviewResult _parseResult(Object? value) {
    return switch (value) {
      'CORRECT' => ReviewResult.correct,
      'INCORRECT' => ReviewResult.incorrect,
      'PARTIAL' => ReviewResult.partial,
      _ => ReviewResult.skipped,
    };
  }
}

class ReviewHistoryPageModel {
  const ReviewHistoryPageModel({
    required this.items,
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
  });

  final List<ReviewHistoryItemModel> items;
  final int page;
  final int limit;
  final int total;
  final int totalPages;

  PaginatedResult<ReviewHistoryItem> toEntity() {
    return PaginatedResult(
      items: [for (final item in items) item.toEntity()],
      page: page,
      limit: limit,
      total: total,
      totalPages: totalPages,
    );
  }
}
