import 'package:equatable/equatable.dart';

import '../../core/error/app_failure.dart';
import '../../domain/entities/bulk_add_result.dart';
import '../../domain/entities/vocabulary_word.dart';

sealed class AddWordState extends Equatable {
  const AddWordState();

  @override
  List<Object?> get props => const [];
}

final class AddWordIdle extends AddWordState {
  const AddWordIdle();
}

final class AddWordSubmitting extends AddWordState {
  const AddWordSubmitting({required this.isBulk});

  final bool isBulk;

  @override
  List<Object?> get props => [isBulk];
}

final class AddWordSingleSuccess extends AddWordState {
  const AddWordSingleSuccess(this.word);

  final VocabularyWord word;

  @override
  List<Object?> get props => [word.id, word.word, word.aiReady];
}

final class AddWordBulkSuccess extends AddWordState {
  const AddWordBulkSuccess(this.result);

  final BulkAddResult result;

  @override
  List<Object?> get props => [
    for (final word in result.added) [word.id, word.word],
    result.duplicates,
    result.invalid,
  ];
}

final class AddWordFailure extends AddWordState {
  const AddWordFailure(this.failure, {required this.isBulk});

  final AppFailure failure;
  final bool isBulk;

  @override
  List<Object?> get props => [failure, isBulk];
}
