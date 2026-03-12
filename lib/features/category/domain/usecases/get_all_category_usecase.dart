import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/category_entity.dart';
import '../repositories/category_repository.dart';

class GetAllCategoryUseCase implements UseCase<List<CategoryEntity>, NoParams> {
  final CategoryRepository repository;
  GetAllCategoryUseCase(this.repository);

  @override
  Future<Either<Failure, List<CategoryEntity>>> call(NoParams _) =>
      repository.getAll();
}
