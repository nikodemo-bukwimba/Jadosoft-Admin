import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/promotion_entity.dart';
import '../events/promotion_domain_events.dart';

class PromotionWorkflowExecutor {
  final List<PromotionDomainEvent> _emittedEvents = [];

  List<PromotionDomainEvent> get emittedEvents => List.unmodifiable(_emittedEvents);

  void clearEvents() => _emittedEvents.clear();

  /// Executes the full workflow for the given entity.
  /// Steps run in order; on failure, completed steps are rolled back.
  Future<Either<Failure, PromotionEntity>> execute(PromotionEntity entity) async {
    _emittedEvents.clear();
    final completedSteps = <String>[];
    var current = entity;
    Either<Failure, PromotionEntity> result;

    // Step: Broadcast via SMS
    result = await _broadcastSms(current);
    if (result.isLeft()) {
      await _rollback(entity, completedSteps);
      return result;
    }
    current = result.getOrElse(() => current);
    completedSteps.add('broadcastSms');
    // Step: Broadcast via WhatsApp
    result = await _broadcastWhatsApp(current);
    if (result.isLeft()) {
      await _rollback(entity, completedSteps);
      return result;
    }
    current = result.getOrElse(() => current);
    completedSteps.add('broadcastWhatsApp');

    return Right(current);
  }

  /// Step: Broadcast via SMS
  Future<Either<Failure, PromotionEntity>> _broadcastSms(PromotionEntity entity) async {
    // -- HUMAN CUSTOMIZATION ZONE --
    // Implement: Broadcast via SMS
    // Return Right(entity) on success, Left(Failure) on failure.
    // -- END CUSTOMIZATION ZONE --
    return Right(entity);
  }
  /// Step: Broadcast via WhatsApp
  Future<Either<Failure, PromotionEntity>> _broadcastWhatsApp(PromotionEntity entity) async {
    // -- HUMAN CUSTOMIZATION ZONE --
    // Implement: Broadcast via WhatsApp
    // Return Right(entity) on success, Left(Failure) on failure.
    // -- END CUSTOMIZATION ZONE --
    return Right(entity);
  }

  Future<void> _rollback(PromotionEntity entity, List<String> completedSteps) async {
    for (final step in completedSteps.reversed) {
      switch (step) {
      case 'broadcastSms': break; // TODO: rollback Broadcast via SMS
      case 'broadcastWhatsApp': break; // TODO: rollback Broadcast via WhatsApp
      }
    }
  }

  void _emit(PromotionDomainEvent event) => _emittedEvents.add(event);
}
