import 'package:equatable/equatable.dart';

class CustomerEntity extends Equatable {
  final String id;
  final String businessName;
  final String? fullOfficeName;
  final String ownerName;
  final String officialPhone;
  final String? contactPerson;
  final String? contactPersonPhone;
  final String? officeAddress;
  final double? gpsLat;
  final double? gpsLng;
  final String assignedOfficerId;
  final DateTime registrationDate;

  const CustomerEntity({
    required this.id,
    required this.businessName,
    this.fullOfficeName,
    required this.ownerName,
    required this.officialPhone,
    this.contactPerson,
    this.contactPersonPhone,
    this.officeAddress,
    this.gpsLat,
    this.gpsLng,
    required this.assignedOfficerId,
    required this.registrationDate,
  });

  CustomerEntity copyWith({
    String? id,
    String? businessName,
    String? fullOfficeName,
    String? ownerName,
    String? officialPhone,
    String? contactPerson,
    String? contactPersonPhone,
    String? officeAddress,
    double? gpsLat,
    double? gpsLng,
    String? assignedOfficerId,
    DateTime? registrationDate,
  }) {
    return CustomerEntity(
      id: id ?? this.id,
      businessName: businessName ?? this.businessName,
      fullOfficeName: fullOfficeName ?? this.fullOfficeName,
      ownerName: ownerName ?? this.ownerName,
      officialPhone: officialPhone ?? this.officialPhone,
      contactPerson: contactPerson ?? this.contactPerson,
      contactPersonPhone: contactPersonPhone ?? this.contactPersonPhone,
      officeAddress: officeAddress ?? this.officeAddress,
      gpsLat: gpsLat ?? this.gpsLat,
      gpsLng: gpsLng ?? this.gpsLng,
      assignedOfficerId: assignedOfficerId ?? this.assignedOfficerId,
      registrationDate: registrationDate ?? this.registrationDate,
    );
  }

  @override
  List<Object?> get props => [];
}
