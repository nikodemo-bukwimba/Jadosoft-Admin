import '../../domain/entities/promotion_entity.dart';
import '../../domain/usecases/create_promotion_usecase.dart';

abstract class PromotionEvent {}

class PromotionLoadAllRequested extends PromotionEvent {}

class PromotionLoadOneRequested extends PromotionEvent {
  final String id;
  PromotionLoadOneRequested(this.id);
}

class PromotionCreateRequested extends PromotionEvent {
  final CreatePromotionParams params;
  PromotionCreateRequested(this.params);
}

class PromotionUpdateRequested extends PromotionEvent {
  final PromotionEntity entity;
  PromotionUpdateRequested(this.entity);
}

class PromotionDeleteRequested extends PromotionEvent {
  final String id;
  PromotionDeleteRequested(this.id);
}

class PromotionFormReset extends PromotionEvent {}

class PromotionActivateRequested extends PromotionEvent {
  final String id;
  PromotionActivateRequested(this.id);
}

class PromotionEndRequested extends PromotionEvent {
  final String id;
  PromotionEndRequested(this.id);
}

class PromotionCancelRequested extends PromotionEvent {
  final String id;
  PromotionCancelRequested(this.id);
}

class PromotionStatusOverridden extends PromotionEvent {
  final PromotionEntity entity;
  PromotionStatusOverridden(this.entity);
}
