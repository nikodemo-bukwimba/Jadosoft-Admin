import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/notification_entity.dart';
import '../repositories/notification_repository.dart';

class CreateNotificationParams {
  final String recipientId;
  final String recipientType;
  final String channel;
  final String content;
  final String? templateId;

  const CreateNotificationParams({
    required this.recipientId,
    required this.recipientType,
    required this.channel,
    required this.content,
    this.templateId,
  });
}

class CreateNotificationUseCase implements UseCase<NotificationEntity, CreateNotificationParams> {
  final NotificationRepository repository;
  CreateNotificationUseCase(this.repository);

  @override
  Future<Either<Failure, NotificationEntity>> call(CreateNotificationParams p) async {
    // -- Validation gate --
    if (p.recipientId.trim().isEmpty) {
      return const Left(ValidationFailure('Recipient is required'));
    }
    if (p.recipientType.trim().isEmpty) {
      return const Left(ValidationFailure('Recipient type is required'));
    }
    if (p.channel.trim().isEmpty) {
      return const Left(ValidationFailure('Channel is required'));
    }
    if (p.content.trim().isEmpty) {
      return const Left(ValidationFailure('Content is required'));
    }

    return repository.create(
      NotificationEntity(
        id: '',
        recipientId: p.recipientId.trim(),
        recipientType: p.recipientType.trim(),
        channel: p.channel.trim(),
        content: p.content.trim(),
        templateId: p.templateId?.trim(),
        status: '',
        sentAt: DateTime.now(),
        deliveredAt: DateTime.now(),
        failureReason: '',
        createdAt: DateTime.now(),
      ),
    );
  }
}
