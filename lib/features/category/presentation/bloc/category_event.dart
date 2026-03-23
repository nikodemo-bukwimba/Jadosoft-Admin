import '../../domain/entities/category_entity.dart';
import '../../domain/usecases/create_category_usecase.dart';

abstract class CategoryEvent {}
class CategoryLoadAllRequested extends CategoryEvent {}
class CategoryLoadOneRequested extends CategoryEvent { final String id; CategoryLoadOneRequested(this.id); }
class CategoryCreateRequested extends CategoryEvent { final CreateCategoryParams params; CategoryCreateRequested(this.params); }
class CategoryUpdateRequested extends CategoryEvent { final CategoryEntity entity; CategoryUpdateRequested(this.entity); }
class CategoryDeleteRequested extends CategoryEvent { final String id; CategoryDeleteRequested(this.id); }
class CategoryFormReset extends CategoryEvent {}
