import 'package:equatable/equatable.dart';

/// Admin comment left during review or flag.
class VisitAdminComment {
  final String id;
  final String authorName;
  final String comment;
  final DateTime createdAt;
  const VisitAdminComment({required this.id, required this.authorName, required this.comment, required this.createdAt});
}

class VisitEntity extends Equatable {
  // ── Original Maishell fields (unchanged) ────────────────────
  final String id;
  final String customerId;
  final String officerId;
  final DateTime visitDate;
  final String? businessName;
  final String? ownerPhone;
  final String? contactPersonPhone;
  final String? businessPhone;
  final String? notes;
  final double? gpsLat;
  final double? gpsLng;
  final List<String>? imageUrls;
  final List<String>? documentUrls;
  final List<String>? promotedProductIds;
  final String? discussionSummary;
  final String status;        // pending | reviewed | flagged
  final DateTime createdAt;

  // ── Nexora extension fields ─────────────────────────────────
  final String? visitType;    // routine | follow_up | promotional | collection | urgent
  final String? objective;
  final String? outcome;
  final String? outcomeStatus; // positive | neutral | negative | follow_up_needed
  final int? durationMinutes;
  final String? customerName;  // denormalized from customer for display
  final String? officerName;   // denormalized from officer for display
  final String? flagReason;    // why admin flagged this visit
  final List<VisitAdminComment> adminComments;

  const VisitEntity({
    required this.id, required this.customerId, required this.officerId,
    required this.visitDate, this.businessName, this.ownerPhone,
    this.contactPersonPhone, this.businessPhone, this.notes,
    this.gpsLat, this.gpsLng, this.imageUrls, this.documentUrls,
    this.promotedProductIds, this.discussionSummary,
    required this.status, required this.createdAt,
    // Nexora extensions
    this.visitType, this.objective, this.outcome, this.outcomeStatus,
    this.durationMinutes, this.customerName, this.officerName,
    this.flagReason, this.adminComments = const [],
  });

  VisitEntity copyWith({
    String? id, String? customerId, String? officerId, DateTime? visitDate,
    String? businessName, String? ownerPhone, String? contactPersonPhone,
    String? businessPhone, String? notes, double? gpsLat, double? gpsLng,
    List<String>? imageUrls, List<String>? documentUrls,
    List<String>? promotedProductIds, String? discussionSummary,
    String? status, DateTime? createdAt,
    String? visitType, String? objective, String? outcome, String? outcomeStatus,
    int? durationMinutes, String? customerName, String? officerName,
    String? flagReason, List<VisitAdminComment>? adminComments,
  }) {
    return VisitEntity(
      id: id ?? this.id, customerId: customerId ?? this.customerId,
      officerId: officerId ?? this.officerId, visitDate: visitDate ?? this.visitDate,
      businessName: businessName ?? this.businessName, ownerPhone: ownerPhone ?? this.ownerPhone,
      contactPersonPhone: contactPersonPhone ?? this.contactPersonPhone,
      businessPhone: businessPhone ?? this.businessPhone, notes: notes ?? this.notes,
      gpsLat: gpsLat ?? this.gpsLat, gpsLng: gpsLng ?? this.gpsLng,
      imageUrls: imageUrls ?? this.imageUrls, documentUrls: documentUrls ?? this.documentUrls,
      promotedProductIds: promotedProductIds ?? this.promotedProductIds,
      discussionSummary: discussionSummary ?? this.discussionSummary,
      status: status ?? this.status, createdAt: createdAt ?? this.createdAt,
      visitType: visitType ?? this.visitType, objective: objective ?? this.objective,
      outcome: outcome ?? this.outcome, outcomeStatus: outcomeStatus ?? this.outcomeStatus,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      customerName: customerName ?? this.customerName, officerName: officerName ?? this.officerName,
      flagReason: flagReason ?? this.flagReason, adminComments: adminComments ?? this.adminComments,
    );
  }

  @override
  List<Object?> get props => [id, customerId, officerId, visitDate, businessName, status, createdAt, adminComments, flagReason];
}
