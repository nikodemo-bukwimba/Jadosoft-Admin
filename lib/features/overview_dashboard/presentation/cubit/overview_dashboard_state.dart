import 'package:equatable/equatable.dart';
import '../../domain/projections/overview_dashboard_projection.dart';

abstract class OverviewDashboardState extends Equatable {
  const OverviewDashboardState();
  @override
  List<Object?> get props => [];
}

class OverviewDashboardInitial extends OverviewDashboardState {}

class OverviewDashboardLoading extends OverviewDashboardState {}

class OverviewDashboardLoaded extends OverviewDashboardState {
  final OverviewDashboardProjection projection;
  const OverviewDashboardLoaded(this.projection);

  @override
  List<Object?> get props => [projection];
}

class OverviewDashboardError extends OverviewDashboardState {
  final String message;
  const OverviewDashboardError(this.message);

  @override
  List<Object?> get props => [message];
}
