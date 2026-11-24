import 'learning_state.dart';

class ReviewQueueItem {
  const ReviewQueueItem({
    required this.wordId,
    required this.word,
    required this.priority,
    required this.knowledgeScore,
    required this.status,
    required this.aiReady,
  });

  final String wordId;
  final String word;
  final double priority;
  final double knowledgeScore;
  final LearningStatus status;
  final bool aiReady;
}

class ReviewQueue {
  const ReviewQueue({
    required this.totalDue,
    required this.newWords,
    required this.reviewWords,
    required this.queue,
  });

  final int totalDue;
  final int newWords;
  final int reviewWords;
  final List<ReviewQueueItem> queue;

  bool get isEmpty => queue.isEmpty;
}
