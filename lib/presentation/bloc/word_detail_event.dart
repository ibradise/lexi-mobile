import 'package:equatable/equatable.dart';

sealed class WordDetailEvent extends Equatable {
  const WordDetailEvent();

  @override
  List<Object?> get props => const [];
}

final class LoadWordDetail extends WordDetailEvent {
  const LoadWordDetail();
}

final class PollWordDetail extends WordDetailEvent {
  const PollWordDetail(this.attempt, this.generation);

  final int attempt;
  final int generation;

  @override
  List<Object?> get props => [attempt, generation];
}

final class RegenerateWordDetailAi extends WordDetailEvent {
  const RegenerateWordDetailAi();
}

final class DeleteWordDetail extends WordDetailEvent {
  const DeleteWordDetail();
}
