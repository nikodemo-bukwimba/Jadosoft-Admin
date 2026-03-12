import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/usecase/usecase.dart';
import '../../domain/usecases/create_category_usecase.dart';
import '../../domain/usecases/delete_category_usecase.dart';
import '../../domain/usecases/get_category_usecase.dart';
import '../../domain/usecases/get_all_category_usecase.dart';
import '../../domain/usecases/update_category_usecase.dart';
import 'category_event.dart';
import 'category_state.dart';

class CategoryBloc extends Bloc<CategoryEvent, CategoryState> {
  final GetAllCategoryUseCase  getAllUseCase;
  final GetCategoryUseCase     getUseCase;
  final CreateCategoryUseCase  createUseCase;
  final UpdateCategoryUseCase  updateUseCase;
  final DeleteCategoryUseCase  deleteUseCase;

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
    on<CategoryFormReset>((_, emit) => emit(CategoryInitial()));
  }

  Future<void> _onLoadAll(
      CategoryLoadAllRequested event, Emitter<CategoryState> emit) async {
    emit(CategoryLoading());
    final result = await getAllUseCase(NoParams());
    result.fold(
      (f) => emit(CategoryFailure(f.message)),
      (items) => items.isEmpty
          ? emit(CategoryEmpty())
          : emit(CategoryListLoaded(items)),
    );
  }

  Future<void> _onLoadOne(
      CategoryLoadOneRequested event, Emitter<CategoryState> emit) async {
    emit(CategoryLoading());
    final result = await getUseCase(GetCategoryParams(id: event.id));
    result.fold(
      (f) => emit(CategoryFailure(f.message)),
      (item) => emit(CategoryDetailLoaded(item)),
    );
  }

  Future<void> _onCreate(
      CategoryCreateRequested event, Emitter<CategoryState> emit) async {
    emit(CategoryLoading());
    final result = await createUseCase(event.params);
    result.fold(
      (f) => emit(CategoryFailure(f.message)),
      (_) => emit(CategoryOperationSuccess('Category created successfully')),
    );
  }

  Future<void> _onUpdate(
      CategoryUpdateRequested event, Emitter<CategoryState> emit) async {
    emit(CategoryLoading());
    final result = await updateUseCase(UpdateCategoryParams(entity: event.entity));
    result.fold(
      (f) => emit(CategoryFailure(f.message)),
      (_) => emit(CategoryOperationSuccess('Category updated successfully')),
    );
  }

  Future<void> _onDelete(
      CategoryDeleteRequested event, Emitter<CategoryState> emit) async {
    emit(CategoryLoading());
    final result = await deleteUseCase(DeleteCategoryParams(id: event.id));
    result.fold(
      (f) => emit(CategoryFailure(f.message)),
      (_) => emit(CategoryOperationSuccess('Category deleted successfully')),
    );
  }
}
