import '../../domain/entities/payment_entity.dart';

abstract class PaymentState {}

class PaymentInitial          extends PaymentState {}
class PaymentLoading           extends PaymentState {}

class PaymentListLoaded extends PaymentState {
  final List<PaymentEntity> items;
  PaymentListLoaded(this.items);
}

class PaymentDetailLoaded extends PaymentState {
  final PaymentEntity item;
  PaymentDetailLoaded(this.item);
}

class PaymentOperationSuccess extends PaymentState {
  final String message;
  PaymentOperationSuccess(this.message);
}

class PaymentEmpty extends PaymentState {}

class PaymentFailure extends PaymentState {
  final String message;
  PaymentFailure(this.message);
}
