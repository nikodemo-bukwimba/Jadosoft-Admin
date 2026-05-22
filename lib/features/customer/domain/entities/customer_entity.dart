import 'package:equatable/equatable.dart';

class CustomerContact extends Equatable {
  final String id;
  final String name;
  final String? role;
  final String? phone;
  final String? email;
  final String? whatsappNumber;
  final bool isPrimary;
  final DateTime? createdAt;

  const CustomerContact({
    required this.id,
    required this.name,
    this.role,
    this.phone,
    this.email,
    this.whatsappNumber,
    this.isPrimary = false,
    this.createdAt,
  });

  @override
  List<Object?> get props =>
      [id, name, role, phone, email, whatsappNumber, isPrimary];
}

class CustomerEntity extends Equatable {
  final String id;
  final String orgId;
  final String? assignedOfficerId;
  final String name;
  final String? code;
  final String customerType;
  final String? category;
  final String tier;
  final String status;
  final String? businessRegistration;
  final String? taxPin;

  // ── Location — full Tanzania hierarchy ────────────────────
  // column mapping:  county = region, city = district, ward, street
  final String? address;
  final String? city;    // district
  final String? county;  // region
  final String? ward;
  final String? street;
  final String? country;

  final double? latitude;
  final double? longitude;
  final int? gpsAccuracyMeters;

  // ── Contact ────────────────────────────────────────────────
  final String? phone;
  final String? altPhone;
  final String? email;
  final String? whatsappNumber;

  // ── Preferences ────────────────────────────────────────────
  final bool receivesWhatsapp;
  final bool receivesSms;
  final bool receivesInApp;

  // ── Finance ────────────────────────────────────────────────
  final double? creditLimit;
  final String? currency;

  final String? notes;
  final List<CustomerContact> contacts;
  final DateTime? createdAt;

  const CustomerEntity({
    required this.id,
    this.orgId = '',
    this.assignedOfficerId,
    required this.name,
    this.code,
    required this.customerType,
    this.category,
    this.tier = 'standard',
    this.status = 'active',
    this.businessRegistration,
    this.taxPin,
    this.address,
    this.city,
    this.county,
    this.ward,
    this.street,
    this.country,
    this.latitude,
    this.longitude,
    this.gpsAccuracyMeters,
    this.phone,
    this.altPhone,
    this.email,
    this.whatsappNumber,
    this.receivesWhatsapp = true,
    this.receivesSms = true,
    this.receivesInApp = true,
    this.creditLimit,
    this.currency,
    this.notes,
    this.contacts = const [],
    this.createdAt,
  });

  String get displayName => name;
  bool get hasGps => latitude != null && longitude != null;
  bool get isB2B => customerType == 'b2b';

  CustomerContact? get primaryContact =>
      contacts.where((c) => c.isPrimary).firstOrNull ??
      contacts.firstOrNull;

  CustomerEntity copyWith({
    String? id,
    String? orgId,
    String? assignedOfficerId,
    String? name,
    String? code,
    String? customerType,
    String? category,
    String? tier,
    String? status,
    String? businessRegistration,
    String? taxPin,
    String? address,
    String? city,
    String? county,
    String? ward,
    String? street,
    String? country,
    double? latitude,
    double? longitude,
    int? gpsAccuracyMeters,
    String? phone,
    String? altPhone,
    String? email,
    String? whatsappNumber,
    bool? receivesWhatsapp,
    bool? receivesSms,
    bool? receivesInApp,
    double? creditLimit,
    String? currency,
    String? notes,
    List<CustomerContact>? contacts,
    DateTime? createdAt,
  }) =>
      CustomerEntity(
        id: id ?? this.id,
        orgId: orgId ?? this.orgId,
        assignedOfficerId: assignedOfficerId ?? this.assignedOfficerId,
        name: name ?? this.name,
        code: code ?? this.code,
        customerType: customerType ?? this.customerType,
        category: category ?? this.category,
        tier: tier ?? this.tier,
        status: status ?? this.status,
        businessRegistration:
            businessRegistration ?? this.businessRegistration,
        taxPin: taxPin ?? this.taxPin,
        address: address ?? this.address,
        city: city ?? this.city,
        county: county ?? this.county,
        ward: ward ?? this.ward,
        street: street ?? this.street,
        country: country ?? this.country,
        latitude: latitude ?? this.latitude,
        longitude: longitude ?? this.longitude,
        gpsAccuracyMeters: gpsAccuracyMeters ?? this.gpsAccuracyMeters,
        phone: phone ?? this.phone,
        altPhone: altPhone ?? this.altPhone,
        email: email ?? this.email,
        whatsappNumber: whatsappNumber ?? this.whatsappNumber,
        receivesWhatsapp: receivesWhatsapp ?? this.receivesWhatsapp,
        receivesSms: receivesSms ?? this.receivesSms,
        receivesInApp: receivesInApp ?? this.receivesInApp,
        creditLimit: creditLimit ?? this.creditLimit,
        currency: currency ?? this.currency,
        notes: notes ?? this.notes,
        contacts: contacts ?? this.contacts,
        createdAt: createdAt ?? this.createdAt,
      );

  @override
  List<Object?> get props => [
        id,
        orgId,
        assignedOfficerId,
        name,
        code,
        customerType,
        category,
        tier,
        status,
        address,
        city,
        county,
        ward,
        street,
        phone,
        email,
        latitude,
        longitude,
        contacts,
        createdAt,
      ];
}