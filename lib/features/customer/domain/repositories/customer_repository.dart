import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/paginated_response.dart';
import '../entities/customer_entity.dart';

abstract class CustomerRepository {
  Future<Either<Failure, PaginatedResponse<CustomerEntity>>> getAll({String? customerType, String? status, String? category, String? tier, String? officerId, String? search, int? perPage, int? page});
  Future<Either<Failure, CustomerEntity>> getById(String id);
  Future<Either<Failure, CustomerEntity>> create(Map<String, dynamic> data);
  Future<Either<Failure, CustomerEntity>> update(String id, Map<String, dynamic> data);
  Future<Either<Failure, void>> delete(String id);
  Future<Either<Failure, CustomerEntity>> assignOfficer(String customerId, String officerActorId);
  Future<Either<Failure, CustomerContact>> addContact(String customerId, Map<String, dynamic> data);
  Future<Either<Failure, CustomerContact>> updateContact(String contactId, Map<String, dynamic> data);
  Future<Either<Failure, void>> deleteContact(String contactId);
}
