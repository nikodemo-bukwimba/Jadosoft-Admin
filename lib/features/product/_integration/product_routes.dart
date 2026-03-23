// ============================================================================
// PRODUCT FEATURE — ROUTE REGISTRATION
// ============================================================================
//
// Add these routes to: lib/app/routes/app_router.dart
//
// Insert inside the GoRouter routes list, after the category routes (Seq 8).
// Products (Seq 9) are under the '/products' path prefix.
//
// Each route wraps its page in a BlocProvider that resolves from GetIt.
// The ProductFormPage also needs CategoryBloc for the category dropdown.
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import '../../features/category/presentation/bloc/category_bloc.dart';
import '../../features/product/domain/entities/product_entity.dart';
import '../../features/product/presentation/bloc/product_bloc.dart';
import '../../features/product/presentation/pages/product_detail_page.dart';
import '../../features/product/presentation/pages/product_form_page.dart';
import '../../features/product/presentation/pages/product_list_page.dart';
import '../../core/enums/form_mode.dart';

final sl = GetIt.instance;

/// Product feature route definitions.
///
/// Add `...productRoutes` to the GoRouter routes list:
///
/// ```dart
/// final router = GoRouter(
///   routes: [
///     // ... existing routes
///     ...productRoutes,
///   ],
/// );
/// ```
final List<RouteBase> productRoutes = [
  GoRoute(
    path: '/products',
    name: 'products',
    builder: (context, state) => BlocProvider(
      create: (_) => sl<ProductBloc>()
        ..add(const ProductLoadAllRequested()),
      child: const ProductListPage(),
    ),
    routes: [
      // Create new product
      GoRoute(
        path: 'create',
        name: 'product-create',
        builder: (context, state) => MultiBlocProvider(
          providers: [
            BlocProvider(create: (_) => sl<ProductBloc>()),
            BlocProvider(create: (_) => sl<CategoryBloc>()),
          ],
          child: const ProductFormPage(mode: FormMode.create),
        ),
      ),

      // Product detail
      GoRoute(
        path: ':productId',
        name: 'product-detail',
        builder: (context, state) {
          final productId = state.pathParameters['productId']!;
          return BlocProvider(
            create: (_) => sl<ProductBloc>()
              ..add(ProductLoadOneRequested(productId)),
            child: ProductDetailPage(productId: productId),
          );
        },
        routes: [
          // Edit product
          GoRoute(
            path: 'edit',
            name: 'product-edit',
            builder: (context, state) {
              final product = state.extra as ProductEntity?;
              return MultiBlocProvider(
                providers: [
                  BlocProvider(create: (_) => sl<ProductBloc>()),
                  BlocProvider(create: (_) => sl<CategoryBloc>()),
                ],
                child: ProductFormPage(
                  mode: FormMode.edit,
                  product: product,
                ),
              );
            },
          ),
        ],
      ),
    ],
  ),
];
