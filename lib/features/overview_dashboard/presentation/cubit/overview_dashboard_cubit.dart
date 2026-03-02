import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/get_overview_dashboard_usecase.dart';
import 'overview_dashboard_state.dart';

class OverviewDashboardCubit extends Cubit<OverviewDashboardState> {
  final GetOverviewDashboardUseCase _getProjection;

  OverviewDashboardCubit({required GetOverviewDashboardUseCase getProjection})
      : _getProjection = getProjection,
        super(OverviewDashboardInitial());

  Future<void> load() async {
    emit(OverviewDashboardLoading());
    final result = await _getProjection();
    result.fold(
      (failure) => emit(OverviewDashboardError(failure.toString())),
      (projection) => emit(OverviewDashboardLoaded(projection)),
    );
  }

  Future<void> refresh() => load();
}
