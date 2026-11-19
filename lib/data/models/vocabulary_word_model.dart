import '../../domain/entities/vocabulary_word.dart';

class VocabularyWordModel {
  const VocabularyWordModel({
    required this.id,
    required this.word,
    required this.aiReady,
  });

  factory VocabularyWordModel.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final word = json['word'];

    if (id is! String || word is! String) {
      throw const FormatException(
        'Vocabulary word is missing required fields.',
      );
    }

    final aiReady = json['aiReady'];
    final aiModel = json['aiModel'];

    return VocabularyWordModel(
      id: id,
      word: word,
      aiReady: aiReady is bool ? aiReady : aiModel != null,
    );
  }

  final String id;
  final String word;
  final bool aiReady;

  VocabularyWord toEntity() {
    return VocabularyWord(id: id, word: word, aiReady: aiReady);
  }
}
