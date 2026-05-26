
//admin app
import '../../domain/entities/customer_entity.dart';

class CustomerContactModel extends CustomerContact {
  const CustomerContactModel({
    required super.id,
    required super.name,
    super.role,
    super.phone,
    super.email,
    super.whatsappNumber,
    super.isPrimary,
    super.createdAt,
  });

  factory CustomerContactModel.fromJson(Map<String, dynamic> j) =>
      CustomerContactModel(
        id: (j['id'] ?? '').toString(),
        name: j['name'] as String? ?? '',
        role: j['role'] as String?,
        phone: j['phone'] as String?,
        email: j['email'] as String?,
        whatsappNumber: j['whatsapp_number'] as String?,
        isPrimary: j['is_primary'] == true,
        createdAt: j['created_at'] != null
            ? DateTime.tryParse(j['created_at'].toString())
            : null,
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        if (role != null) 'role': role,
        if (phone != null) 'phone': phone,
        if (email != null) 'email': email,
        if (whatsappNumber != null) 'whatsapp_number': whatsappNumber,
        'is_primary': isPrimary,
      };
}

class CustomerModel extends CustomerEntity {
  const CustomerModel({
    required super.id,
    super.orgId,
    super.assignedOfficerId,
    required super.name,
    super.code,
    required super.customerType,
    super.category,
    super.tier,
    super.status,
    super.businessRegistration,
    super.taxPin,
    super.address,
    super.city,
    super.county,
    super.ward,
    super.street,
    super.country,
    super.latitude,
    super.longitude,
    super.gpsAccuracyMeters,
    super.phone,
    super.altPhone,
    super.email,
    super.whatsappNumber,
    super.receivesWhatsapp,
    super.receivesSms,
    super.receivesInApp,
    super.creditLimit,
    super.currency,
    super.notes,
    super.contacts,
    super.createdAt,
  });

  static double? _toDouble(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString());
  }

  static int? _toInt(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString());
  }

  factory CustomerModel.fromJson(Map<String, dynamic> j) {
    final rawC = j['contacts'] as List<dynamic>? ?? [];
    final contacts = rawC
        .map((c) => CustomerContactModel.fromJson(c as Map<String, dynamic>))
        .toList();

    return CustomerModel(
      id: (j['id'] ?? '').toString(),
      orgId: (j['org_id'] ?? '').toString(),
      assignedOfficerId: j['assigned_officer_id']?.toString(),
      name: j['name'] as String? ?? '',
      code: j['code'] as String?,
      customerType: j['customer_type'] as String? ?? 'b2b',
      category: j['category'] as String?,
      tier: j['tier'] as String? ?? 'standard',
      status: j['status'] as String? ?? 'active',
      businessRegistration: j['business_registration'] as String?,
      taxPin: j['tax_pin'] as String?,
      address: j['address'] as String?,
      city: j['city'] as String?,
      county: j['county'] as String?,
      ward: j['ward'] as String?,
      street: j['street'] as String?,
      country: j['country'] as String?,
      latitude: _toDouble(j['latitude']),
      longitude: _toDouble(j['longitude']),
      gpsAccuracyMeters: _toInt(j['gps_accuracy_meters']),
      phone: j['phone'] as String?,
      altPhone: j['alt_phone'] as String?,
      email: j['email'] as String?,
      whatsappNumber: j['whatsapp_number'] as String?,
      receivesWhatsapp: j['receives_whatsapp'] as bool? ?? true,
      receivesSms: j['receives_sms'] as bool? ?? true,
      receivesInApp: j['receives_in_app'] as bool? ?? true,
      creditLimit: _toDouble(j['credit_limit']),
      currency: j['currency'] as String?,
      notes: j['notes'] as String?,
      contacts: contacts,
      createdAt: j['created_at'] != null
          ? DateTime.tryParse(j['created_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'customer_type': customerType,
        'category': category,
        'tier': tier,
        'status': status,
        'address': address,
        'city': city,
        'county': county,
        'ward': ward,
        'street': street,
        'country': country,
        'latitude': latitude,
        'longitude': longitude,
        'phone': phone,
        'email': email,
        'whatsapp_number': whatsappNumber,
        'receives_whatsapp': receivesWhatsapp,
        'receives_sms': receivesSms,
        'receives_in_app': receivesInApp,
        'credit_limit': creditLimit,
        'currency': currency,
        'notes': notes,
      };

  factory CustomerModel.fromEntity(CustomerEntity e) => CustomerModel(
        id: e.id,
        orgId: e.orgId,
        assignedOfficerId: e.assignedOfficerId,
        name: e.name,
        code: e.code,
        customerType: e.customerType,
        category: e.category,
        tier: e.tier,
        status: e.status,
        businessRegistration: e.businessRegistration,
        taxPin: e.taxPin,
        address: e.address,
        city: e.city,
        county: e.county,
        ward: e.ward,
        street: e.street,
        country: e.country,
        latitude: e.latitude,
        longitude: e.longitude,
        gpsAccuracyMeters: e.gpsAccuracyMeters,
        phone: e.phone,
        altPhone: e.altPhone,
        email: e.email,
        whatsappNumber: e.whatsappNumber,
        receivesWhatsapp: e.receivesWhatsapp,
        receivesSms: e.receivesSms,
        receivesInApp: e.receivesInApp,
        creditLimit: e.creditLimit,
        currency: e.currency,
        notes: e.notes,
        contacts: e.contacts,
        createdAt: e.createdAt,
      );
}