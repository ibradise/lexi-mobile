import '../../domain/entities/ai_content.dart';
import 'model_utils.dart';

class WordMeaningModel {
  const WordMeaningModel({required this.meaning, required this.isPrimary});

  factory WordMeaningModel.fromJson(Map<String, dynamic> json) {
    return WordMeaningModel(
      meaning: requireString(json, 'meaning'),
      isPrimary: json['isPrimary'] == true,
    );
  }

  final String meaning;
  final bool isPrimary;

  WordMeaning toEntity() {
    return WordMeaning(meaning: meaning, isPrimary: isPrimary);
  }
}

class WordExampleModel {
  const WordExampleModel({required this.sentence, this.context});

  factory WordExampleModel.fromJson(Map<String, dynamic> json) {
    return WordExampleModel(
      sentence: requireString(json, 'sentence'),
      context: optionalString(json['context']),
    );
  }

  final String sentence;
  final String? context;

  WordExample toEntity() {
    return WordExample(sentence: sentence, context: context);
  }
}

class AiContentModel {
  const AiContentModel({
    required this.meanings,
    required this.examples,
    required this.synonyms,
    required this.antonyms,
    required this.difficulty,
    this.pronunciation,
  });

  factory AiContentModel.fromJson(Map<String, dynamic> json) {
    final meaningsValue = json['meanings'];
    final examplesValue = json['examples'];

    return AiContentModel(
      meanings: meaningsValue is List
          ? [
              for (final item in meaningsValue)
                if (item is Map<String, dynamic>)
                  WordMeaningModel.fromJson(item),
            ]
          : const [],
      examples: examplesValue is List
          ? [
              for (final item in examplesValue)
                if (item is Map<String, dynamic>)
                  WordExampleModel.fromJson(item),
            ]
          : const [],
      synonyms: stringList(json['synonyms']),
      antonyms: stringList(json['antonyms']),
      pronunciation: optionalString(json['pronunciation']),
      difficulty: optionalInt(json['difficulty'], fallback: 3),
    );
  }

  final List<WordMeaningModel> meanings;
  final List<WordExampleModel> examples;
  final List<String> synonyms;
  final List<String> antonyms;
  final String? pronunciation;
  final int difficulty;

  AiContent toEntity() {
    return AiContent(
      meanings: [for (final meaning in meanings) meaning.toEntity()],
      examples: [for (final example in examples) example.toEntity()],
      synonyms: synonyms,
      antonyms: antonyms,
      pronunciation: pronunciation,
      difficulty: difficulty,
    );
  }
}
