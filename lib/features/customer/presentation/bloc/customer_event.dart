import '../../domain/entities/customer_entity.dart';
import '../../domain/usecases/create_customer_usecase.dart';

abstract class CustomerEvent {}

class CustomerLoadAllRequested extends CustomerEvent {}

class CustomerLoadOneRequested extends CustomerEvent {
  final String id;
  CustomerLoadOneRequested(this.id);
}

class CustomerCreateRequested extends CustomerEvent {
  final CreateCustomerParams params;
  CustomerCreateRequested(this.params);
}

class CustomerUpdateRequested extends CustomerEvent {
  final CustomerEntity entity;
  CustomerUpdateRequested(this.entity);
}

class CustomerDeleteRequested extends CustomerEvent {
  final String id;
  CustomerDeleteRequested(this.id);
}

class CustomerFormReset extends CustomerEvent {}
