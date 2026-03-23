import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/paginated_response.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/category_entity.dart';
import '../repositories/category_repository.dart';

class GetAllCategoryUseCase implements UseCase<PaginatedResponse<CategoryEntity>, NoParams> {
  final CategoryRepository repository;
  GetAllCategoryUseCase(this.repository);
  @override
  Future<Either<Failure, PaginatedResponse<CategoryEntity>>> call(NoParams _) => repository.getAll();
}
