// customer_data_provider_impl.dart
// ─────────────────────────────────────────────────────────────
// Fix: CustomerRepository.getAll() returns PaginatedResponse<CustomerEntity>
// from the real Nexora API. The marketing dashboard CustomerDataProvider
// interface expects List<CustomerEntity>. Unwrap here.
//
// CHECK: look at your PaginatedResponse class and use the correct field:
//   • If it has `.items`  → use paginated.items
//   • If it has `.data`   → use paginated.data
//   • If it has `.results`→ use paginated.results
// The import path below may also need adjusting to match your project.
// ─────────────────────────────────────────────────────────────

import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
// import '../../../../core/network/paginated_response.dart';
import '../../../../features/customer/domain/entities/customer_entity.dart';
import '../../../../features/customer/domain/repositories/customer_repository.dart';
import '../../domain/providers/customer_data_provider.dart';

class CustomerDataProviderImpl implements CustomerDataProvider {
  final CustomerRepository _repository;

  CustomerDataProviderImpl({required CustomerRepository repository})
    : _repository = repository;

  @override
  Future<Either<Failure, List<CustomerEntity>>> getAll() async {
    final result = await _repository.getAll();
    return result.fold(Left.new, (paginated) => Right(paginated.items));
  }
}
