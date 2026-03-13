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
      id: json['id']?.toString() ?? '',
      customerId: json['customer_id']?.toString() ?? '',
      officerId: json['officer_id']?.toString() ?? '',
      visitDate: json['visit_date'] != null
          ? DateTime.parse(json['visit_date'].toString())
          : DateTime.now(),
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
      status: json['status'] as String? ?? 'pending',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'].toString())
          : DateTime.now(),
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

  factory VisitModel.fromEntity(VisitEntity e) => VisitModel(
    id: e.id,
    customerId: e.customerId,
    officerId: e.officerId,
    visitDate: e.visitDate,
    businessName: e.businessName,
    ownerPhone: e.ownerPhone,
    contactPersonPhone: e.contactPersonPhone,
    businessPhone: e.businessPhone,
    notes: e.notes,
    gpsLat: e.gpsLat,
    gpsLng: e.gpsLng,
    imageUrls: e.imageUrls,
    documentUrls: e.documentUrls,
    promotedProductIds: e.promotedProductIds,
    discussionSummary: e.discussionSummary,
    status: e.status,
    createdAt: e.createdAt,
  );
}
