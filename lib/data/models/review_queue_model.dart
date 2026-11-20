import '../../domain/entities/learning_state.dart';
import '../../domain/entities/review_queue.dart';
import 'model_utils.dart';

class ReviewQueueItemModel {
  const ReviewQueueItemModel({
    required this.wordId,
    required this.word,
    required this.priority,
    required this.knowledgeScore,
    required this.status,
    required this.aiReady,
  });

  factory ReviewQueueItemModel.fromJson(Map<String, dynamic> json) {
    return ReviewQueueItemModel(
      wordId: requireString(json, 'wordId'),
      word: requireString(json, 'word'),
      priority: optionalDouble(json['priority']),
      knowledgeScore: optionalDouble(json['knowledgeScore']),
      status: _parseStatus(json['status']),
      aiReady: json['aiReady'] == true,
    );
  }

  final String wordId;
  final String word;
  final double priority;
  final double knowledgeScore;
  final LearningStatus status;
  final bool aiReady;

  ReviewQueueItem toEntity() {
    return ReviewQueueItem(
      wordId: wordId,
      word: word,
      priority: priority,
      knowledgeScore: knowledgeScore,
      status: status,
      aiReady: aiReady,
    );
  }

  static LearningStatus _parseStatus(Object? value) {
    return switch (value) {
      'LEARNING' => LearningStatus.learning,
      'FAMILIAR' => LearningStatus.familiar,
      'STRONG' => LearningStatus.strong,
      'MASTERED' => LearningStatus.mastered,
      _ => LearningStatus.newWord,
    };
  }
}

class ReviewQueueModel {
  const ReviewQueueModel({
    required this.totalDue,
    required this.newWords,
    required this.reviewWords,
    required this.queue,
  });

  factory ReviewQueueModel.fromJson(Map<String, dynamic> json) {
    final queueValue = json['queue'];

    if (queueValue is! List) {
      throw const FormatException('Missing review queue.');
    }

    return ReviewQueueModel(
      totalDue: optionalInt(json['totalDue']),
      newWords: optionalInt(json['newWords']),
      reviewWords: optionalInt(json['reviewWords']),
      queue: [
        for (final item in queueValue)
          if (item is Map<String, dynamic>) ReviewQueueItemModel.fromJson(item),
      ],
    );
  }

  final int totalDue;
  final int newWords;
  final int reviewWords;
  final List<ReviewQueueItemModel> queue;

  ReviewQueue toEntity() {
    return ReviewQueue(
      totalDue: totalDue,
      newWords: newWords,
      reviewWords: reviewWords,
      queue: [for (final item in queue) item.toEntity()],
    );
  }
}
