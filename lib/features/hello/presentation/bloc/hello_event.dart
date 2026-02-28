import '../../domain/entities/h_e_l_l_o_entity.dart';
import '../../domain/usecases/create_hello_usecase.dart';

abstract class HelloEvent {}

class HelloLoadAllRequested extends HelloEvent {}

class HelloLoadOneRequested extends HelloEvent {
  final String id;
  HelloLoadOneRequested(this.id);
}

class HelloCreateRequested extends HelloEvent {
  final CreateHelloParams params;
  HelloCreateRequested(this.params);
}

class HelloUpdateRequested extends HelloEvent {
  final HelloEntity entity;
  HelloUpdateRequested(this.entity);
}

class HelloDeleteRequested extends HelloEvent {
  final String id;
  HelloDeleteRequested(this.id);
}

class HelloFormReset extends HelloEvent {}
