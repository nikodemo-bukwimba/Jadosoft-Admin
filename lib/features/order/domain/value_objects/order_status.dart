import 'package:flutter/material.dart';

enum OrderStatus {
  draft,
  confirmed,
  shipped,
  delivered,
  cancelled,
}

extension OrderStatusX on OrderStatus {
  static const Map<OrderStatus, Set<OrderStatus>> _transitions = {
    OrderStatus.draft:     {OrderStatus.confirmed, OrderStatus.cancelled},
    OrderStatus.confirmed: {OrderStatus.shipped, OrderStatus.cancelled},
    OrderStatus.shipped:   {OrderStatus.delivered},
    OrderStatus.delivered: {},
    OrderStatus.cancelled: {},
  };

  static const OrderStatus initial = OrderStatus.draft;

  bool canTransitionTo(OrderStatus target) =>
      _transitions[this]?.contains(target) ?? false;

  String get displayName => switch (this) {
    OrderStatus.draft     => 'Draft',
    OrderStatus.confirmed => 'Confirmed',
    OrderStatus.shipped   => 'Shipped',
    OrderStatus.delivered => 'Delivered',
    OrderStatus.cancelled => 'Cancelled',
  };

  Color get color => switch (this) {
    OrderStatus.draft     => Colors.grey,
    OrderStatus.confirmed => Colors.blue,
    OrderStatus.shipped   => Colors.orange,
    OrderStatus.delivered => Colors.green,
    OrderStatus.cancelled => Colors.red,
  };

  static OrderStatus fromString(String? value) =>
      OrderStatus.values.firstWhere(
        (e) => e.name == value,
        orElse: () => OrderStatus.draft,
      );
}