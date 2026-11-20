import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/error/app_failure.dart';
import '../../domain/usecases/add_word.dart';
import '../../domain/usecases/add_words.dart';
import 'add_word_event.dart';
import 'add_word_state.dart';

class AddWordBloc extends Bloc<AddWordEvent, AddWordState> {
  // on<EventType>(handler)
  AddWordBloc(this._addWord, this._addWords) : super(const AddWordIdle()) {
    on<SubmitSingleWord>(_onSubmitSingle);
    on<SubmitBulkWords>(_onSubmitBulk);
    on<ResetAddWordFlow>(_onReset);
  }

  final AddWord _addWord;
  final AddWords _addWords;

  Future<void> _onSubmitSingle(
    SubmitSingleWord event,
    Emitter<AddWordState> emit,
  ) async {
    if (state is AddWordSubmitting) {
      return;
    }

    emit(const AddWordSubmitting(isBulk: false));

    try {
      final word = await _addWord(event.params);
      emit(AddWordSingleSuccess(word));
    } on AppFailure catch (failure) {
      emit(AddWordFailure(failure, isBulk: false));
    }
  }

  Future<void> _onSubmitBulk(
    SubmitBulkWords event,
    Emitter<AddWordState> emit,
  ) async {
    if (state is AddWordSubmitting) {
      return;
    }

    emit(const AddWordSubmitting(isBulk: true));

    try {
      final result = await _addWords(event.input);
      emit(AddWordBulkSuccess(result));
    } on AppFailure catch (failure) {
      emit(AddWordFailure(failure, isBulk: true));
    }
  }

  void _onReset(ResetAddWordFlow event, Emitter<AddWordState> emit) {
    emit(const AddWordIdle());
  }
}
