import 'package:dartz/dartz.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/paginated_response.dart';
import '../../domain/entities/customer_entity.dart';
import '../../domain/repositories/customer_repository.dart';
import '../datasources/customer_remote_datasource.dart';

class CustomerRepositoryImpl implements CustomerRepository {
  final CustomerRemoteDataSource _remote;
  CustomerRepositoryImpl({required CustomerRemoteDataSource remoteDataSource}) : _remote = remoteDataSource;

  Future<Either<Failure, T>> _guard<T>(Future<T> Function() call) async {
    try { return Right(await call());
    } on AuthException catch (e) { return Left(AuthFailure(e.message));
    } on ServerException catch (e) { return Left(ServerFailure(e.message));
    } on NetworkException catch (e) { return Left(NetworkFailure(e.message));
    } catch (e) { return Left(GenericFailure(e.toString())); }
  }

  @override Future<Either<Failure, PaginatedResponse<CustomerEntity>>> getAll({String? customerType, String? status, String? category, String? tier, String? officerId, String? search, int? perPage, int? page}) =>
    _guard(() => _remote.getAll(customerType: customerType, status: status, category: category, tier: tier, officerId: officerId, search: search, perPage: perPage, page: page));
  @override Future<Either<Failure, CustomerEntity>> getById(String id) => _guard(() => _remote.getById(id));
  @override Future<Either<Failure, CustomerEntity>> create(Map<String, dynamic> data) => _guard(() => _remote.create(data));
  @override Future<Either<Failure, CustomerEntity>> update(String id, Map<String, dynamic> data) => _guard(() => _remote.update(id, data));
  @override Future<Either<Failure, void>> delete(String id) => _guard(() => _remote.delete(id));
  @override Future<Either<Failure, CustomerEntity>> assignOfficer(String cId, String oId) => _guard(() => _remote.assignOfficer(cId, oId));
  @override Future<Either<Failure, CustomerContact>> addContact(String cId, Map<String, dynamic> d) => _guard(() => _remote.addContact(cId, d));
  @override Future<Either<Failure, CustomerContact>> updateContact(String cId, Map<String, dynamic> d) => _guard(() => _remote.updateContact(cId, d));
  @override Future<Either<Failure, void>> deleteContact(String cId) => _guard(() => _remote.deleteContact(cId));
}
