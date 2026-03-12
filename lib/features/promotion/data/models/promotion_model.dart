import '../../domain/entities/promotion_entity.dart';

class PromotionModel extends PromotionEntity {
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
  });

  factory PromotionModel.fromJson(Map<String, dynamic> json) {
    return PromotionModel(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      productIds: List<String>.from(json['product_ids'] as List),
      startDate: DateTime.parse(json['start_date'] as String),
      endDate: DateTime.parse(json['end_date'] as String),
      channels: List<String>.from(json['channels'] as List),
      status: json['status'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
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
  };

  factory PromotionModel.fromEntity(PromotionEntity entity) {
    return PromotionModel(
      id: entity.id,
      title: entity.title,
      description: entity.description,
      productIds: entity.productIds,
      startDate: entity.startDate,
      endDate: entity.endDate,
      channels: entity.channels,
      status: entity.status,
      createdAt: entity.createdAt,
    );
  }
}