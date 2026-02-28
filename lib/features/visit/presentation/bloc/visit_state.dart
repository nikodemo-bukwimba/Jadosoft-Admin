// visit_state.dart
// All states emitted by VisitBloc.

part of 'visit_bloc.dart';

abstract class VisitState {}

class VisitInitial          extends VisitState {}
class VisitLoading          extends VisitState {}
class VisitEmpty            extends VisitState {}

class VisitListLoaded extends VisitState {
  final List<CategoryEntity> items;
  final int? totalCount;

  VisitListLoaded(this.items, {this.totalCount});
}

class VisitDetailLoaded extends VisitState {
  final CategoryEntity item;
  VisitDetailLoaded(this.item);
}

class VisitOperationSuccess extends VisitState {
  final String message;
  final CategoryEntity? updatedItem;

  VisitOperationSuccess(this.message, {this.updatedItem});
}

class VisitFailure extends VisitState {
  final String message;
  VisitFailure(this.message);
}
