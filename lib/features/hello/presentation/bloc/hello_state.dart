import '../../domain/entities/h_e_l_l_o_entity.dart';

abstract class HelloState {}

class HelloInitial          extends HelloState {}
class HelloLoading           extends HelloState {}

class HelloListLoaded extends HelloState {
  final List<HelloEntity> items;
  HelloListLoaded(this.items);
}

class HelloDetailLoaded extends HelloState {
  final HelloEntity item;
  HelloDetailLoaded(this.item);
}

class HelloOperationSuccess extends HelloState {
  final String message;
  HelloOperationSuccess(this.message);
}

class HelloEmpty extends HelloState {}

class HelloFailure extends HelloState {
  final String message;
  HelloFailure(this.message);
}
