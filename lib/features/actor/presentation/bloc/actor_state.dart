import '../../domain/entities/actor_entity.dart';

abstract class ActorState {}

class ActorInitial          extends ActorState {}
class ActorLoading           extends ActorState {}

class ActorListLoaded extends ActorState {
  final List<ActorEntity> items;
  ActorListLoaded(this.items);
}

class ActorDetailLoaded extends ActorState {
  final ActorEntity item;
  ActorDetailLoaded(this.item);
}

class ActorOperationSuccess extends ActorState {
  final String message;
  ActorOperationSuccess(this.message);
}

class ActorEmpty extends ActorState {}

class ActorFailure extends ActorState {
  final String message;
  ActorFailure(this.message);
}
