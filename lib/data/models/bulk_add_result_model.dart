import '../../domain/entities/bulk_add_result.dart';
import 'added_word_model.dart';

class BulkAddResultModel {
  const BulkAddResultModel({
    required this.added,
    required this.duplicates,
    required this.invalid,
  });

  factory BulkAddResultModel.fromJson(Map<String, dynamic> json) {
    final addedValue = json['added'];

    if (addedValue is! List) {
      throw const FormatException('Bulk result is missing the added list.');
    }

    final added = addedValue.map((item) {
      if (item is! Map<String, dynamic>) {
        throw const FormatException('Bulk result contains an invalid word.');
      }
      return AddedWordModel.fromJson(item);
    }).toList();

    return BulkAddResultModel(
      added: added,
      duplicates: _parseStringList(json['duplicates'], 'duplicates'),
      invalid: _parseStringList(json['invalid'], 'invalid'),
    );
  }

  final List<AddedWordModel> added;
  final List<String> duplicates;
  final List<String> invalid;

  BulkAddResult toEntity() {
    return BulkAddResult(
      added: added.map((item) => item.toEntity()).toList(),
      duplicates: duplicates,
      invalid: invalid,
    );
  }

  static List<String> _parseStringList(Object? value, String field) {
    if (value is! List) {
      throw FormatException('Bulk result is missing the $field list.');
    }

    return value.map((item) => item.toString()).toList();
  }
}
