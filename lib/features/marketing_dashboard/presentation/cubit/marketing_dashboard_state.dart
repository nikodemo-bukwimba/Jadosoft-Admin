import 'package:equatable/equatable.dart';
import '../../domain/projections/marketing_dashboard_projection.dart';

abstract class MarketingDashboardState extends Equatable {
  const MarketingDashboardState();
  @override
  List<Object?> get props => [];
}

class MarketingDashboardInitial extends MarketingDashboardState {}

class MarketingDashboardLoading extends MarketingDashboardState {}

class MarketingDashboardLoaded extends MarketingDashboardState {
  final MarketingDashboardProjection projection;
  const MarketingDashboardLoaded(this.projection);

  @override
  List<Object?> get props => [projection];
}

class MarketingDashboardError extends MarketingDashboardState {
  final String message;
  const MarketingDashboardError(this.message);

  @override
  List<Object?> get props => [message];
}
