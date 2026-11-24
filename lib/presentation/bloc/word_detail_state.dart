import 'package:equatable/equatable.dart';

import '../../core/error/app_failure.dart';
import '../../domain/entities/word_detail.dart';

enum WordDetailStatus { loading, ready, pending, notFound, error, deleted }

class WordDetailState extends Equatable {
  const WordDetailState({
    required this.wordId,
    this.status = WordDetailStatus.loading,
    this.detail,
    this.failure,
    this.actionFailure,
    this.isRegenerating = false,
    this.isDeleting = false,
    this.pollExhausted = false,
  });

  final String wordId;
  final WordDetailStatus status;
  final WordDetail? detail;
  final AppFailure? failure;
  final AppFailure? actionFailure;
  final bool isRegenerating;
  final bool isDeleting;
  final bool pollExhausted;

  bool get isBusy => isRegenerating || isDeleting;

  WordDetailState copyWith({
    WordDetailStatus? status,
    WordDetail? detail,
    AppFailure? failure,
    bool clearFailure = false,
    AppFailure? actionFailure,
    bool clearActionFailure = false,
    bool? isRegenerating,
    bool? isDeleting,
    bool? pollExhausted,
  }) {
    return WordDetailState(
      wordId: wordId,
      status: status ?? this.status,
      detail: detail ?? this.detail,
      failure: clearFailure ? null : failure ?? this.failure,
      actionFailure: clearActionFailure
          ? null
          : actionFailure ?? this.actionFailure,
      isRegenerating: isRegenerating ?? this.isRegenerating,
      isDeleting: isDeleting ?? this.isDeleting,
      pollExhausted: pollExhausted ?? this.pollExhausted,
    );
  }

  @override
  List<Object?> get props => [
    wordId,
    status,
    detail?.summary.id,
    detail?.summary.word,
    detail?.summary.aiReady,
    detail?.aiModel,
    failure,
    actionFailure,
    isRegenerating,
    isDeleting,
    pollExhausted,
  ];
}
