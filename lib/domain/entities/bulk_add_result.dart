import 'added_word.dart';

class BulkAddResult {
  const BulkAddResult({
    required this.added,
    required this.duplicates,
    required this.invalid,
  });

  final List<AddedWord> added;
  final List<String> duplicates;
  final List<String> invalid;
}
