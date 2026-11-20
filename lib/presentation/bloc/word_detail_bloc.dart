import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/error/app_failure.dart';
import '../../domain/entities/word_detail.dart';
import '../../domain/usecases/delete_word.dart';
import '../../domain/usecases/get_word_detail.dart';
import '../../domain/usecases/regenerate_word_ai.dart';
import 'word_detail_event.dart';
import 'word_detail_state.dart';

class WordDetailBloc extends Bloc<WordDetailEvent, WordDetailState> {
  WordDetailBloc(
    this._getWordDetail,
    this._regenerateWordAi,
    this._deleteWord, {
    required String wordId,
    List<Duration>? pollDelays,
  }) : _wordId = wordId,
       _pollDelays =
           pollDelays ??
           const [
             Duration(seconds: 3),
             Duration(seconds: 6),
             Duration(seconds: 12),
             Duration(seconds: 20),
             Duration(seconds: 30),
           ],
       super(WordDetailState(wordId: wordId)) {
    on<LoadWordDetail>(_onLoad);
    on<PollWordDetail>(_onPoll);
    on<RegenerateWordDetailAi>(_onRegenerate);
    on<DeleteWordDetail>(_onDelete);
  }

  final String _wordId;
  final GetWordDetail _getWordDetail;
  final RegenerateWordAi _regenerateWordAi;
  final DeleteWord _deleteWord;
  final List<Duration> _pollDelays;

  Timer? _pollTimer;
  int _pollAttempt = 0;
  int _pollGeneration = 0;

  @override
  Future<void> close() {
    _pollTimer?.cancel();
    return super.close();
  }

  Future<void> _onLoad(
    LoadWordDetail event,
    Emitter<WordDetailState> emit,
  ) async {
    _cancelPoll();
    _pollAttempt = 0;
    _pollGeneration += 1;

    emit(
      state.copyWith(
        status: WordDetailStatus.loading,
        clearFailure: true,
        clearActionFailure: true,
        isRegenerating: false,
        isDeleting: false,
        pollExhausted: false,
      ),
    );

    try {
      final detail = await _getWordDetail(_wordId);
      if (isClosed) {
        return;
      }
      _emitDetail(detail, emit);
    } on AppFailure catch (failure) {
      if (isClosed) {
        return;
      }
      _emitFailure(failure, emit);
    }
  }

  Future<void> _onPoll(
    PollWordDetail event,
    Emitter<WordDetailState> emit,
  ) async {
    if (event.generation != _pollGeneration ||
        event.attempt != _pollAttempt ||
        state.status != WordDetailStatus.pending) {
      return;
    }

    try {
      final detail = await _getWordDetail(_wordId);
      if (isClosed || event.generation != _pollGeneration) {
        return;
      }
      if (detail.aiReady) {
        _cancelPoll();
        _pollAttempt = 0;
        emit(
          state.copyWith(
            detail: detail,
            status: WordDetailStatus.ready,
            clearFailure: true,
            clearActionFailure: true,
            pollExhausted: false,
          ),
        );
        return;
      }

      _pollAttempt += 1;
      emit(state.copyWith(detail: detail));
      _schedulePoll(emit);
    } on AppFailure {
      if (isClosed || event.generation != _pollGeneration) {
        return;
      }
      _pollAttempt += 1;
      _schedulePoll(emit);
    }
  }

  Future<void> _onRegenerate(
    RegenerateWordDetailAi event,
    Emitter<WordDetailState> emit,
  ) async {
    if (state.isBusy) {
      return;
    }

    _cancelPoll();
    _pollAttempt = 0;
    _pollGeneration += 1;

    emit(
      state.copyWith(
        isRegenerating: true,
        clearActionFailure: true,
        pollExhausted: false,
      ),
    );

    try {
      final detail = await _regenerateWordAi(_wordId);
      if (isClosed) {
        return;
      }
      _emitDetail(detail, emit);
    } on AppFailure catch (failure) {
      if (isClosed) {
        return;
      }
      _emitActionFailure(failure, emit);
    }
  }

  Future<void> _onDelete(
    DeleteWordDetail event,
    Emitter<WordDetailState> emit,
  ) async {
    if (state.isBusy) {
      return;
    }

    _cancelPoll();
    _pollGeneration += 1;

    emit(state.copyWith(isDeleting: true, clearActionFailure: true));

    try {
      await _deleteWord(_wordId);
      if (isClosed) {
        return;
      }
      emit(
        state.copyWith(
          status: WordDetailStatus.deleted,
          isDeleting: false,
          clearFailure: true,
          clearActionFailure: true,
          pollExhausted: false,
        ),
      );
    } on AppFailure catch (failure) {
      if (isClosed) {
        return;
      }
      if (failure is NotFoundFailure) {
        _emitFailure(failure, emit);
        return;
      }
      _emitActionFailure(failure, emit);
    }
  }

  void _emitDetail(WordDetail detail, Emitter<WordDetailState> emit) {
    final ready = detail.aiReady;
    final status = ready ? WordDetailStatus.ready : WordDetailStatus.pending;

    emit(
      state.copyWith(
        detail: detail,
        status: status,
        clearFailure: true,
        clearActionFailure: true,
        isRegenerating: false,
        isDeleting: false,
        pollExhausted: false,
      ),
    );

    if (!ready) {
      _schedulePoll(emit);
    }
  }

  void _emitFailure(AppFailure failure, Emitter<WordDetailState> emit) {
    _cancelPoll();
    emit(
      state.copyWith(
        status: failure is NotFoundFailure
            ? WordDetailStatus.notFound
            : WordDetailStatus.error,
        failure: failure,
        isRegenerating: false,
        isDeleting: false,
        pollExhausted: false,
      ),
    );
  }

  void _emitActionFailure(AppFailure failure, Emitter<WordDetailState> emit) {
    emit(
      state.copyWith(
        actionFailure: failure,
        isRegenerating: false,
        isDeleting: false,
      ),
    );

    if (state.status == WordDetailStatus.pending) {
      _schedulePoll(emit);
    }
  }

  void _schedulePoll(Emitter<WordDetailState> emit) {
    if (isClosed) {
      return;
    }
    if (_pollAttempt >= _pollDelays.length) {
      emit(state.copyWith(pollExhausted: true));
      return;
    }

    _pollTimer?.cancel();
    final attempt = _pollAttempt;
    final generation = _pollGeneration;
    _pollTimer = Timer(_pollDelays[attempt], () {
      if (!isClosed) {
        add(PollWordDetail(attempt, generation));
      }
    });
  }

  void _cancelPoll() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }
}
