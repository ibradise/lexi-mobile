import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/error/app_failure.dart';
import '../../domain/usecases/get_dashboard.dart';
import 'dashboard_event.dart';
import 'dashboard_state.dart';

class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  DashboardBloc(this._getDashboard) : super(const DashboardState()) {
    on<LoadDashboard>(_onLoad);
  }

  final GetDashboard _getDashboard;
  int _requestId = 0;

  Future<void> _onLoad(
    LoadDashboard event,
    Emitter<DashboardState> emit,
  ) async {
    final requestId = ++_requestId;
    emit(state.copyWith(isLoading: true, clearFailure: true));

    try {
      final data = await _getDashboard();
      if (requestId != _requestId) {
        return;
      }
      emit(state.copyWith(data: data, isLoading: false, clearFailure: true));
    } on AppFailure catch (failure) {
      if (requestId != _requestId) {
        return;
      }
      emit(state.copyWith(isLoading: false, failure: failure));
    }
  }
}
