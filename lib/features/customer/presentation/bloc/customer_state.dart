import '../../domain/entities/customer_entity.dart';

abstract class CustomerState {}

class CustomerInitial          extends CustomerState {}
class CustomerLoading           extends CustomerState {}

class CustomerListLoaded extends CustomerState {
  final List<CustomerEntity> items;
  CustomerListLoaded(this.items);
}

class CustomerDetailLoaded extends CustomerState {
  final CustomerEntity item;
  CustomerDetailLoaded(this.item);
}

class CustomerOperationSuccess extends CustomerState {
  final String message;
  CustomerOperationSuccess(this.message);
}

class CustomerEmpty extends CustomerState {}

class CustomerFailure extends CustomerState {
  final String message;
  CustomerFailure(this.message);
}
