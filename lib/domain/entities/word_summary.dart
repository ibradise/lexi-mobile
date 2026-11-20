import 'learning_state.dart';

class WordSummary {
  const WordSummary({
    required this.id,
    required this.word,
    required this.difficulty,
    required this.aiReady,
    this.partOfSpeech,
    this.pronunciation,
    this.sourceContext,
    this.sourceUrl,
    this.sourceTitle,
    this.dateAdded,
    this.learningState,
  });

  final String id;
  final String word;
  final int difficulty;
  final bool aiReady;
  final String? partOfSpeech;
  final String? pronunciation;
  final String? sourceContext;
  final String? sourceUrl;
  final String? sourceTitle;
  final DateTime? dateAdded;
  final LearningState? learningState;
}
