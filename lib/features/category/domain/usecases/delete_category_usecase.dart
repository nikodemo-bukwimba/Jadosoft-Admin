import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/category_repository.dart';

class DeleteCategoryParams { final String id; const DeleteCategoryParams({required this.id}); }
class DeleteCategoryUseCase implements UseCase<void, DeleteCategoryParams> {
  final CategoryRepository repository;
  DeleteCategoryUseCase(this.repository);
  @override Future<Either<Failure, void>> call(DeleteCategoryParams p) => repository.delete(p.id);
}
