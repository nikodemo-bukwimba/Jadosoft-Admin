// dashboard_state.dart
abstract class DashboardState {}

class DashboardInitial extends DashboardState {}
class DashboardLoading extends DashboardState {}
class DashboardReady   extends DashboardState {}
class DashboardError   extends DashboardState {
  final String message;
  DashboardError(this.message);
}
