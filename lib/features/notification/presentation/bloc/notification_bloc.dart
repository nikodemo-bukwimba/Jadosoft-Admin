import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/usecase/usecase.dart';
import '../../domain/services/notification_domain_service.dart';
import '../../domain/usecases/create_notification_usecase.dart';
import '../../domain/usecases/delete_notification_usecase.dart';
import '../../domain/usecases/get_notification_usecase.dart';
import '../../domain/usecases/get_all_notification_usecase.dart';
import '../../domain/usecases/update_notification_usecase.dart';
import '../../domain/value_objects/notification_status.dart';
import 'notification_event.dart';
import 'notification_state.dart';

class NotificationBloc extends Bloc<NotificationEvent, NotificationState> {
  final GetAllNotificationUseCase  getAllUseCase;
  final GetNotificationUseCase     getUseCase;
  final CreateNotificationUseCase  createUseCase;
  final UpdateNotificationUseCase  updateUseCase;
  final DeleteNotificationUseCase  deleteUseCase;
  final NotificationDomainService  domainService;

  NotificationBloc({
    required this.getAllUseCase,
    required this.getUseCase,
    required this.createUseCase,
    required this.updateUseCase,
    required this.deleteUseCase,
    required this.domainService,
  }) : super(NotificationInitial()) {
    on<NotificationLoadAllRequested>(_onLoadAll);
    on<NotificationLoadOneRequested>(_onLoadOne);
    on<NotificationCreateRequested>(_onCreate);
    on<NotificationUpdateRequested>(_onUpdate);
    on<NotificationDeleteRequested>(_onDelete);
    on<NotificationFormReset>((_, emit) => emit(NotificationInitial()));
    on<NotificationRetryRequested>(_onRetry);
  }

  Future<void> _onLoadAll(
      NotificationLoadAllRequested event, Emitter<NotificationState> emit) async {
    emit(NotificationLoading());
    final result = await getAllUseCase(NoParams());
    result.fold(
      (f) => emit(NotificationFailure(f.message)),
      (items) => items.isEmpty
          ? emit(NotificationEmpty())
          : emit(NotificationListLoaded(items)),
    );
  }

  Future<void> _onLoadOne(
      NotificationLoadOneRequested event, Emitter<NotificationState> emit) async {
    emit(NotificationLoading());
    final result = await getUseCase(GetNotificationParams(id: event.id));
    result.fold(
      (f) => emit(NotificationFailure(f.message)),
      (item) => emit(NotificationDetailLoaded(item)),
    );
  }

  Future<void> _onCreate(
      NotificationCreateRequested event, Emitter<NotificationState> emit) async {
    emit(NotificationLoading());
    final result = await createUseCase(event.params);
    result.fold(
      (f) => emit(NotificationFailure(f.message)),
      (_) => emit(NotificationOperationSuccess('Notification created successfully')),
    );
  }

  Future<void> _onUpdate(
      NotificationUpdateRequested event, Emitter<NotificationState> emit) async {
    emit(NotificationLoading());
    final result = await updateUseCase(UpdateNotificationParams(entity: event.entity));
    result.fold(
      (f) => emit(NotificationFailure(f.message)),
      (_) => emit(NotificationOperationSuccess('Notification updated successfully')),
    );
  }

  Future<void> _onDelete(
      NotificationDeleteRequested event, Emitter<NotificationState> emit) async {
    emit(NotificationLoading());
    final result = await deleteUseCase(DeleteNotificationParams(id: event.id));
    result.fold(
      (f) => emit(NotificationFailure(f.message)),
      (_) => emit(NotificationOperationSuccess('Notification deleted successfully')),
    );
  }

  Future<void> _onRetry(
      NotificationRetryRequested event, Emitter<NotificationState> emit) async {
    emit(NotificationLoading());
    final result = await domainService.transition(
      id: event.id,
      targetStatus: NotificationStatus.queued,
    );
    result.fold(
      (f) => emit(NotificationFailure(f.message)),
      (entity) => emit(NotificationOperationSuccess(
        'Retry Notification successful',
        updatedItem: entity,
      )),
    );
  }
}
