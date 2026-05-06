// lib/features/promotion/data/models/promotion_model.dart

import '../../domain/entities/promotion_entity.dart';

class PromotionModel extends PromotionEntity {
  final int targetCount;
  final DateTime? broadcastSentAt;

  const PromotionModel({
    required super.id,
    required super.title,
    super.description,
    required super.productIds,
    required super.startDate,
    required super.endDate,
    required super.channels,
    required super.status,
    required super.createdAt,
    super.discountPercentage,
    this.targetCount = 0,
    this.broadcastSentAt,
  });

  factory PromotionModel.fromJson(Map<String, dynamic> json) {
    final sentAt = json['broadcast_sent_at'] != null
        ? DateTime.tryParse(json['broadcast_sent_at'] as String)
        : null;
    final createdAt = json['created_at'] != null
        ? DateTime.tryParse(json['created_at'] as String) ?? DateTime.now()
        : DateTime.now();
    final anchor = sentAt ?? createdAt;
    final startDate = json['start_date'] != null
        ? DateTime.tryParse(json['start_date'] as String) ?? anchor
        : anchor;
    final endDate = json['end_date'] != null
        ? DateTime.tryParse(json['end_date'] as String) ??
              startDate.add(const Duration(days: 7))
        : startDate.add(const Duration(days: 7));

    return PromotionModel(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String?,
      productIds: List<String>.from((json['product_ids'] as List?) ?? []),
      startDate: startDate,
      endDate: endDate,
      channels: List<String>.from((json['channels'] as List?) ?? []),
      status: json['status'] as String? ?? 'draft',
      createdAt: createdAt,
      discountPercentage: (json['discount_percentage'] as num?)?.toDouble(),
      targetCount: json['target_count'] as int? ?? 0,
      broadcastSentAt: sentAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'product_ids': productIds,
    'start_date': startDate.toIso8601String(),
    'end_date': endDate.toIso8601String(),
    'channels': channels,
    'status': status,
    'created_at': createdAt.toIso8601String(),
    'target_count': targetCount,
    'broadcast_sent_at': broadcastSentAt?.toIso8601String(),
    'discount_percentage': discountPercentage,
  };

  static PromotionModel fromEntity(PromotionEntity e) {
    if (e is PromotionModel) return e;
    return PromotionModel(
      id: e.id,
      title: e.title,
      description: e.description,
      productIds: e.productIds,
      startDate: e.startDate,
      endDate: e.endDate,
      channels: e.channels,
      status: e.status,
      createdAt: e.createdAt,
      discountPercentage: e.discountPercentage,
    );
  }

  @override
  PromotionModel copyWith({
    String? id,
    String? title,
    String? description,
    List<String>? productIds,
    DateTime? startDate,
    DateTime? endDate,
    List<String>? channels,
    String? status,
    DateTime? createdAt,
    double? discountPercentage,
    bool clearDiscount = false,
    int? targetCount,
    DateTime? broadcastSentAt,
  }) {
    return PromotionModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      productIds: productIds ?? this.productIds,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      channels: channels ?? this.channels,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      discountPercentage: clearDiscount
          ? null
          : (discountPercentage ?? this.discountPercentage),
      targetCount: targetCount ?? this.targetCount,
      broadcastSentAt: broadcastSentAt ?? this.broadcastSentAt,
    );
  }
}
