// delete_isActive_usecase.dart

import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/category_repository.dart';

class DeleteCategoryParams {
  final String id;
  const DeleteCategoryParams({required this.id});
}

class DeleteCategoryUseCase implements UseCase<void, DeleteCategoryParams> {
  final CategoryRepository repository;
  DeleteCategoryUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(DeleteCategoryParams params) async {
    if (params.id.isEmpty) {
      return const Left(ValidationFailure('Cannot delete: ID is required'));
    }

    // TODO: Add pre-delete domain checks here

    return repository.delete(params.id);
  }
}
