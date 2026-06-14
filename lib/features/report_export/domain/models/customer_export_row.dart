// lib/features/report_export/domain/models/customer_export_row.dart
//
// Immutable DTO built from CustomerEntity + optional List<VisitEntity>.
// Both PDF and Excel generators consume this exclusively.
// No generator touches a raw entity or calls any UseCase.
// ─────────────────────────────────────────────────────────────────

class CustomerContactRow {
  final String name;
  final String? role;
  final String? phone;
  final String? email;
  final String? whatsapp;
  final bool isPrimary;

  const CustomerContactRow({
    required this.name,
    this.role,
    this.phone,
    this.email,
    this.whatsapp,
    required this.isPrimary,
  });
}

class CustomerVisitRow {
  final String visitDate;
  final String status;
  final String? officerName;
  final String? purpose;
  final String? notes;
  final String? outcome;

  const CustomerVisitRow({
    required this.visitDate,
    required this.status,
    this.officerName,
    this.purpose,
    this.notes,
    this.outcome,
  });
}

class CustomerExportRow {
  final int no;

  // ── Identity ──────────────────────────────────────────────────
  final String name;
  final String? code;
  final String customerType; // b2b | b2c
  final String? category;
  final String tier;
  final String status;

  // ── Contact ───────────────────────────────────────────────────
  final String? phone;
  final String? altPhone;
  final String? email;
  final String? whatsappNumber;

  // ── Communication preferences ─────────────────────────────────
  final bool receivesWhatsapp;
  final bool receivesSms;
  final bool receivesInApp;

  // ── Location ──────────────────────────────────────────────────
  final String? address;
  final String? city;
  final String? county;
  final String? country;
  final double? latitude;
  final double? longitude;

  // ── Business ──────────────────────────────────────────────────
  final String? businessRegistration;
  final String? taxPin;
  final double? creditLimit;
  final String? currency;

  // ── Notes ─────────────────────────────────────────────────────
  final String? notes;

  // ── Contacts ──────────────────────────────────────────────────
  final List<CustomerContactRow> contacts;

  // ── Assignment ────────────────────────────────────────────────
  final String? assignedOfficerName; // resolved display name

  // ── Dates ─────────────────────────────────────────────────────
  final String? registeredAt;

  // ── Visit history (optional) ──────────────────────────────────
  final List<CustomerVisitRow> visits;

  const CustomerExportRow({
    required this.no,
    required this.name,
    this.code,
    required this.customerType,
    this.category,
    required this.tier,
    required this.status,
    this.phone,
    this.altPhone,
    this.email,
    this.whatsappNumber,
    required this.receivesWhatsapp,
    required this.receivesSms,
    required this.receivesInApp,
    this.address,
    this.city,
    this.county,
    this.country,
    this.latitude,
    this.longitude,
    this.businessRegistration,
    this.taxPin,
    this.creditLimit,
    this.currency,
    this.notes,
    this.contacts = const [],
    this.assignedOfficerName,
    this.registeredAt,
    this.visits = const [],
  });
}