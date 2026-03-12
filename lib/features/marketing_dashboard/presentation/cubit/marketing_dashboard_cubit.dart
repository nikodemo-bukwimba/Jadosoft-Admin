import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/get_marketing_dashboard_usecase.dart';
import 'marketing_dashboard_state.dart';

class MarketingDashboardCubit extends Cubit<MarketingDashboardState> {
  final GetMarketingDashboardUseCase _getProjection;

  MarketingDashboardCubit({required GetMarketingDashboardUseCase getProjection})
      : _getProjection = getProjection,
        super(MarketingDashboardInitial());

  Future<void> load() async {
    emit(MarketingDashboardLoading());
    final result = await _getProjection();
    result.fold(
      (failure) => emit(MarketingDashboardError(failure.toString())),
      (projection) => emit(MarketingDashboardLoaded(projection)),
    );
  }

  Future<void> refresh() => load();
}
