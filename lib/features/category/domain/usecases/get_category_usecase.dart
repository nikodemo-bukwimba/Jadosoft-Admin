import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/category_entity.dart';
import '../repositories/category_repository.dart';

class GetCategoryParams { final String id; const GetCategoryParams({required this.id}); }
class GetCategoryUseCase implements UseCase<CategoryEntity, GetCategoryParams> {
  final CategoryRepository repository;
  GetCategoryUseCase(this.repository);
  @override Future<Either<Failure, CategoryEntity>> call(GetCategoryParams p) => repository.getById(p.id);
}
