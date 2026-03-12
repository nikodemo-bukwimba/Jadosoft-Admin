import 'package:equatable/equatable.dart';
import '../value_objects/visit_status.dart';

class VisitEntity extends Equatable {
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
  final String status;
  final DateTime createdAt;

  const VisitEntity({
    required this.id,
    required this.customerId,
    required this.officerId,
    required this.visitDate,
    this.businessName,
    this.ownerPhone,
    this.contactPersonPhone,
    this.businessPhone,
    this.notes,
    this.gpsLat,
    this.gpsLng,
    this.imageUrls,
    this.documentUrls,
    this.promotedProductIds,
    this.discussionSummary,
    required this.status,
    required this.createdAt,
  });

  VisitEntity copyWith({
    String? id,
    String? customerId,
    String? officerId,
    DateTime? visitDate,
    String? businessName,
    String? ownerPhone,
    String? contactPersonPhone,
    String? businessPhone,
    String? notes,
    double? gpsLat,
    double? gpsLng,
    List<String>? imageUrls,
    List<String>? documentUrls,
    List<String>? promotedProductIds,
    String? discussionSummary,
    String? status,
    DateTime? createdAt,
  }) {
    return VisitEntity(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      officerId: officerId ?? this.officerId,
      visitDate: visitDate ?? this.visitDate,
      businessName: businessName ?? this.businessName,
      ownerPhone: ownerPhone ?? this.ownerPhone,
      contactPersonPhone: contactPersonPhone ?? this.contactPersonPhone,
      businessPhone: businessPhone ?? this.businessPhone,
      notes: notes ?? this.notes,
      gpsLat: gpsLat ?? this.gpsLat,
      gpsLng: gpsLng ?? this.gpsLng,
      imageUrls: imageUrls ?? this.imageUrls,
      documentUrls: documentUrls ?? this.documentUrls,
      promotedProductIds: promotedProductIds ?? this.promotedProductIds,
      discussionSummary: discussionSummary ?? this.discussionSummary,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [id, customerId, officerId, visitDate, businessName, ownerPhone, contactPersonPhone, businessPhone, notes, gpsLat, gpsLng, imageUrls, documentUrls, promotedProductIds, discussionSummary, status, createdAt];
}
