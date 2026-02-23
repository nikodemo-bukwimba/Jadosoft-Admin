// dashboard_bloc.dart
// Aggregates data from all feature BLoCs/use cases for the home screen.
// No business logic here — delegate to use cases.

import 'package:flutter_bloc/flutter_bloc.dart';
import 'dashboard_event.dart';
import 'dashboard_state.dart';

class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  DashboardBloc() : super(DashboardInitial()) {
    on<DashboardLoaded>(_onLoaded);
  }

  Future<void> _onLoaded(DashboardLoaded event, Emitter<DashboardState> emit) async {
    emit(DashboardLoading());
    // TODO: call use cases and aggregate results
    emit(DashboardReady());
  }
}
