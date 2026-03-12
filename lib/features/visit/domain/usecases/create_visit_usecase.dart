import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/visit_entity.dart';
import '../repositories/visit_repository.dart';

class CreateVisitParams {
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
  final List<String>? promotedProductIds;
  final String? discussionSummary;

  const CreateVisitParams({
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
    this.promotedProductIds,
    this.discussionSummary,
  });
}

class CreateVisitUseCase implements UseCase<VisitEntity, CreateVisitParams> {
  final VisitRepository repository;
  CreateVisitUseCase(this.repository);

  @override
  Future<Either<Failure, VisitEntity>> call(CreateVisitParams p) async {
    // -- Validation gate --
    if (p.customerId.trim().isEmpty) {
      return const Left(ValidationFailure('Customer is required'));
    }
    if (p.officerId.trim().isEmpty) {
      return const Left(ValidationFailure('Officer is required'));
    }

    return repository.create(
      VisitEntity(
        id: '',
        customerId: p.customerId.trim(),
        officerId: p.officerId.trim(),
        visitDate: p.visitDate,
        businessName: p.businessName?.trim(),
        ownerPhone: p.ownerPhone?.trim(),
        contactPersonPhone: p.contactPersonPhone?.trim(),
        businessPhone: p.businessPhone?.trim(),
        notes: p.notes?.trim(),
        gpsLat: p.gpsLat,
        gpsLng: p.gpsLng,
        imageUrls: null,
        documentUrls: null,
        promotedProductIds: p.promotedProductIds,
        discussionSummary: p.discussionSummary?.trim(),
        status: '',
        createdAt: DateTime.now(),
      ),
    );
  }
}
