import 'package:equatable/equatable.dart';

sealed class DashboardEvent extends Equatable {
  const DashboardEvent();

  @override
  List<Object?> get props => const [];
}

final class LoadDashboard extends DashboardEvent {
  const LoadDashboard();
}
