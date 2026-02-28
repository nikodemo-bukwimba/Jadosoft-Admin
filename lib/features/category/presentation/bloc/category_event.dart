// category_event.dart
// All events dispatched to CategoryBloc.

part of 'category_bloc.dart';

abstract class CategoryEvent {}

// ── CRUD events ───────────────────────────────────────────────
class CategoryLoadAllRequested extends CategoryEvent {
  final CategoryFilterParams?     filters;
  final CategorySortParams?       sort;
  final CategoryPaginationParams? pagination;

  CategoryLoadAllRequested({this.filters, this.sort, this.pagination});
}

class CategoryLoadOneRequested extends CategoryEvent {
  final String id;
  CategoryLoadOneRequested(this.id);
}

class CategoryCreateRequested extends CategoryEvent {
  final CreateCategoryParams params;
  CategoryCreateRequested(this.params);
}

class CategoryUpdateRequested extends CategoryEvent {
  final CategoryEntity entity;
  CategoryUpdateRequested(this.entity);
}

class CategoryDeleteRequested extends CategoryEvent {
  final String id;
  CategoryDeleteRequested(this.id);
}

class CategorySearchChanged extends CategoryEvent {
  final String query;
  CategorySearchChanged(this.query);
}

class CategoryFormReset extends CategoryEvent {}

