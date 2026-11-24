import 'ai_content.dart';
import 'review_entry.dart';
import 'word_summary.dart';

class WordDetail {
  const WordDetail({
    required this.summary,
    this.aiContent,
    this.aiModel,
    this.aiUpdatedAt,
    this.reviews = const [],
  });

  final WordSummary summary;
  final AiContent? aiContent;
  final String? aiModel;
  final DateTime? aiUpdatedAt;
  final List<ReviewEntry> reviews;

  bool get aiReady => aiModel != null || summary.aiReady;
}
