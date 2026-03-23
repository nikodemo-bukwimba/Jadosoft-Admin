import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/customer_entity.dart';
import '../repositories/customer_repository.dart';

class UpdateCustomerParams { final CustomerEntity entity; const UpdateCustomerParams({required this.entity}); }
class UpdateCustomerUseCase implements UseCase<CustomerEntity, UpdateCustomerParams> {
  final CustomerRepository repository;
  UpdateCustomerUseCase(this.repository);
  @override Future<Either<Failure, CustomerEntity>> call(UpdateCustomerParams p) => repository.update(p.entity.id, {
    'name': p.entity.name, 'category': p.entity.category, 'tier': p.entity.tier,
    if (p.entity.phone != null) 'phone': p.entity.phone, if (p.entity.email != null) 'email': p.entity.email,
    if (p.entity.whatsappNumber != null) 'whatsapp_number': p.entity.whatsappNumber,
    if (p.entity.address != null) 'address': p.entity.address, if (p.entity.city != null) 'city': p.entity.city,
    if (p.entity.county != null) 'county': p.entity.county,
    if (p.entity.latitude != null) 'latitude': p.entity.latitude, if (p.entity.longitude != null) 'longitude': p.entity.longitude,
    if (p.entity.notes != null) 'notes': p.entity.notes,
    'receives_whatsapp': p.entity.receivesWhatsapp, 'receives_sms': p.entity.receivesSms, 'receives_in_app': p.entity.receivesInApp,
  });
}
