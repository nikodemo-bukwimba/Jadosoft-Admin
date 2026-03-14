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
    this.targetCount = 0,
    this.broadcastSentAt,
  });

  factory PromotionModel.fromJson(Map<String, dynamic> json) {
    return PromotionModel(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String?,
      productIds: List<String>.from(
          (json['product_ids'] as List?) ?? []),
      startDate: json['start_date'] != null
          ? DateTime.tryParse(json['start_date'] as String) ??
              DateTime.now()
          : DateTime.now(),
      endDate: json['end_date'] != null
          ? DateTime.tryParse(json['end_date'] as String) ??
              DateTime.now()
          : DateTime.now(),
      channels: List<String>.from(
          (json['channels'] as List?) ?? []),
      status: json['status'] as String? ?? 'draft',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String) ??
              DateTime.now()
          : DateTime.now(),
      targetCount: json['target_count'] as int? ?? 0,
      broadcastSentAt: json['broadcast_sent_at'] != null
          ? DateTime.tryParse(json['broadcast_sent_at'] as String)
          : null,
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
    );
  }
}