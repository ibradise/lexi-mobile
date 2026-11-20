class WordMeaning {
  const WordMeaning({required this.meaning, required this.isPrimary});

  final String meaning;
  final bool isPrimary;
}

class WordExample {
  const WordExample({required this.sentence, this.context});

  final String sentence;
  final String? context;
}

class AiContent {
  const AiContent({
    required this.meanings,
    required this.examples,
    required this.synonyms,
    required this.antonyms,
    this.pronunciation,
    required this.difficulty,
  });

  final List<WordMeaning> meanings;
  final List<WordExample> examples;
  final List<String> synonyms;
  final List<String> antonyms;
  final String? pronunciation;
  final int difficulty;
}
