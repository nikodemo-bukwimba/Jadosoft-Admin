// category_bloc.dart
// Orchestrates CRUD and state machine transitions.
// Pure dispatcher — events in, states out.

import 'package:fca/features/category/domain/usecases/create_isActive_usecase.dart';
import 'package:fca/features/category/domain/usecases/delete_isActive_usecase.dart';
import 'package:fca/features/category/domain/usecases/update_isActive_usecase.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/category_entity.dart';
import '../../domain/repositories/category_repository.dart';

import '../../domain/usecases/get_category_usecase.dart';
import '../../domain/usecases/get_all_category_usecase.dart';

part 'category_event.dart';
part 'category_state.dart';

class CategoryBloc extends Bloc<CategoryEvent, CategoryState> {
  final GetAllCategoryUseCase getAllUseCase;
  final GetCategoryUseCase getUseCase;
  final CreateCategoryUseCase createUseCase;
  final UpdateCategoryUseCase updateUseCase;
  final DeleteCategoryUseCase deleteUseCase;

  CategoryBloc({
    required this.getAllUseCase,
    required this.getUseCase,
    required this.createUseCase,
    required this.updateUseCase,
    required this.deleteUseCase,
  }) : super(CategoryInitial()) {
    on<CategoryLoadAllRequested>(_onLoadAll);
    on<CategoryLoadOneRequested>(_onLoadOne);
    on<CategoryCreateRequested>(_onCreate);
    on<CategoryUpdateRequested>(_onUpdate);
    on<CategoryDeleteRequested>(_onDelete);
    on<CategorySearchChanged>(_onSearch);
    on<CategoryFormReset>((_, emit) => emit(CategoryInitial()));
  }

  Future<void> _onLoadAll(
    CategoryLoadAllRequested event,
    Emitter<CategoryState> emit,
  ) async {
    emit(CategoryLoading());
    final result = await getAllUseCase(
      GetAllCategoryParams(
        filters: event.filters,
        sort: event.sort,
        pagination: event.pagination,
      ),
    );
    result.fold(
      (f) => emit(CategoryFailure(f.message)),
      (items) => items.isEmpty
          ? emit(CategoryEmpty())
          : emit(CategoryListLoaded(items)),
    );
  }

  Future<void> _onLoadOne(
    CategoryLoadOneRequested event,
    Emitter<CategoryState> emit,
  ) async {
    emit(CategoryLoading());
    final result = await getUseCase(GetCategoryParams(id: event.id));
    result.fold(
      (f) => emit(CategoryFailure(f.message)),
      (item) => emit(CategoryDetailLoaded(item)),
    );
  }

  Future<void> _onCreate(
    CategoryCreateRequested event,
    Emitter<CategoryState> emit,
  ) async {
    emit(CategoryLoading());
    final result = await createUseCase(event.params);
    result.fold(
      (f) => emit(CategoryFailure(f.message)),
      (_) => emit(CategoryOperationSuccess('Category created successfully')),
    );
  }

  Future<void> _onUpdate(
    CategoryUpdateRequested event,
    Emitter<CategoryState> emit,
  ) async {
    emit(CategoryLoading());
    final result = await updateUseCase(
      UpdateCategoryParams(entity: event.entity),
    );
    result.fold(
      (f) => emit(CategoryFailure(f.message)),
      (item) => emit(
        CategoryOperationSuccess(
          'Category updated successfully',
          updatedItem: item,
        ),
      ),
    );
  }

  Future<void> _onDelete(
    CategoryDeleteRequested event,
    Emitter<CategoryState> emit,
  ) async {
    emit(CategoryLoading());
    final result = await deleteUseCase(DeleteCategoryParams(id: event.id));
    result.fold(
      (f) => emit(CategoryFailure(f.message)),
      (_) => emit(CategoryOperationSuccess('Category deleted successfully')),
    );
  }

  Future<void> _onSearch(
    CategorySearchChanged event,
    Emitter<CategoryState> emit,
  ) async {
    emit(CategoryLoading());
    final result = await getAllUseCase(const GetAllCategoryParams());
    result.fold((f) => emit(CategoryFailure(f.message)), (items) {
      final filtered = items
          .where(
            (item) => item.toString().toLowerCase().contains(
              event.query.toLowerCase(),
            ),
          )
          .toList();
      filtered.isEmpty
          ? emit(CategoryEmpty())
          : emit(CategoryListLoaded(filtered));
    });
  }
}
