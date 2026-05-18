// notification_bloc.dart
// ─────────────────────────────────────────────────────────────
// Only handles operations the backend actually supports:
//   LoadAll (with filters), LoadOne, Retry.
//
// Create / Update / Delete events are removed because
// NotificationController has no such endpoints.
// ─────────────────────────────────────────────────────────────

import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/services/notification_domain_service.dart';
import '../../domain/usecases/get_all_notification_usecase.dart';
import '../../domain/usecases/get_notification_usecase.dart';
import '../../domain/value_objects/notification_status.dart';
import 'notification_event.dart';
import 'notification_state.dart';

class NotificationBloc extends Bloc<NotificationEvent, NotificationState> {
  final GetAllNotificationUseCase getAllUseCase;
  final GetNotificationUseCase getUseCase;
  final NotificationDomainService domainService;

  NotificationBloc({
    required this.getAllUseCase,
    required this.getUseCase,
    required this.domainService,
  }) : super(NotificationInitial()) {
    on<NotificationLoadAllRequested>(_onLoadAll);
    on<NotificationLoadOneRequested>(_onLoadOne);
    on<NotificationRetryRequested>(_onRetry);
    on<NotificationFilterChanged>(_onFilterChanged);
    on<NotificationFormReset>((_, emit) => emit(NotificationInitial()));
  }

  Future<void> _onLoadAll(
    NotificationLoadAllRequested event,
    Emitter<NotificationState> emit,
  ) async {
    emit(NotificationLoading());
    final result = await getAllUseCase(
      GetAllNotificationParams(
        status: event.status,
        channel: event.channel,
        perPage: event.perPage,
        page: event.page,
      ),
    );
    result.fold(
      (f) => emit(NotificationFailure(f.message)),
      (items) => items.isEmpty
          ? emit(NotificationEmpty())
          : emit(
              NotificationListLoaded(
                items,
                statusFilter: event.status,
                channelFilter: event.channel,
              ),
            ),
    );
  }

  Future<void> _onLoadOne(
    NotificationLoadOneRequested event,
    Emitter<NotificationState> emit,
  ) async {
    emit(NotificationLoading());
    final result = await getUseCase(GetNotificationParams(id: event.id));
    result.fold(
      (f) => emit(NotificationFailure(f.message)),
      (item) => emit(NotificationDetailLoaded(item)),
    );
  }

  Future<void> _onRetry(
    NotificationRetryRequested event,
    Emitter<NotificationState> emit,
  ) async {
    emit(NotificationLoading());
    final result = await domainService.transition(
      id: event.id,
      targetStatus: NotificationStatus.queued,
    );
    result.fold(
      (f) => emit(NotificationFailure(f.message)),
      (entity) => emit(
        NotificationOperationSuccess(
          'Delivery re-queued successfully.',
          updatedItem: entity,
        ),
      ),
    );
  }

  Future<void> _onFilterChanged(
    NotificationFilterChanged event,
    Emitter<NotificationState> emit,
  ) async {
    emit(NotificationLoading());
    final result = await getAllUseCase(
      GetAllNotificationParams(status: event.status, channel: event.channel),
    );
    result.fold(
      (f) => emit(NotificationFailure(f.message)),
      (items) => items.isEmpty
          ? emit(NotificationEmpty())
          : emit(
              NotificationListLoaded(
                items,
                statusFilter: event.status,
                channelFilter: event.channel,
              ),
            ),
    );
  }
}
