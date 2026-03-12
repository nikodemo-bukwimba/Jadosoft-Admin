import '../../domain/entities/visit_entity.dart';

abstract class VisitState {}

class VisitInitial extends VisitState {}
class VisitLoading extends VisitState {}

class VisitListLoaded extends VisitState {
  final List<VisitEntity> items;
  VisitListLoaded(this.items);
}

class VisitDetailLoaded extends VisitState {
  final VisitEntity item;
  VisitDetailLoaded(this.item);
}

class VisitOperationSuccess extends VisitState {
  final String message;
  final VisitEntity? updatedItem;
  VisitOperationSuccess(this.message, {this.updatedItem});
}

class VisitEmpty extends VisitState {}

class VisitFailure extends VisitState {
  final String message;
  VisitFailure(this.message);
}
