import '../../domain/entities/customer_entity.dart';

class CustomerModel extends CustomerEntity {
  const CustomerModel({
    required super.id,
    required super.businessName,
    required super.fullOfficeName,
    required super.ownerName,
    required super.officialPhone,
    required super.contactPerson,
    required super.contactPersonPhone,
    required super.officeAddress,
    required super.gpsLat,
    required super.gpsLng,
    required super.assignedOfficerId,
    required super.registrationDate,
  });

  factory CustomerModel.fromJson(Map<String, dynamic> json) {
    return CustomerModel(
      id: json['id'] as String,
      businessName: json['business_name'] as String,
      fullOfficeName: json['full_office_name'] as String?,
      ownerName: json['owner_name'] as String,
      officialPhone: json['official_phone'] as String,
      contactPerson: json['contact_person'] as String?,
      contactPersonPhone: json['contact_person_phone'] as String?,
      officeAddress: json['office_address'] as String?,
      gpsLat: (json['gps_lat'] as num?)?.toDouble(),
      gpsLng: (json['gps_lng'] as num?)?.toDouble(),
      assignedOfficerId: json['assigned_officer_id'] as String,
      registrationDate: DateTime.parse(json['registration_date'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
      'id': id,
      'business_name': businessName,
      'full_office_name': fullOfficeName,
      'owner_name': ownerName,
      'official_phone': officialPhone,
      'contact_person': contactPerson,
      'contact_person_phone': contactPersonPhone,
      'office_address': officeAddress,
      'gps_lat': gpsLat,
      'gps_lng': gpsLng,
      'assigned_officer_id': assignedOfficerId,
      'registration_date': registrationDate.toIso8601String(),
  };

  factory CustomerModel.fromEntity(CustomerEntity entity) {
    return CustomerModel(
      id: entity.id,
      businessName: entity.businessName,
      fullOfficeName: entity.fullOfficeName,
      ownerName: entity.ownerName,
      officialPhone: entity.officialPhone,
      contactPerson: entity.contactPerson,
      contactPersonPhone: entity.contactPersonPhone,
      officeAddress: entity.officeAddress,
      gpsLat: entity.gpsLat,
      gpsLng: entity.gpsLng,
      assignedOfficerId: entity.assignedOfficerId,
      registrationDate: entity.registrationDate,
    );
  }
}
