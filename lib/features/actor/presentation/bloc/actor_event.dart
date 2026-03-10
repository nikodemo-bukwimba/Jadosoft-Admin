import '../../domain/entities/actor_entity.dart';
import '../../domain/usecases/create_actor_usecase.dart';

abstract class ActorEvent {}

class ActorLoadAllRequested extends ActorEvent {}

class ActorLoadOneRequested extends ActorEvent {
  final String id;
  ActorLoadOneRequested(this.id);
}

class ActorCreateRequested extends ActorEvent {
  final CreateActorParams params;
  ActorCreateRequested(this.params);
}

class ActorUpdateRequested extends ActorEvent {
  final ActorEntity entity;
  ActorUpdateRequested(this.entity);
}

class ActorDeleteRequested extends ActorEvent {
  final String id;
  ActorDeleteRequested(this.id);
}

class ActorFormReset extends ActorEvent {}
