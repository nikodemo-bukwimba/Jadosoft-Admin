import '../../domain/entities/payment_entity.dart';
import '../../domain/usecases/create_payment_usecase.dart';

abstract class PaymentEvent {}

class PaymentLoadAllRequested extends PaymentEvent {}

class PaymentLoadOneRequested extends PaymentEvent {
  final String id;
  PaymentLoadOneRequested(this.id);
}

class PaymentCreateRequested extends PaymentEvent {
  final CreatePaymentParams params;
  PaymentCreateRequested(this.params);
}

class PaymentUpdateRequested extends PaymentEvent {
  final PaymentEntity entity;
  PaymentUpdateRequested(this.entity);
}

class PaymentDeleteRequested extends PaymentEvent {
  final String id;
  PaymentDeleteRequested(this.id);
}

class PaymentFormReset extends PaymentEvent {}
