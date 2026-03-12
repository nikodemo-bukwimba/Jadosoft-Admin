import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/customer_entity.dart';
import '../repositories/customer_repository.dart';

class CreateCustomerParams {
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

  const CreateCustomerParams({
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
  });
}

class CreateCustomerUseCase implements UseCase<CustomerEntity, CreateCustomerParams> {
  final CustomerRepository repository;
  CreateCustomerUseCase(this.repository);

  @override
  Future<Either<Failure, CustomerEntity>> call(CreateCustomerParams p) async {
    // -- Validation gate --
    if (p.businessName.trim().isEmpty) {
      return Left(ValidationFailure('Business name is required'));
    }
    if (p.businessName.length < 2) {
      return Left(ValidationFailure('Business name must be at least 2 characters'));
    }
    if (p.ownerName.trim().isEmpty) {
      return Left(ValidationFailure('Owner name is required'));
    }
    if (p.officialPhone.trim().isEmpty) {
      return Left(ValidationFailure('Official phone is required'));
    }
    if (p.assignedOfficerId.trim().isEmpty) {
      return Left(ValidationFailure('Assigned officer is required'));
    }

    return repository.create(
      CustomerEntity(
        id: '',
        businessName: p.businessName.trim(),
        fullOfficeName: p.fullOfficeName?.trim(),
        ownerName: p.ownerName.trim(),
        officialPhone: p.officialPhone.trim(),
        contactPerson: p.contactPerson?.trim(),
        contactPersonPhone: p.contactPersonPhone?.trim(),
        officeAddress: p.officeAddress?.trim(),
        gpsLat: p.gpsLat,
        gpsLng: p.gpsLng,
        assignedOfficerId: p.assignedOfficerId.trim(),
        registrationDate: DateTime.now(),
      ),
    );
  }
}
