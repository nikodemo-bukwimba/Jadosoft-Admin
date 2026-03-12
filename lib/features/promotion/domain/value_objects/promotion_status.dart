import 'package:flutter/material.dart';

enum PromotionStatus {
  draft,
  active,
  ended,
  cancelled,
}

extension PromotionStatusX on PromotionStatus {
  static const Map<PromotionStatus, Set<PromotionStatus>> _transitions = {
    PromotionStatus.draft:     {PromotionStatus.active, PromotionStatus.cancelled},
    PromotionStatus.active:    {PromotionStatus.ended, PromotionStatus.cancelled},
    PromotionStatus.ended:     {},
    PromotionStatus.cancelled: {},
  };

  static const PromotionStatus initial = PromotionStatus.draft;

  bool canTransitionTo(PromotionStatus target) =>
      _transitions[this]?.contains(target) ?? false;

  String get displayName => switch (this) {
    PromotionStatus.draft     => 'Draft',
    PromotionStatus.active    => 'Active',
    PromotionStatus.ended     => 'Ended',
    PromotionStatus.cancelled => 'Cancelled',
  };

  Color get color => switch (this) {
    PromotionStatus.draft     => Colors.grey,
    PromotionStatus.active    => Colors.green,
    PromotionStatus.ended     => Colors.blue,
    PromotionStatus.cancelled => Colors.red,
  };

  static PromotionStatus fromString(String? value) =>
      PromotionStatus.values.firstWhere(
        (e) => e.name == value,
        orElse: () => PromotionStatus.draft,
      );
}