import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/customer_entity.dart';
import '../repositories/customer_repository.dart';

class CreateCustomerParams {
  final String name;
  final String customerType;
  final String? category;
  final String? tier;
  final String? phone;
  final String? email;
  final String? whatsappNumber;
  final String? address;
  final String? city;
  final String? county;
  final double? latitude;
  final double? longitude;
  final String? notes;
  final String? contactName;
  final String? contactRole;
  final String? contactPhone;

  const CreateCustomerParams({required this.name, required this.customerType, this.category, this.tier, this.phone, this.email, this.whatsappNumber, this.address, this.city, this.county, this.latitude, this.longitude, this.notes, this.contactName, this.contactRole, this.contactPhone});

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{'name': name.trim(), 'customer_type': customerType,
      if (category != null && category!.isNotEmpty) 'category': category,
      if (tier != null && tier!.isNotEmpty) 'tier': tier,
      if (phone != null && phone!.isNotEmpty) 'phone': phone,
      if (email != null && email!.isNotEmpty) 'email': email,
      if (whatsappNumber != null && whatsappNumber!.isNotEmpty) 'whatsapp_number': whatsappNumber,
      if (address != null && address!.isNotEmpty) 'address': address,
      if (city != null && city!.isNotEmpty) 'city': city,
      if (county != null && county!.isNotEmpty) 'county': county,
      if (latitude != null) 'latitude': latitude, if (longitude != null) 'longitude': longitude,
      if (notes != null && notes!.isNotEmpty) 'notes': notes};
    if (contactName != null && contactName!.isNotEmpty) {
      data['contacts'] = [{'name': contactName, if (contactRole != null) 'role': contactRole, if (contactPhone != null) 'phone': contactPhone, 'is_primary': true}];
    }
    return data;
  }
}

class CreateCustomerUseCase implements UseCase<CustomerEntity, CreateCustomerParams> {
  final CustomerRepository repository;
  CreateCustomerUseCase(this.repository);
  @override
  Future<Either<Failure, CustomerEntity>> call(CreateCustomerParams p) async {
    if (p.name.trim().isEmpty) return const Left(ValidationFailure('Customer name is required'));
    if (p.name.trim().length < 2) return const Left(ValidationFailure('Name must be at least 2 characters'));
    if (p.customerType != 'b2b' && p.customerType != 'b2c') return const Left(ValidationFailure('Type must be b2b or b2c'));
    return repository.create(p.toJson());
  }
}
