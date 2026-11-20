import '../../domain/entities/added_word.dart';

class AddedWordModel {
  const AddedWordModel({required this.id, required this.word});

  factory AddedWordModel.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final word = json['word'];

    if (id is! String || word is! String) {
      throw const FormatException('Added word is missing required fields.');
    }

    return AddedWordModel(id: id, word: word);
  }

  final String id;
  final String word;

  AddedWord toEntity() {
    return AddedWord(id: id, word: word);
  }
}
