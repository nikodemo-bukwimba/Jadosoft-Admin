import 'package:equatable/equatable.dart';
import '../value_objects/promotion_status.dart';

class PromotionEntity extends Equatable {
  final String id;
  final String title;
  final String? description;
  final List<String> productIds;
  final DateTime startDate;
  final DateTime endDate;
  final List<String> channels;
  final String status;
  final DateTime createdAt;

  const PromotionEntity({
    required this.id,
    required this.title,
    this.description,
    required this.productIds,
    required this.startDate,
    required this.endDate,
    required this.channels,
    required this.status,
    required this.createdAt,
  });

  PromotionEntity copyWith({
    String? id,
    String? title,
    String? description,
    List<String>? productIds,
    DateTime? startDate,
    DateTime? endDate,
    List<String>? channels,
    String? status,
    DateTime? createdAt,
  }) {
    return PromotionEntity(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      productIds: productIds ?? this.productIds,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      channels: channels ?? this.channels,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [id, title, description, productIds, startDate, endDate, channels, status, createdAt];
}
