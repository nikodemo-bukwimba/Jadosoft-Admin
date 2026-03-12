import '../../domain/entities/officer_entity.dart';

abstract class OfficerState {}

class OfficerInitial extends OfficerState {}
class OfficerLoading extends OfficerState {}

class OfficerListLoaded extends OfficerState {
  final List<OfficerEntity> items;
  OfficerListLoaded(this.items);
}

class OfficerDetailLoaded extends OfficerState {
  final OfficerEntity item;
  OfficerDetailLoaded(this.item);
}

class OfficerOperationSuccess extends OfficerState {
  final String message;
  final OfficerEntity? updatedItem;
  OfficerOperationSuccess(this.message, {this.updatedItem});
}

class OfficerEmpty extends OfficerState {}

class OfficerFailure extends OfficerState {
  final String message;
  OfficerFailure(this.message);
}
