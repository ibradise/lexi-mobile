import '../../domain/entities/word_detail.dart';
import 'ai_content_model.dart';
import 'model_utils.dart';
import 'review_entry_model.dart';
import 'word_summary_model.dart';

class WordDetailModel {
  const WordDetailModel({
    required this.summary,
    this.aiContent,
    this.aiModel,
    this.aiUpdatedAt,
    this.reviews = const [],
  });

  factory WordDetailModel.fromJson(Map<String, dynamic> json) {
    final aiDataValue = json['aiData'];
    final reviewsValue = json['reviews'];

    return WordDetailModel(
      summary: WordSummaryModel.fromJson(json),
      aiContent: aiDataValue is Map<String, dynamic>
          ? AiContentModel.fromJson(aiDataValue)
          : null,
      aiModel: optionalString(json['aiModel']),
      aiUpdatedAt: optionalDate(json['aiUpdatedAt']),
      reviews: reviewsValue is List
          ? [
              for (final item in reviewsValue)
                if (item is Map<String, dynamic>)
                  ReviewEntryModel.fromJson(item),
            ]
          : const [],
    );
  }

  final WordSummaryModel summary;
  final AiContentModel? aiContent;
  final String? aiModel;
  final DateTime? aiUpdatedAt;
  final List<ReviewEntryModel> reviews;

  WordDetail toEntity() {
    return WordDetail(
      summary: summary.toEntity(),
      aiContent: aiContent?.toEntity(),
      aiModel: aiModel,
      aiUpdatedAt: aiUpdatedAt,
      reviews: [for (final review in reviews) review.toEntity()],
    );
  }
}
