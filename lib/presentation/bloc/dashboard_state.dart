import 'package:equatable/equatable.dart';

import '../../core/error/app_failure.dart';
import '../../domain/entities/dashboard_data.dart';

class DashboardState extends Equatable {
  const DashboardState({this.data, this.isLoading = false, this.failure});

  final DashboardData? data;
  final bool isLoading;
  final AppFailure? failure;

  bool get isLibraryEmpty => data?.isLibraryEmpty ?? false;

  DashboardState copyWith({
    DashboardData? data,
    bool? isLoading,
    AppFailure? failure,
    bool clearFailure = false,
  }) {
    return DashboardState(
      data: data ?? this.data,
      isLoading: isLoading ?? this.isLoading,
      failure: clearFailure ? null : failure ?? this.failure,
    );
  }

  @override
  List<Object?> get props => [data, isLoading, failure];
}
