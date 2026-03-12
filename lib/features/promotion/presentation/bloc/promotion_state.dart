import '../../domain/entities/promotion_entity.dart';

abstract class PromotionState {}

class PromotionInitial extends PromotionState {}
class PromotionLoading extends PromotionState {}

class PromotionListLoaded extends PromotionState {
  final List<PromotionEntity> items;
  PromotionListLoaded(this.items);
}

class PromotionDetailLoaded extends PromotionState {
  final PromotionEntity item;
  PromotionDetailLoaded(this.item);
}

class PromotionOperationSuccess extends PromotionState {
  final String message;
  final PromotionEntity? updatedItem;
  PromotionOperationSuccess(this.message, {this.updatedItem});
}

class PromotionEmpty extends PromotionState {}

class PromotionFailure extends PromotionState {
  final String message;
  PromotionFailure(this.message);
}
