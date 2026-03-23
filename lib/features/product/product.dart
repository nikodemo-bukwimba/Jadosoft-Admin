// ============================================================================
// PRODUCT FEATURE — BARREL EXPORTS
// ============================================================================
//
// Place at: lib/features/product/product.dart
//
// Allows consumers to import the entire product feature with a single line:
//   import 'package:barick_admin/features/product/product.dart';
// ============================================================================

// Domain — Entities
export 'domain/entities/product_entity.dart';

// Domain — Value Objects
export 'domain/value_objects/product_status.dart';

// Domain — Repository Interface
export 'domain/repositories/product_repository.dart';

// Domain — Guards
export 'domain/guards/product_transition_guard.dart';

// Domain — Services
export 'domain/services/product_domain_service.dart';

// Domain — Use Cases
export 'domain/usecases/create_product_usecase.dart';
export 'domain/usecases/delete_product_usecase.dart';
export 'domain/usecases/get_all_product_usecase.dart';
export 'domain/usecases/get_product_usecase.dart';
export 'domain/usecases/update_product_usecase.dart';

// Data — Model
export 'data/models/product_model.dart';

// Data — Datasources
export 'data/datasources/product_remote_datasource.dart';
export 'data/datasources/product_mock_datasource.dart';

// Data — Repository Implementation
export 'data/repositories/product_repository_impl.dart';

// Presentation — BLoC
export 'presentation/bloc/product_bloc.dart';
export 'presentation/bloc/product_event.dart';
export 'presentation/bloc/product_state.dart';

// Presentation — Pages
export 'presentation/pages/product_list_page.dart';
export 'presentation/pages/product_detail_page.dart';
export 'presentation/pages/product_form_page.dart';

// Presentation — Widgets
export 'presentation/widgets/product_card.dart';
export 'presentation/widgets/product_card_tile.dart';
export 'presentation/widgets/product_grid_tile.dart';
export 'presentation/widgets/product_image.dart';
export 'presentation/widgets/product_list_row.dart';
export 'presentation/widgets/product_status_badge.dart';
export 'presentation/widgets/product_table_row.dart';
export 'presentation/widgets/view_mode_toggle.dart';
