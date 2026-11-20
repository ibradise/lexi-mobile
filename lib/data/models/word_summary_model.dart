import '../../domain/entities/word_summary.dart';
import 'learning_state_model.dart';
import 'model_utils.dart';

class WordSummaryModel {
  const WordSummaryModel({
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

  factory WordSummaryModel.fromJson(Map<String, dynamic> json) {
    final aiReady = json['aiReady'];
    final learningStateValue = json['learningState'];

    return WordSummaryModel(
      id: requireString(json, 'id'),
      word: requireString(json, 'word'),
      difficulty: optionalInt(json['difficulty'], fallback: 3),
      aiReady: aiReady is bool ? aiReady : json['aiModel'] != null,
      partOfSpeech: optionalString(json['partOfSpeech']),
      pronunciation: optionalString(json['pronunciation']),
      sourceContext: optionalString(json['sourceContext']),
      sourceUrl: optionalString(json['sourceUrl']),
      sourceTitle: optionalString(json['sourceTitle']),
      dateAdded: optionalDate(json['dateAdded']),
      learningState: learningStateValue is Map<String, dynamic>
          ? LearningStateModel.fromJson(learningStateValue)
          : null,
    );
  }

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
  final LearningStateModel? learningState;

  WordSummary toEntity() {
    return WordSummary(
      id: id,
      word: word,
      difficulty: difficulty,
      aiReady: aiReady,
      partOfSpeech: partOfSpeech,
      pronunciation: pronunciation,
      sourceContext: sourceContext,
      sourceUrl: sourceUrl,
      sourceTitle: sourceTitle,
      dateAdded: dateAdded,
      learningState: learningState?.toEntity(),
    );
  }
}
