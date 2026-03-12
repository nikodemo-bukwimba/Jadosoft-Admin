import 'package:equatable/equatable.dart';
import '../../domain/projections/sales_dashboard_projection.dart';

abstract class SalesDashboardState extends Equatable {
  const SalesDashboardState();
  @override
  List<Object?> get props => [];
}

class SalesDashboardInitial extends SalesDashboardState {}

class SalesDashboardLoading extends SalesDashboardState {}

class SalesDashboardLoaded extends SalesDashboardState {
  final SalesDashboardProjection projection;
  const SalesDashboardLoaded(this.projection);

  @override
  List<Object?> get props => [projection];
}

class SalesDashboardError extends SalesDashboardState {
  final String message;
  const SalesDashboardError(this.message);

  @override
  List<Object?> get props => [message];
}
