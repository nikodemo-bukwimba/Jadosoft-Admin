// app_router.dart
// App navigation — the single source of truth for all named routes.
//
// Uses Flutter's Navigator with MaterialPageRoute (not GoRouter).
// All route name constants live here. All route → widget mappings live here.
//
// Moved from: config/routes/app_router.dart
// New location: app/routes/app_router.dart
//
// Import path changes:
//   Old shell import: '../shell/features/shell/shell_page.dart'
//   New shell import: '../shell/shell_page.dart'   ← shell is no longer a feature
//
// Adding a new feature route:
//   1. Add a static const String for the route path.
//   2. Add a case in generateRoute() returning the feature's page.
//   3. If the feature needs a shell tab, also update shell_nav_items.dart.
//
// Generator appends new route constants and cases between the boundary markers.

// ── GENERATOR FEATURE PAGE IMPORTS — append only ─────────────────────────────
import '../../features/category/presentation/pages/category_list_page.dart';
import '../../features/category/presentation/pages/category_detail_page.dart';
import '../../features/category/presentation/pages/category_form_page.dart';
import '../../features/category/presentation/bloc/category_bloc.dart';
import '../../config/di/injection_container.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../features/visit/presentation/pages/visit_list_page.dart';
import '../../features/visit/presentation/pages/visit_detail_page.dart';
import '../../features/visit/presentation/pages/visit_form_page.dart';
import '../../features/visit/presentation/bloc/visit_bloc.dart';

import 'package:flutter/material.dart';

import '../../features/auth/presentation/pages/account_picker_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../shell/shell_page.dart';

import '../../features/hello/presentation/pages/hello_list_page.dart';
import '../../features/hello/presentation/pages/hello_detail_page.dart';
import '../../features/hello/presentation/pages/hello_form_page.dart';
import '../../features/hello/presentation/bloc/hello_bloc.dart';
import '../../features/hello/presentation/bloc/hello_event.dart';

import '../../features/order/presentation/pages/order_list_page.dart';
import '../../features/order/presentation/pages/order_detail_page.dart';
import '../../features/order/presentation/pages/order_form_page.dart';
import '../../features/order/presentation/bloc/order_bloc.dart';
import '../../features/order/presentation/bloc/order_event.dart';
import '../../core/enums/form_mode.dart';

import '../../features/project/presentation/pages/project_list_page.dart';
import '../../features/project/presentation/pages/project_detail_page.dart';
import '../../features/project/presentation/pages/project_form_page.dart';
import '../../features/project/presentation/bloc/project_bloc.dart';
import '../../features/project/presentation/bloc/project_event.dart';
import '../../features/overview_dashboard/presentation/pages/overview_dashboard_dashboard_page.dart';
import '../../features/overview_dashboard/presentation/cubit/overview_dashboard_cubit.dart';

// ── END GENERATOR FEATURE PAGE IMPORTS ───────────────────────────────────────

class AppRouter {
  // ── Route path constants ──────────────────────────────────────────────────
  static const String login = '/login';
  static const String register = '/register';
  static const String home = '/home';
  static const String accountPicker = '/account-picker';

  // ── GENERATOR ROUTE CONSTANTS — append only ───────────────────────────────────
  static const String categoryList = '/categorys';
  static const String categoryCreate = '/categorys/create';
  static const String categoryDetail = '/categorys/detail';
  static const String categoryEdit = '/categorys/edit';
  static const String visitList = '/visits';
  static const String visitCreate = '/visits/create';
  static const String visitDetail = '/visits/detail';
  static const String visitEdit = '/visits/edit';
  static const String aboutPage = '/about';

  static const String helloList = '/hellos';
  static const String helloCreate = '/hellos/create';
  static const String helloDetail = '/hellos/detail';
  static const String helloEdit = '/hellos/edit';

  static const String habariList = '/habaris';
  static const String habariCreate = '/habaris/create';
  static const String habariDetail = '/habaris/detail';
  static const String habariEdit = '/habaris/edit';
  static const String orderList = '/orders';
  static const String orderCreate = '/orders/create';
  static const String orderDetail = '/orders/detail';
  static const String orderEdit = '/orders/edit';

  static const String projectList = '/projects';
  static const String projectCreate = '/projects/create';
  static const String projectDetail = '/projects/detail';
  static const String projectEdit = '/projects/edit';
  static const String overview_dashboardDashboard =
      '/overview_dashboards/dashboard';

  // ── END GENERATOR ROUTE CONSTANTS ────────────────────────────────────────────

  // ── Route factory ─────────────────────────────────────────────────────────
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case login:
        final args = settings.arguments as Map<String, dynamic>?;
        final addAccount = args?['addAccount'] as bool? ?? false;
        return MaterialPageRoute(
          builder: (_) => LoginPage(addAccount: addAccount),
          settings: settings,
        );

      case register:
        return MaterialPageRoute(
          builder: (_) => const RegisterPage(),
          settings: settings,
        );

      case home:
        return MaterialPageRoute(
          builder: (_) => const ShellPage(),
          settings: settings,
        );

      case accountPicker:
        final args = settings.arguments as Map<String, dynamic>?;
        final mode = args?['mode'] == 'add'
            ? AccountPickerMode.add
            : AccountPickerMode.picker;
        return MaterialPageRoute(
          builder: (_) => AccountPickerPage(mode: mode),
          settings: settings,
        );

      // ── Category routes (generated 2026-02-27) ──
      case categoryList:
        return MaterialPageRoute(
          builder: (_) => BlocProvider<CategoryBloc>(
            create: (_) => sl<CategoryBloc>()..add(CategoryLoadAllRequested()),
            child: const CategoryListPage(),
          ),
          settings: settings,
        );

      case categoryCreate:
        return MaterialPageRoute(
          builder: (_) => BlocProvider<CategoryBloc>(
            create: (_) => sl<CategoryBloc>(),
            child: const CategoryFormPage(mode: cFormMode.create),
          ),
          settings: settings,
        );

      case categoryDetail:
        final args = settings.arguments as Map<String, dynamic>?;
        final id = args?['id'] as String? ?? '';
        return MaterialPageRoute(
          builder: (_) => BlocProvider<CategoryBloc>(
            create: (_) =>
                sl<CategoryBloc>()..add(CategoryLoadOneRequested(id)),
            child: const CategoryDetailPage(),
          ),
          settings: settings,
        );

      case categoryEdit:
        final args = settings.arguments as Map<String, dynamic>?;
        final id = args?['id'] as String? ?? '';
        return MaterialPageRoute(
          builder: (_) => BlocProvider<CategoryBloc>(
            create: (_) => sl<CategoryBloc>(),
            child: CategoryFormPage(mode: cFormMode.edit, id: id),
          ),
          settings: settings,
        );

      // ── Visit routes (generated 2026-02-27) ──
      case visitList:
        return MaterialPageRoute(
          builder: (_) => BlocProvider<VisitBloc>(
            create: (_) => sl<VisitBloc>()..add(VisitLoadAllRequested()),
            child: const VisitListPage(),
          ),
          settings: settings,
        );

      case visitCreate:
        return MaterialPageRoute(
          builder: (_) => BlocProvider<VisitBloc>(
            create: (_) => sl<VisitBloc>(),
            child: const VisitFormPage(mode: FormModee.create),
          ),
          settings: settings,
        );

      case visitDetail:
        final args = settings.arguments as Map<String, dynamic>?;
        final id = args?['id'] as String? ?? '';
        return MaterialPageRoute(
          builder: (_) => BlocProvider<VisitBloc>(
            create: (_) => sl<VisitBloc>()..add(VisitLoadOneRequested(id)),
            child: const VisitDetailPage(),
          ),
          settings: settings,
        );

      case visitEdit:
        final args = settings.arguments as Map<String, dynamic>?;
        final id = args?['id'] as String? ?? '';
        return MaterialPageRoute(
          builder: (_) => BlocProvider<VisitBloc>(
            create: (_) => sl<VisitBloc>(),
            child: VisitFormPage(mode: FormModee.edit, id: id),
          ),
          settings: settings,
        );

      // Hello routes (Level 1, generated 2026-02-27)
      case helloList:
        return MaterialPageRoute(
          builder: (_) => BlocProvider(
            create: (_) => sl<HelloBloc>()..add(HelloLoadAllRequested()),
            child: const HelloListPage(),
          ),
          settings: settings,
        );

      case helloCreate:
        return MaterialPageRoute(
          builder: (_) => BlocProvider(
            create: (_) => sl<HelloBloc>(),
            child: const HelloFormPage(mode: HelloFormMode.create),
          ),
          settings: settings,
        );

      case helloDetail:
        final args = settings.arguments as Map<String, dynamic>? ?? {};
        final id = args['id'] as String? ?? '';
        return MaterialPageRoute(
          builder: (_) => BlocProvider(
            create: (_) => sl<HelloBloc>()..add(HelloLoadOneRequested(id)),
            child: const HelloDetailPage(),
          ),
          settings: settings,
        );

      case helloEdit:
        final args = settings.arguments as Map<String, dynamic>? ?? {};
        final id = args['id'] as String? ?? '';
        return MaterialPageRoute(
          builder: (_) => BlocProvider(
            create: (_) => sl<HelloBloc>()..add(HelloLoadOneRequested(id)),
            child: HelloFormPage(mode: HelloFormMode.edit, id: id),
          ),
          settings: settings,
        );

      // Order routes (Level 3, generated 2026-03-01)
      case orderList:
        return MaterialPageRoute(
          builder: (_) => BlocProvider(
            create: (_) => sl<OrderBloc>()..add(OrderLoadAllRequested()),
            child: const OrderListPage(),
          ),
          settings: settings,
        );

      case orderCreate:
        return MaterialPageRoute(
          builder: (_) => BlocProvider(
            create: (_) => sl<OrderBloc>(),
            child: const OrderFormPage(mode: FormMode.create),
          ),
          settings: settings,
        );

      case orderDetail:
        final args = settings.arguments as Map<String, dynamic>? ?? {};
        final id = args['id'] as String? ?? '';
        return MaterialPageRoute(
          builder: (_) => BlocProvider(
            create: (_) => sl<OrderBloc>()..add(OrderLoadOneRequested(id)),
            child: const OrderDetailPage(),
          ),
          settings: settings,
        );

      case orderEdit:
        final args = settings.arguments as Map<String, dynamic>? ?? {};
        final id = args['id'] as String? ?? '';
        return MaterialPageRoute(
          builder: (_) => BlocProvider(
            create: (_) => sl<OrderBloc>()..add(OrderLoadOneRequested(id)),
            child: OrderFormPage(mode: FormMode.edit, id: id),
          ),
          settings: settings,
        );

      // Project routes (Level 2, generated 2026-03-01)
      case projectList:
        return MaterialPageRoute(
          builder: (_) => BlocProvider(
            create: (_) => sl<ProjectBloc>()..add(ProjectLoadAllRequested()),
            child: const ProjectListPage(),
          ),
          settings: settings,
        );

      case projectCreate:
        return MaterialPageRoute(
          builder: (_) => BlocProvider(
            create: (_) => sl<ProjectBloc>(),
            child: const ProjectFormPage(mode: FormMode.create),
          ),
          settings: settings,
        );

      case projectDetail:
        final args = settings.arguments as Map<String, dynamic>? ?? {};
        final id = args['id'] as String? ?? '';
        return MaterialPageRoute(
          builder: (_) => BlocProvider(
            create: (_) => sl<ProjectBloc>()..add(ProjectLoadOneRequested(id)),
            child: const ProjectDetailPage(),
          ),
          settings: settings,
        );

      case projectEdit:
        final args = settings.arguments as Map<String, dynamic>? ?? {};
        final id = args['id'] as String? ?? '';
        return MaterialPageRoute(
          builder: (_) => BlocProvider(
            create: (_) => sl<ProjectBloc>()..add(ProjectLoadOneRequested(id)),
            child: ProjectFormPage(mode: FormMode.edit, id: id),
          ),
          settings: settings,
        );

      // Overview routes (Level 4 Aggregator, generated 2026-03-01)
      case overview_dashboardDashboard:
        return MaterialPageRoute(
          builder: (_) => BlocProvider(
            create: (_) => sl<OverviewDashboardCubit>()..load(),
            child: const OverviewDashboardDashboardPage(),
          ),
          settings: settings,
        );
      // ── GENERATOR ROUTES — append only ─────────────────────────
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(child: Text('Route "${settings.name}" not found')),
          ),
        );
    }
  }
}
