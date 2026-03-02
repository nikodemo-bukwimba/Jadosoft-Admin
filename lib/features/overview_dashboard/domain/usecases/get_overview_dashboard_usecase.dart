import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../projections/overview_dashboard_projection.dart';
import '../providers/order_data_provider.dart';
import '../providers/project_data_provider.dart';
import '../../../../features/order/domain/entities/order_entity.dart';
import '../../../../features/project/domain/entities/project_entity.dart';

class GetOverviewDashboardUseCase {
  final OrderDataProvider _orderProvider;
  final ProjectDataProvider _projectProvider;

  GetOverviewDashboardUseCase({
    required OrderDataProvider orderProvider,
    required ProjectDataProvider projectProvider,
  })      : _orderProvider = orderProvider,
        _projectProvider = projectProvider;

  Future<Either<Failure, OverviewDashboardProjection>> call() async {
    final orderResult = await _orderProvider.getAll();
    if (orderResult.isLeft()) {
      return orderResult.fold((f) => Left(f), (_) => throw StateError('unreachable'));
    }
    final orderList = orderResult.getOrElse(() => throw StateError('unreachable'));
    final projectResult = await _projectProvider.getAll();
    if (projectResult.isLeft()) {
      return projectResult.fold((f) => Left(f), (_) => throw StateError('unreachable'));
    }
    final projectList = projectResult.getOrElse(() => throw StateError('unreachable'));

    final totalOrders = orderList.length;
    final totalProjects = projectList.length;
    final revenue = orderList.fold<double>(0.0, (s, e) => s + (e.totalAmount ?? 0.0));
    final projectsByStatus = <String, int>{};
    for (final e in projectList) {
      final key = e.status.toString();
      projectsByStatus[key] = (projectsByStatus[key] ?? 0) + 1;
    }

    return Right(OverviewDashboardProjection(
      totalOrders: totalOrders,
      totalProjects: totalProjects,
      revenue: revenue,
      projectsByStatus: projectsByStatus,
      generatedAt: DateTime.now(),
    ));
  }
}
