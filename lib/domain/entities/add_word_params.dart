class AddWordParams {
  const AddWordParams({
    required this.word,
    this.context,
    this.sourceTitle,
    this.sourceUrl,
  });

  final String word;
  final String? context;
  final String? sourceTitle;
  final String? sourceUrl;
}
