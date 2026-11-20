import 'package:equatable/equatable.dart';

import '../../domain/entities/add_word_params.dart';

sealed class AddWordEvent extends Equatable {
  const AddWordEvent();

  @override
  List<Object?> get props => const [];
}

final class SubmitSingleWord extends AddWordEvent {
  const SubmitSingleWord(this.params);

  final AddWordParams params;

  @override
  List<Object?> get props => [
    params.word,
    params.context,
    params.sourceTitle,
    params.sourceUrl,
  ];
}

final class SubmitBulkWords extends AddWordEvent {
  const SubmitBulkWords(this.input);

  final String input;

  @override
  List<Object?> get props => [input];
}

final class ResetAddWordFlow extends AddWordEvent {
  const ResetAddWordFlow();
}
