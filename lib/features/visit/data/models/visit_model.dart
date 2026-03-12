import '../../domain/entities/visit_entity.dart';

class VisitModel extends VisitEntity {
  const VisitModel({
    required super.id,
    required super.customerId,
    required super.officerId,
    required super.visitDate,
    super.businessName,
    super.ownerPhone,
    super.contactPersonPhone,
    super.businessPhone,
    super.notes,
    super.gpsLat,
    super.gpsLng,
    super.imageUrls,
    super.documentUrls,
    super.promotedProductIds,
    super.discussionSummary,
    required super.status,
    required super.createdAt,
  });

  factory VisitModel.fromJson(Map<String, dynamic> json) {
    return VisitModel(
      id: json['id'] as String,
      customerId: json['customer_id'] as String,
      officerId: json['officer_id'] as String,
      visitDate: DateTime.parse(json['visit_date'] as String),
      businessName: json['business_name'] as String?,
      ownerPhone: json['owner_phone'] as String?,
      contactPersonPhone: json['contact_person_phone'] as String?,
      businessPhone: json['business_phone'] as String?,
      notes: json['notes'] as String?,
      gpsLat: (json['gps_lat'] as num?)?.toDouble(),
      gpsLng: (json['gps_lng'] as num?)?.toDouble(),
      imageUrls: json['image_urls'] != null
          ? List<String>.from(json['image_urls'] as List)
          : null,
      documentUrls: json['document_urls'] != null
          ? List<String>.from(json['document_urls'] as List)
          : null,
      promotedProductIds: json['promoted_product_ids'] != null
          ? List<String>.from(json['promoted_product_ids'] as List)
          : null,
      discussionSummary: json['discussion_summary'] as String?,
      status: json['status'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'customer_id': customerId,
    'officer_id': officerId,
    'visit_date': visitDate.toIso8601String(),
    'business_name': businessName,
    'owner_phone': ownerPhone,
    'contact_person_phone': contactPersonPhone,
    'business_phone': businessPhone,
    'notes': notes,
    'gps_lat': gpsLat,
    'gps_lng': gpsLng,
    'image_urls': imageUrls,
    'document_urls': documentUrls,
    'promoted_product_ids': promotedProductIds,
    'discussion_summary': discussionSummary,
    'status': status,
    'created_at': createdAt.toIso8601String(),
  };

  factory VisitModel.fromEntity(VisitEntity entity) {
    return VisitModel(
      id: entity.id,
      customerId: entity.customerId,
      officerId: entity.officerId,
      visitDate: entity.visitDate,
      businessName: entity.businessName,
      ownerPhone: entity.ownerPhone,
      contactPersonPhone: entity.contactPersonPhone,
      businessPhone: entity.businessPhone,
      notes: entity.notes,
      gpsLat: entity.gpsLat,
      gpsLng: entity.gpsLng,
      imageUrls: entity.imageUrls,
      documentUrls: entity.documentUrls,
      promotedProductIds: entity.promotedProductIds,
      discussionSummary: entity.discussionSummary,
      status: entity.status,
      createdAt: entity.createdAt,
    );
  }
}