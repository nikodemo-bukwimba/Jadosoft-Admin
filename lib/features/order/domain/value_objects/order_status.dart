import 'package:flutter/material.dart';

enum OrderStatus {
  draft,
  submitted,
  approved,
  rejected,
  fulfilled,
}

extension OrderStatusX on OrderStatus {
  static const Map<OrderStatus, Set<OrderStatus>> _transitions = {
      OrderStatus.draft: {OrderStatus.submitted},
      OrderStatus.submitted: {OrderStatus.approved, OrderStatus.rejected},
      OrderStatus.approved: {OrderStatus.fulfilled},
      OrderStatus.rejected: {OrderStatus.draft},
      OrderStatus.fulfilled: {},
  };

  static const OrderStatus initial = OrderStatus.draft;

  bool canTransitionTo(OrderStatus target) =>
      _transitions[this]?.contains(target) ?? false;

  String get displayName => switch (this) {
      OrderStatus.draft  => 'Draft',
      OrderStatus.submitted  => 'Submitted',
      OrderStatus.approved  => 'Approved',
      OrderStatus.rejected  => 'Rejected',
      OrderStatus.fulfilled  => 'Fulfilled',
  };

  Color get color => switch (this) {
      OrderStatus.draft => Colors.grey,
      OrderStatus.submitted => Colors.blue,
      OrderStatus.approved => Colors.orange,
      OrderStatus.rejected => Colors.green,
      OrderStatus.fulfilled => Colors.red,
  };
}
