// === FILE: lib/features/visit/data/models/visit_model.dart ===
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
    super.visitType,
    super.objective,
    super.outcome,
    super.outcomeStatus,
    super.durationMinutes,
    super.customerName,
    super.officerName,
    super.flagReason,
    super.adminComments,
  });

  factory VisitModel.fromJson(Map<String, dynamic> json) {
    final commentsList = <VisitAdminComment>[];
    final commentsJson = json['admin_comments'] as List<dynamic>?;
    if (commentsJson != null) {
      for (final c in commentsJson) {
        if (c is Map<String, dynamic>) {
          commentsList.add(
            VisitAdminComment(
              id: c['id']?.toString() ?? '',
              authorName: c['author_name'] as String? ?? 'Admin',
              comment: c['comment'] as String? ?? '',
              createdAt: c['created_at'] != null
                  ? DateTime.parse(c['created_at'].toString())
                  : DateTime.now(),
            ),
          );
        }
      }
    }

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
      gpsLat: _parseDouble(json['gps_lat']), // ← fixed
      gpsLng: _parseDouble(json['gps_lng']), // ← fixed
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
      visitType: json['visit_type'] as String?,
      objective: json['objective'] as String?,
      outcome: json['outcome'] as String?,
      outcomeStatus: json['outcome_status'] as String?,
      durationMinutes: _parseInt(json['duration_minutes']), // ← fixed
      customerName:
          json['customer_name'] as String? ?? json['business_name'] as String?,
      officerName: json['officer_name'] as String?,
      flagReason: json['flag_reason'] as String?,
      adminComments: commentsList,
    );
  }

  /// Safely parse any numeric-like value to double.
  /// Handles: double, int, String, null.
  static double? _parseDouble(dynamic v) {
    if (v == null) return null;
    if (v is double) return v;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v);
    return null;
  }

  /// Safely parse any numeric-like value to int.
  /// Handles: int, double, String, null.
  static int? _parseInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v);
    return null;
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
    'visit_type': visitType,
    'objective': objective,
    'outcome': outcome,
    'outcome_status': outcomeStatus,
    'duration_minutes': durationMinutes,
    'customer_name': customerName,
    'officer_name': officerName,
    'flag_reason': flagReason,
    'admin_comments': adminComments
        .map(
          (c) => {
            'id': c.id,
            'author_name': c.authorName,
            'comment': c.comment,
            'created_at': c.createdAt.toIso8601String(),
          },
        )
        .toList(),
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
    visitType: e.visitType,
    objective: e.objective,
    outcome: e.outcome,
    outcomeStatus: e.outcomeStatus,
    durationMinutes: e.durationMinutes,
    customerName: e.customerName,
    officerName: e.officerName,
    flagReason: e.flagReason,
    adminComments: e.adminComments,
  );
}
