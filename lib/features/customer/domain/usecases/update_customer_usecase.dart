import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/customer_entity.dart';
import '../repositories/customer_repository.dart';

class UpdateCustomerParams {
  final CustomerEntity entity;
  final String? contactName;
  final String? contactPhone;
  final String? contactRole;
  final String? appPassword;
  final String? appPasswordConfirmation;

  const UpdateCustomerParams({
    required this.entity,
    this.contactName,
    this.contactPhone,
    this.contactRole,
    this.appPassword,
    this.appPasswordConfirmation,
  });
}

class UpdateCustomerUseCase
    implements UseCase<CustomerEntity, UpdateCustomerParams> {
  final CustomerRepository repository;
  UpdateCustomerUseCase(this.repository);

  @override
  Future<Either<Failure, CustomerEntity>> call(UpdateCustomerParams p) =>
      repository.update(p.entity.id, {
        'name': p.entity.name,
        'customer_type': p.entity.customerType,
        'category': p.entity.category,
        'tier': p.entity.tier,
        if (p.entity.assignedOfficerId != null &&
            p.entity.assignedOfficerId!.isNotEmpty)
          'assigned_officer_id': p.entity.assignedOfficerId,
        // Location — full hierarchy
        if (p.entity.address != null) 'address': p.entity.address,
        if (p.entity.city != null) 'city': p.entity.city,
        if (p.entity.county != null) 'county': p.entity.county,
        if (p.entity.ward != null) 'ward': p.entity.ward,
        if (p.entity.street != null) 'street': p.entity.street,
        if (p.entity.latitude != null) 'latitude': p.entity.latitude,
        if (p.entity.longitude != null) 'longitude': p.entity.longitude,
        // Communication
        if (p.entity.phone != null) 'phone': p.entity.phone,
        if (p.entity.email != null) 'email': p.entity.email,
        if (p.entity.whatsappNumber != null)
          'whatsapp_number': p.entity.whatsappNumber,
        'receives_whatsapp': p.entity.receivesWhatsapp,
        'receives_sms': p.entity.receivesSms,
        'receives_in_app': p.entity.receivesInApp,
        if (p.entity.notes != null) 'notes': p.entity.notes,
        // Contact person
        if (p.contactName != null && p.contactName!.isNotEmpty)
          'contact_name': p.contactName,
        if (p.contactPhone != null && p.contactPhone!.isNotEmpty)
          'contact_phone': p.contactPhone,
        if (p.contactRole != null && p.contactRole!.isNotEmpty)
          'contact_role': p.contactRole,
        // App login password
        if (p.appPassword != null && p.appPassword!.isNotEmpty)
          'app_password': p.appPassword,
        if (p.appPasswordConfirmation != null &&
            p.appPasswordConfirmation!.isNotEmpty)
          'app_password_confirmation': p.appPasswordConfirmation,
      });
}