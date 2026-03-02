import 'package:equatable/equatable.dart';

class OverviewDashboardProjection extends Equatable {
  final int totalOrders;
  final int totalProjects;
  final double revenue;
  final Map<String, int> projectsByStatus;
  final DateTime generatedAt;

  const OverviewDashboardProjection({
    required this.totalOrders,
    required this.totalProjects,
    required this.revenue,
    required this.projectsByStatus,
    required this.generatedAt,
  });

  @override
  List<Object?> get props => [totalOrders, totalProjects, revenue, projectsByStatus, generatedAt];
}
