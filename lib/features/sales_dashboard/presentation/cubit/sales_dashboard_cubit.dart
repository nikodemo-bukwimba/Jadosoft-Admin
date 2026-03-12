import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/get_sales_dashboard_usecase.dart';
import 'sales_dashboard_state.dart';

class SalesDashboardCubit extends Cubit<SalesDashboardState> {
  final GetSalesDashboardUseCase _getProjection;

  SalesDashboardCubit({required GetSalesDashboardUseCase getProjection})
      : _getProjection = getProjection,
        super(SalesDashboardInitial());

  Future<void> load() async {
    emit(SalesDashboardLoading());
    final result = await _getProjection();
    result.fold(
      (failure) => emit(SalesDashboardError(failure.toString())),
      (projection) => emit(SalesDashboardLoaded(projection)),
    );
  }

  Future<void> refresh() => load();
}
