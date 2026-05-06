// app_router.dart
// -------------------------------------------------------------
// Application routing — GoRouter configuration.
// All 21 features wired. Seq 1 (Shell) + Seq 2 (Auth) are the
// foundation; Seq 3–21 register inside the ShellRoute.
// -------------------------------------------------------------

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../core/enums/form_mode.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/presentation/bloc/auth_state.dart';
import '../../features/auth/domain/entities/account_session.dart';
import '../../features/auth/presentation/pages/account_picker_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/dashboard/presentation/pages/dashboard_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/auth/presentation/bloc/auth_event.dart';
import '../../features/auth/presentation/pages/wrong_app_page.dart';
import '../../features/auth/presentation/pages/pending_activation_page.dart';
import '../../core/rbac/rbac_extensions.dart';
// hide HomeTab — it is also defined in shell_page_home_tab.dart
import '../shell/shell_page_home_tab.dart';
import '../shell/shell_nav_items.dart';
import '../../customnav/adaptive_nav_shell.dart';

// -- GENERATOR FEATURE PAGE IMPORTS — append only ----------------------

// Actor (HMSCP core — L1)
import '../../features/actor/presentation/pages/actor_list_page.dart';
import '../../features/actor/presentation/pages/actor_detail_page.dart';
import '../../features/actor/presentation/pages/actor_form_page.dart';
import '../../features/actor/presentation/bloc/actor_bloc.dart';
import '../../features/actor/presentation/bloc/actor_event.dart';

// Phase 3 — External Integrations (L5)
import '../../features/sms_gateway/presentation/cubit/sms_gateway_cubit.dart';
import '../../features/sms_gateway/presentation/pages/sms_gateway_page.dart';
import '../../features/whatsapp/presentation/cubit/whatsapp_cubit.dart';
import '../../features/whatsapp/presentation/pages/whatsapp_page.dart';
import '../../features/mobile_money/presentation/cubit/mobile_money_cubit.dart';
import '../../features/mobile_money/presentation/pages/mobile_money_page.dart';

// Phase 4 — Officers (L2)
import '../../features/officer/presentation/bloc/officer_bloc.dart';
import '../../features/officer/presentation/bloc/officer_event.dart';
import '../../features/officer/presentation/pages/officer_list_page.dart';
import '../../features/officer/presentation/pages/officer_detail_page.dart';
import '../../features/officer/presentation/pages/officer_form_page.dart';

// Phase 4 — Customers (L1)
import '../../features/customer/presentation/bloc/customer_bloc.dart';
import '../../features/customer/presentation/bloc/customer_event.dart';
import '../../features/customer/presentation/pages/customer_list_page.dart';
import '../../features/customer/presentation/pages/customer_detail_page.dart';
import '../../features/customer/presentation/pages/customer_form_page.dart';

// Phase 5 — Categories (L1)
import '../../features/category/presentation/bloc/category_bloc.dart';
import '../../features/category/presentation/bloc/category_event.dart';
import '../../features/category/presentation/pages/category_list_page.dart';
import '../../features/category/presentation/pages/category_detail_page.dart';
import '../../features/category/presentation/pages/category_form_page.dart';

// Phase 5 — Products (L2)
import '../../features/product/presentation/bloc/product_bloc.dart';
import '../../features/product/presentation/bloc/product_event.dart';
import '../../features/product/presentation/pages/product_list_page.dart';
import '../../features/product/presentation/pages/product_detail_page.dart';
import '../../features/product/presentation/pages/product_form_page.dart';

// Phase 6 — Promotions (L3)
import '../../features/promotion/presentation/bloc/promotion_bloc.dart';
import '../../features/promotion/presentation/bloc/promotion_event.dart';
import '../../features/promotion/presentation/pages/promotion_list_page.dart';
import '../../features/promotion/presentation/pages/promotion_detail_page.dart';
import '../../features/promotion/presentation/pages/promotion_form_page.dart';
import '../../features/promotion/presentation/enums/promotion_form_node.dart'
    show PromotionFormNode;

// Phase 7 — Field Operations
import '../../features/visit/presentation/bloc/visit_bloc.dart';
import '../../features/visit/presentation/bloc/visit_event.dart';
import '../../features/visit/presentation/pages/visit_list_page.dart';
import '../../features/visit/presentation/pages/visit_detail_page.dart';
import '../../features/visit/presentation/pages/visit_form_page.dart';

import '../../features/weekly_plan/presentation/bloc/weekly_plan_bloc.dart';
import '../../features/weekly_plan/presentation/bloc/weekly_plan_event.dart';
import '../../features/weekly_plan/presentation/pages/weekly_plan_list_page.dart';
import '../../features/weekly_plan/presentation/pages/weekly_plan_detail_page.dart';
import '../../features/weekly_plan/presentation/pages/weekly_plan_form_page.dart';

import '../../features/daily_report/presentation/bloc/daily_report_bloc.dart';
import '../../features/daily_report/presentation/bloc/daily_report_event.dart';
import '../../features/daily_report/presentation/pages/daily_report_list_page.dart';
import '../../features/daily_report/presentation/pages/daily_report_detail_page.dart';
import '../../features/daily_report/presentation/pages/daily_report_form_page.dart';

// Phase 8 — Communication & Commerce
import '../../features/conversation/presentation/bloc/conversation_bloc.dart';
import '../../features/conversation/presentation/bloc/conversation_event.dart';
import '../../features/conversation/presentation/pages/conversation_list_page.dart';
import '../../features/conversation/presentation/pages/conversation_detail_page.dart';
import '../../features/conversation/presentation/pages/conversation_form_page.dart';

import '../../features/order/presentation/bloc/order_bloc.dart';
import '../../features/order/presentation/bloc/order_event.dart';
import '../../features/order/presentation/pages/order_list_page.dart';
import '../../features/order/presentation/pages/order_detail_page.dart';
import '../../features/order/presentation/pages/order_form_page.dart';

import '../../features/payment/presentation/bloc/payment_bloc.dart';
import '../../features/payment/presentation/bloc/payment_event.dart';
import '../../features/payment/presentation/pages/payment_list_page.dart';
import '../../features/payment/presentation/pages/payment_detail_page.dart';
import '../../features/payment/presentation/pages/payment_form_page.dart';

import '../../features/notification/presentation/bloc/notification_bloc.dart';
import '../../features/notification/presentation/bloc/notification_event.dart';
import '../../features/notification/presentation/pages/notification_list_page.dart';
import '../../features/notification/presentation/pages/notification_detail_page.dart';
import '../../features/notification/presentation/pages/notification_form_page.dart';

// Phase 9 — Analytics & Reporting
import '../../features/marketing_dashboard/presentation/cubit/marketing_dashboard_cubit.dart';
import '../../features/marketing_dashboard/presentation/pages/marketing_dashboard_dashboard_page.dart';

import '../../features/sales_dashboard/presentation/cubit/sales_dashboard_cubit.dart';
import '../../features/sales_dashboard/presentation/pages/sales_dashboard_dashboard_page.dart';

import '../../features/report_export/presentation/cubit/report_export_cubit.dart';
import '../../features/report_export/presentation/pages/report_export_page.dart';

import '../../features/activity_log/presentation/bloc/activity_log_bloc.dart';
import '../../features/activity_log/presentation/bloc/activity_log_event.dart';
import '../../features/activity_log/presentation/pages/activity_log_list_page.dart';
import '../../features/activity_log/presentation/pages/activity_log_detail_page.dart';

// -- FormNode enums -----------------------------------------
import '../../features/officer/presentation/enums/officer_form_node.dart';
import '../../features/customer/presentation/pages/customer_form_page.dart'
    show CustomerFormMode;
import '../../features/category/presentation/pages/category_form_page.dart'
    show CategoryFormMode;
import '../../features/product/presentation/enums/product_form_node.dart';
import '../../features/visit/presentation/enums/visit_form_node.dart';
import '../../features/weekly_plan/presentation/enums/weekly_plan_form_node.dart';
import '../../features/daily_report/presentation/enums/daily_report_form_node.dart';
import '../../features/order/presentation/enums/order_form_node.dart';
import '../../features/conversation/presentation/pages/conversation_form_page.dart'
    show ConversationFormMode;
import '../../features/payment/presentation/pages/payment_form_page.dart'
    show PaymentFormMode;
import '../../features/notification/presentation/enums/notification_form_node.dart';

import '../../config/di/injection_container.dart';

import '../../features/organization/presentation/bloc/organization_bloc.dart';
import '../../features/organization/presentation/bloc/organization_event.dart';
import '../../features/organization/presentation/pages/organization_hub_page.dart';

// -- END GENERATOR FEATURE PAGE IMPORTS --------------------------------

class AppRouter {
  // -- Core routes ---------------------------------------------
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String accountPicker = '/account-picker';
  static const String wrongApp = '/wrong-app';
  static const String pendingActivation = '/pending-activation';
  static const String home = '/home';
  static const String dashboard = '/dashboard';
  static const String profile = '/profile';
  static const String orgHub = '/organization';

  // -- GENERATOR ROUTE CONSTANTS — append only -----------------

  // Actor (HMSCP core)
  static const String actorList = '/actors';
  static const String actorCreate = '/actors/create';
  static const String actorDetail = '/actors/:id';
  static const String actorEdit = '/actors/:id/edit';
  static String actorDetailPath(String id) => '/actors/$id';
  static String actorEditPath(String id) => '/actors/$id/edit';

  // Phase 3
  static const String smsGateway = '/integrations/sms';
  static const String whatsapp = '/integrations/whatsapp';
  static const String mobileMoney = '/integrations/mobile-money';

  // Phase 4 — Officers
  static const String officerList = '/officers';
  static const String officerCreate = '/officers/create';
  static const String officerDetail = '/officers/:id';
  static const String officerEdit = '/officers/:id/edit';
  static String officerDetailPath(String id) => '/officers/$id';
  static String officerEditPath(String id) => '/officers/$id/edit';

  // Phase 4 — Customers
  static const String customerList = '/customers';
  static const String customerCreate = '/customers/create';
  static const String customerDetail = '/customers/:id';
  static const String customerEdit = '/customers/:id/edit';
  static String customerDetailPath(String id) => '/customers/$id';
  static String customerEditPath(String id) => '/customers/$id/edit';

  // Phase 5 — Categories
  static const String categoryList = '/categories';
  static const String categoryCreate = '/categories/create';
  static const String categoryDetail = '/categories/:id';
  static const String categoryEdit = '/categories/:id/edit';
  static String categoryDetailPath(String id) => '/categories/$id';
  static String categoryEditPath(String id) => '/categories/$id/edit';

  // Phase 5 — Products
  static const String productList = '/products';
  static const String productCreate = '/products/create';
  static const String productDetail = '/products/:id';
  static const String productEdit = '/products/:id/edit';
  static String productDetailPath(String id) => '/products/$id';
  static String productEditPath(String id) => '/products/$id/edit';

  // Phase 6 — Promotions
  static const String promotionList = '/promotions';
  static const String promotionCreate = '/promotions/create';
  static const String promotionDetail = '/promotions/:id';
  static const String promotionEdit = '/promotions/:id/edit';
  static String promotionDetailPath(String id) => '/promotions/$id';
  static String promotionEditPath(String id) => '/promotions/$id/edit';

  // Phase 7 — Visits
  static const String visitList = '/visits';
  static const String visitCreate = '/visits/create';
  static const String visitDetail = '/visits/:id';
  static const String visitEdit = '/visits/:id/edit';
  static String visitDetailPath(String id) => '/visits/$id';
  static String visitEditPath(String id) => '/visits/$id/edit';

  // Phase 7 — Weekly Plans
  static const String weeklyPlanList = '/weekly-plans';
  static const String weeklyPlanCreate = '/weekly-plans/create';
  static const String weeklyPlanDetail = '/weekly-plans/:id';
  static const String weeklyPlanEdit = '/weekly-plans/:id/edit';
  static String weeklyPlanDetailPath(String id) => '/weekly-plans/$id';
  static String weeklyPlanEditPath(String id) => '/weekly-plans/$id/edit';

  // Phase 7 — Daily Reports
  static const String dailyReportList = '/daily-reports';
  static const String dailyReportCreate = '/daily-reports/create';
  static const String dailyReportDetail = '/daily-reports/:id';
  static const String dailyReportEdit = '/daily-reports/:id/edit';
  static String dailyReportDetailPath(String id) => '/daily-reports/$id';
  static String dailyReportEditPath(String id) => '/daily-reports/$id/edit';

  // Phase 8 — Conversations
  static const String conversationList = '/conversations';
  static const String conversationCreate = '/conversations/create';
  static const String conversationDetail = '/conversations/:id';
  static const String conversationEdit = '/conversations/:id/edit';
  static String conversationDetailPath(String id) => '/conversations/$id';
  static String conversationEditPath(String id) => '/conversations/$id/edit';

  // Phase 8 — Orders
  static const String orderList = '/orders';
  static const String orderCreate = '/orders/create';
  static const String orderDetail = '/orders/:id';
  static const String orderEdit = '/orders/:id/edit';
  static String orderDetailPath(String id) => '/orders/$id';
  static String orderEditPath(String id) => '/orders/$id/edit';

  // Phase 8 — Payments
  static const String paymentList = '/payments';
  static const String paymentCreate = '/payments/create';
  static const String paymentDetail = '/payments/:id';
  static const String paymentEdit = '/payments/:id/edit';
  static String paymentDetailPath(String id) => '/payments/$id';
  static String paymentEditPath(String id) => '/payments/$id/edit';

  // Phase 8 — Notifications
  static const String notificationList = '/notifications';
  static const String notificationCreate = '/notifications/create';
  static const String notificationDetail = '/notifications/:id';
  static const String notificationEdit = '/notifications/:id/edit';
  static String notificationDetailPath(String id) => '/notifications/$id';
  static String notificationEditPath(String id) => '/notifications/$id/edit';

  // Phase 9
  static const String marketingDashboard = '/analytics/marketing';
  static const String salesDashboard = '/analytics/sales';
  static const String reportExport = '/analytics/export';
  static const String activityLogList = '/activity-logs';
  static const String activityLogDetail = '/activity-logs/:id';
  static String activityLogDetailPath(String id) => '/activity-logs/$id';

  // -- END GENERATOR ROUTE CONSTANTS --------------------------

  static GoRouter createRouter(AuthBloc authBloc) {
    final notifier = AuthRouterNotifier(authBloc);

    return GoRouter(
      initialLocation: splash,
      refreshListenable: notifier,
      redirect: (context, state) =>
          _redirect(authBloc.state, state.matchedLocation),
      routes: [
        GoRoute(path: splash, builder: (_, _) => const _SplashScreen()),

        GoRoute(
          path: login,
          builder: (_, routeState) {
            final args = routeState.extra as Map<String, dynamic>?;
            return BlocProvider.value(
              value: authBloc,
              child: LoginPage(
                addAccount: args?['addAccount'] as bool? ?? false,
              ),
            );
          },
        ),

        GoRoute(
          path: register,
          builder: (_, routeState) {
            final args = routeState.extra as Map<String, dynamic>?;
            return BlocProvider.value(
              value: authBloc,
              child: RegisterPage(
                addAccount: args?['addAccount'] as bool? ?? false,
              ),
            );
          },
        ),
        GoRoute(
          path: wrongApp,
          builder: (_, __) => const WrongAppPage(officerInAdminApp: true),
        ),

        GoRoute(
          path: pendingActivation,
          builder: (_, __) => const PendingActivationPage(),
        ),

        GoRoute(
          path: accountPicker,
          builder: (_, routeState) {
            final args = routeState.extra as Map<String, dynamic>?;
            final mode = args?['mode'] == 'add'
                ? AccountPickerMode.add
                : AccountPickerMode.picker;
            final authState = authBloc.state;
            List<AccountSession> initialAccounts = [];
            String? initialActiveEmail;
            if (authState is AuthAuthenticated) {
              initialAccounts = authState.savedAccounts;
              initialActiveEmail = authState.activeSession.user.email;
            } else if (authState is AuthNeedsAccountPicker) {
              initialAccounts = authState.savedAccounts;
            } else if (authState is AuthAccountsUpdated) {
              initialAccounts = authState.savedAccounts;
              initialActiveEmail = authState.activeSession.user.email;
            }
            return BlocProvider.value(
              value: authBloc,
              child: AccountPickerPage(
                mode: mode,
                initialAccounts: initialAccounts,
                initialActiveEmail: initialActiveEmail,
              ),
            );
          },
        ),

        // -- Authenticated shell -----------------------------
        ShellRoute(
          builder: (context, state, child) {
            final authState = context.read<AuthBloc>().state;
            if (authState is! AuthAuthenticated) return child;
            return AdaptiveNavShell(
              router: GoRouter.of(context),
              items: ShellNavItems.buildNavItems(auth: authState),
              railFooter: _LogoutFooter(),
              child: child,
            );
          },
          routes: [
            GoRoute(path: home, builder: (_, _) => const HomeTab()),
            GoRoute(path: dashboard, builder: (_, _) => const DashboardPage()),
            GoRoute(path: profile, builder: (_, _) => const ProfilePage()),

            // -- GENERATOR ROUTES — append only --------------

            // --- Actor (HMSCP core, L1) ---------------------
            GoRoute(
              path: actorList,
              builder: (_, _) => BlocProvider(
                create: (_) => sl<ActorBloc>()..add(ActorLoadAllRequested()),
                child: const ActorListPage(),
              ),
            ),
            GoRoute(
              path: actorCreate,
              builder: (_, _) => BlocProvider(
                create: (_) => sl<ActorBloc>(),
                child: const ActorFormPage(mode: ActorFormMode.create),
              ),
            ),
            GoRoute(
              path: actorDetail,
              builder: (_, s) {
                final id = s.pathParameters['id'] ?? '';
                return BlocProvider(
                  create: (_) =>
                      sl<ActorBloc>()..add(ActorLoadOneRequested(id)),
                  child: const ActorDetailPage(),
                );
              },
            ),
            GoRoute(
              path: actorEdit,
              builder: (_, s) {
                final id = s.pathParameters['id'] ?? '';
                return BlocProvider(
                  create: (_) =>
                      sl<ActorBloc>()..add(ActorLoadOneRequested(id)),
                  child: ActorFormPage(mode: ActorFormMode.edit, id: id),
                );
              },
            ),

            // --- Phase 3 — Integrations (L5) ----------------
            GoRoute(
              path: smsGateway,
              builder: (_, _) => BlocProvider(
                create: (_) => sl<SmsGatewayCubit>(),
                child: const SmsGatewayPage(),
              ),
            ),
            GoRoute(
              path: whatsapp,
              builder: (_, _) => BlocProvider(
                create: (_) => sl<WhatsappCubit>(),
                child: const WhatsappPage(),
              ),
            ),
            GoRoute(
              path: mobileMoney,
              builder: (_, _) => BlocProvider(
                create: (_) => sl<MobileMoneyCubit>(),
                child: const MobileMoneyPage(),
              ),
            ),

            // --- Phase 4 — Officers (L2) --------------------
            GoRoute(
              path: orgHub,
              builder: (_, _) => BlocProvider(
                create: (_) => sl<OrganizationBloc>()..add(OrgLoadRequested()),
                child: const OrganizationHubPage(),
              ),
            ),
            GoRoute(
              path: officerList,
              builder: (_, _) => BlocProvider(
                create: (_) =>
                    sl<OfficerBloc>()..add(OfficerLoadAllRequested()),
                child: const OfficerListPage(),
              ),
            ),
            GoRoute(
              path: officerCreate,
              builder: (_, _) => MultiBlocProvider(
                providers: [
                  BlocProvider(create: (_) => sl<OfficerBloc>()),
                  BlocProvider(
                    create: (_) => sl<OrganizationBloc>()
                      ..add(BranchesLoadRequested())
                      ..add(RolesLoadRequested()),
                  ),
                ],
                child: const OfficerFormPage(mode: OfficerFormNode.create),
              ),
            ),
            GoRoute(
              path: officerDetail,
              builder: (_, s) {
                final id = s.pathParameters['id'] ?? '';
                return MultiBlocProvider(
                  providers: [
                    BlocProvider(
                      create: (_) =>
                          sl<OfficerBloc>()..add(OfficerLoadOneRequested(id)),
                    ),
                    BlocProvider(
                      create: (_) => sl<OrganizationBloc>()
                        ..add(BranchesLoadRequested())
                        ..add(RolesLoadRequested()),
                    ),
                  ],
                  child: const OfficerDetailPage(),
                );
              },
            ),
            GoRoute(
              path: officerEdit,
              builder: (_, s) {
                final id = s.pathParameters['id'] ?? '';
                return MultiBlocProvider(
                  providers: [
                    BlocProvider(
                      create: (_) =>
                          sl<OfficerBloc>()..add(OfficerLoadOneRequested(id)),
                    ),
                    BlocProvider(
                      create: (_) => sl<OrganizationBloc>()
                        ..add(BranchesLoadRequested())
                        ..add(RolesLoadRequested()),
                    ),
                  ],
                  child: OfficerFormPage(mode: OfficerFormNode.edit, id: id),
                );
              },
            ),

            // --- Phase 4 — Customers (L1) -------------------
            GoRoute(
              path: customerList,
              builder: (_, _) => BlocProvider(
                create: (_) =>
                    sl<CustomerBloc>()..add(CustomerLoadAllRequested()),
                child: const CustomerListPage(),
              ),
            ),
            GoRoute(
              path: customerCreate,
              builder: (_, _) => BlocProvider(
                create: (_) => sl<CustomerBloc>(),
                child: const CustomerFormPage(mode: CustomerFormMode.create),
              ),
            ),
            GoRoute(
              path: customerDetail,
              builder: (_, s) {
                final id = s.pathParameters['id'] ?? '';
                return BlocProvider(
                  create: (_) =>
                      sl<CustomerBloc>()..add(CustomerLoadOneRequested(id)),
                  child: const CustomerDetailPage(),
                );
              },
            ),
            GoRoute(
              path: customerEdit,
              builder: (_, s) {
                final id = s.pathParameters['id'] ?? '';
                return BlocProvider(
                  create: (_) =>
                      sl<CustomerBloc>()..add(CustomerLoadOneRequested(id)),
                  child: CustomerFormPage(mode: CustomerFormMode.edit, id: id),
                );
              },
            ),

            // --- Phase 5 — Categories (L1) ------------------
            GoRoute(
              path: categoryList,
              builder: (_, _) => BlocProvider(
                create: (_) =>
                    sl<CategoryBloc>()..add(CategoryLoadAllRequested()),
                child: const CategoryListPage(),
              ),
            ),
            GoRoute(
              path: categoryCreate,
              builder: (_, _) => BlocProvider(
                create: (_) => sl<CategoryBloc>(),
                child: const CategoryFormPage(mode: CategoryFormMode.create),
              ),
            ),
            GoRoute(
              path: categoryDetail,
              builder: (_, s) {
                final id = s.pathParameters['id'] ?? '';
                return BlocProvider(
                  create: (_) =>
                      sl<CategoryBloc>()..add(CategoryLoadOneRequested(id)),
                  child: const CategoryDetailPage(),
                );
              },
            ),
            GoRoute(
              path: categoryEdit,
              builder: (_, s) {
                final id = s.pathParameters['id'] ?? '';
                return BlocProvider(
                  create: (_) =>
                      sl<CategoryBloc>()..add(CategoryLoadOneRequested(id)),
                  child: CategoryFormPage(mode: CategoryFormMode.edit, id: id),
                );
              },
            ),

            // --- Phase 5 — Products (L2) --------------------
            GoRoute(
              path: productList,
              builder: (_, _) => BlocProvider(
                create: (_) =>
                    sl<ProductBloc>()..add(ProductLoadAllRequested()),
                child: const ProductListPage(),
              ),
            ),
            GoRoute(
              path: productCreate,
              builder: (_, _) => MultiBlocProvider(
                providers: [
                  BlocProvider(create: (_) => sl<ProductBloc>()),
                  BlocProvider(create: (_) => sl<CategoryBloc>()),
                ],
                child: ProductFormPage(mode: ProductFormNode.create),
              ),
            ),
            GoRoute(
              path: productDetail,
              builder: (_, s) {
                final id = s.pathParameters['id'] ?? '';
                return BlocProvider(
                  create: (_) =>
                      sl<ProductBloc>()..add(ProductLoadOneRequested(id)),
                  child: const ProductDetailPage(),
                );
              },
            ),
            GoRoute(
              path: productEdit,
              builder: (_, s) {
                final id = s.pathParameters['id'] ?? '';
                return MultiBlocProvider(
                  providers: [
                    BlocProvider(
                      create: (_) =>
                          sl<ProductBloc>()..add(ProductLoadOneRequested(id)),
                    ),
                    BlocProvider(create: (_) => sl<CategoryBloc>()),
                  ],
                  child: ProductFormPage(mode: ProductFormNode.edit, id: id),
                );
              },
            ),

            // --- Phase 6 — Promotions (L3) ------------------
            GoRoute(
              path: promotionList,
              builder: (_, _) => BlocProvider(
                create: (_) =>
                    sl<PromotionBloc>()..add(PromotionLoadAllRequested()),
                child: const PromotionListPage(),
              ),
            ),
            GoRoute(
              path: promotionCreate,
              builder: (_, _) => BlocProvider(
                create: (_) => sl<PromotionBloc>(),
                child: const PromotionFormPage(mode: PromotionFormNode.create),
              ),
            ),
            GoRoute(
              path: promotionDetail,
              builder: (_, s) {
                final id = s.pathParameters['id'] ?? '';
                return BlocProvider(
                  create: (_) =>
                      sl<PromotionBloc>()..add(PromotionLoadOneRequested(id)),
                  child: const PromotionDetailPage(),
                );
              },
            ),
            GoRoute(
              path: promotionEdit,
              builder: (_, s) {
                final id = s.pathParameters['id'] ?? '';
                return BlocProvider(
                  create: (_) =>
                      sl<PromotionBloc>()..add(PromotionLoadOneRequested(id)),
                  child: PromotionFormPage(
                    mode: PromotionFormNode.edit,
                    id: id,
                  ),
                );
              },
            ),

            // --- Phase 7 — Visits (L2) ---------------------
            GoRoute(
              path: visitList,
              builder: (_, _) => BlocProvider(
                create: (_) => sl<VisitBloc>()..add(VisitLoadAllRequested()),
                child: const VisitListPage(),
              ),
            ),
            GoRoute(
              path: visitCreate,
              builder: (_, _) => BlocProvider(
                create: (_) => sl<VisitBloc>(),
                child: const VisitFormPage(mode: VisitFormNode.create),
              ),
            ),
            GoRoute(
              path: visitDetail,
              builder: (_, s) {
                final id = s.pathParameters['id'] ?? '';
                return BlocProvider(
                  create: (_) =>
                      sl<VisitBloc>()..add(VisitLoadOneRequested(id)),
                  child: VisitDetailPage(visitId: id),
                );
              },
            ),
            GoRoute(
              path: visitEdit,
              builder: (_, s) {
                final id = s.pathParameters['id'] ?? '';
                return BlocProvider(
                  create: (_) =>
                      sl<VisitBloc>()..add(VisitLoadOneRequested(id)),
                  child: VisitFormPage(mode: VisitFormNode.edit, id: id),
                );
              },
            ),

            // --- Phase 7 — Weekly Plans (L2) ----------------
            GoRoute(
              path: weeklyPlanList,
              builder: (_, _) => BlocProvider(
                create: (_) =>
                    sl<WeeklyPlanBloc>()..add(WeeklyPlanLoadAllRequested()),
                child: const WeeklyPlanListPage(),
              ),
            ),
            GoRoute(
              path: weeklyPlanCreate,
              builder: (_, _) => BlocProvider(
                create: (_) => sl<WeeklyPlanBloc>(),
                child: const WeeklyPlanFormPage(
                  mode: WeeklyPlanFormNode.create,
                ),
              ),
            ),
            GoRoute(
              path: weeklyPlanDetail,
              builder: (_, s) {
                final id = s.pathParameters['id'] ?? '';
                return BlocProvider(
                  create: (_) =>
                      sl<WeeklyPlanBloc>()..add(WeeklyPlanLoadOneRequested(id)),
                  child: const WeeklyPlanDetailPage(),
                );
              },
            ),
            GoRoute(
              path: weeklyPlanEdit,
              builder: (_, s) {
                final id = s.pathParameters['id'] ?? '';
                return BlocProvider(
                  create: (_) =>
                      sl<WeeklyPlanBloc>()..add(WeeklyPlanLoadOneRequested(id)),
                  child: WeeklyPlanFormPage(
                    mode: WeeklyPlanFormNode.edit,
                    id: id,
                  ),
                );
              },
            ),

            // --- Phase 7 — Daily Reports (L3) --------------
            GoRoute(
              path: dailyReportList,
              builder: (_, _) => BlocProvider(
                create: (_) =>
                    sl<DailyReportBloc>()..add(DailyReportLoadAllRequested()),
                child: const DailyReportListPage(),
              ),
            ),
            GoRoute(
              path: dailyReportCreate,
              builder: (_, _) => BlocProvider(
                create: (_) => sl<DailyReportBloc>(),
                child: const DailyReportFormPage(
                  mode: DailyReportFormNode.create,
                ),
              ),
            ),
            GoRoute(
              path: dailyReportDetail,
              builder: (_, s) {
                final id = s.pathParameters['id'] ?? '';
                return BlocProvider(
                  create: (_) =>
                      sl<DailyReportBloc>()
                        ..add(DailyReportLoadOneRequested(id)),
                  child: const DailyReportDetailPage(),
                );
              },
            ),
            GoRoute(
              path: dailyReportEdit,
              builder: (_, s) {
                final id = s.pathParameters['id'] ?? '';
                return BlocProvider(
                  create: (_) =>
                      sl<DailyReportBloc>()
                        ..add(DailyReportLoadOneRequested(id)),
                  child: DailyReportFormPage(
                    mode: DailyReportFormNode.edit,
                    id: id,
                  ),
                );
              },
            ),

            // --- Phase 8 — Conversations (L1) --------------
            GoRoute(
              path: conversationList,
              builder: (_, _) => BlocProvider(
                create: (_) =>
                    sl<ConversationBloc>()..add(ConversationLoadAllRequested()),
                child: const ConversationListPage(),
              ),
            ),
            GoRoute(
              path: conversationCreate,
              builder: (_, _) => MultiBlocProvider(
                providers: [
                  BlocProvider(create: (_) => sl<ConversationBloc>()),
                  BlocProvider(
                    create: (_) =>
                        sl<ActorBloc>()..add(ActorLoadAllRequested()),
                  ),
                  BlocProvider(
                    create: (_) =>
                        sl<OfficerBloc>()..add(OfficerLoadAllRequested()),
                  ),
                  BlocProvider(
                    create: (_) =>
                        sl<CustomerBloc>()..add(CustomerLoadAllRequested()),
                  ),
                ],
                child: const ConversationFormPage(
                  mode: ConversationFormMode.create,
                ),
              ),
            ),
            GoRoute(
              path: conversationDetail,
              builder: (_, s) {
                final id = s.pathParameters['id'] ?? '';
                return MultiBlocProvider(
                  providers: [
                    BlocProvider(
                      create: (_) =>
                          sl<ConversationBloc>()
                            ..add(ConversationLoadOneRequested(id)),
                    ),
                    // FIX #7: Provide ActorBloc so the detail page can
                    // populate availableContacts for the "Add Member" sheet.
                    BlocProvider(
                      create: (_) =>
                          sl<ActorBloc>()..add(ActorLoadAllRequested()),
                    ),
                  ],
                  child: const ConversationDetailPage(),
                );
              },
            ),
            GoRoute(
              path: conversationEdit,
              builder: (_, s) {
                final id = s.pathParameters['id'] ?? '';
                return MultiBlocProvider(
                  providers: [
                    BlocProvider(
                      create: (_) =>
                          sl<ConversationBloc>()
                            ..add(ConversationLoadOneRequested(id)),
                    ),
                    BlocProvider(
                      create: (_) =>
                          sl<ActorBloc>()..add(ActorLoadAllRequested()),
                    ),
                    BlocProvider(
                      create: (_) =>
                          sl<OfficerBloc>()..add(OfficerLoadAllRequested()),
                    ),
                    BlocProvider(
                      create: (_) =>
                          sl<CustomerBloc>()..add(CustomerLoadAllRequested()),
                    ),
                  ],
                  child: ConversationFormPage(
                    mode: ConversationFormMode.edit,
                    id: id,
                  ),
                );
              },
            ),
            // --- Phase 8 — Orders (L3) ---------------------
            GoRoute(
              path: orderList,
              builder: (_, _) => BlocProvider(
                create: (_) => sl<OrderBloc>()..add(OrderLoadAllRequested()),
                child: const OrderListPage(),
              ),
            ),
            GoRoute(
              path: orderCreate,
              builder: (_, _) => BlocProvider(
                create: (_) => sl<OrderBloc>(),
                child: const OrderFormPage(mode: OrderFormNode.create),
              ),
            ),
            GoRoute(
              path: orderDetail,
              builder: (_, s) {
                final id = s.pathParameters['id'] ?? '';
                return BlocProvider(
                  create: (_) =>
                      sl<OrderBloc>()..add(OrderLoadOneRequested(id)),
                  child: const OrderDetailPage(),
                );
              },
            ),
            GoRoute(
              path: orderEdit,
              builder: (_, s) {
                final id = s.pathParameters['id'] ?? '';
                return BlocProvider(
                  create: (_) =>
                      sl<OrderBloc>()..add(OrderLoadOneRequested(id)),
                  child: OrderFormPage(mode: OrderFormNode.edit, id: id),
                );
              },
            ),

            // --- Phase 8 — Payments (L1) --------------------
            GoRoute(
              path: paymentList,
              builder: (_, _) => BlocProvider(
                create: (_) =>
                    sl<PaymentBloc>()..add(PaymentLoadAllRequested()),
                child: const PaymentListPage(),
              ),
            ),
            GoRoute(
              path: paymentCreate,
              builder: (_, _) => BlocProvider(
                create: (_) => sl<PaymentBloc>(),
                child: const PaymentFormPage(mode: PaymentFormMode.create),
              ),
            ),
            GoRoute(
              path: paymentDetail,
              builder: (_, s) {
                final id = s.pathParameters['id'] ?? '';
                return BlocProvider(
                  create: (_) =>
                      sl<PaymentBloc>()..add(PaymentLoadOneRequested(id)),
                  child: const PaymentDetailPage(),
                );
              },
            ),
            GoRoute(
              path: paymentEdit,
              builder: (_, s) {
                final id = s.pathParameters['id'] ?? '';
                return BlocProvider(
                  create: (_) =>
                      sl<PaymentBloc>()..add(PaymentLoadOneRequested(id)),
                  child: PaymentFormPage(mode: PaymentFormMode.edit, id: id),
                );
              },
            ),

            // --- Phase 8 — Notifications (L2) --------------
            GoRoute(
              path: notificationList,
              builder: (_, _) => BlocProvider(
                create: (_) =>
                    sl<NotificationBloc>()..add(NotificationLoadAllRequested()),
                child: const NotificationListPage(),
              ),
            ),
            GoRoute(
              path: notificationCreate,
              builder: (_, _) => BlocProvider(
                create: (_) => sl<NotificationBloc>(),
                child: const NotificationFormPage(
                  mode: NotificationFormNode.create,
                ),
              ),
            ),
            GoRoute(
              path: notificationDetail,
              builder: (_, s) {
                final id = s.pathParameters['id'] ?? '';
                return BlocProvider(
                  create: (_) =>
                      sl<NotificationBloc>()
                        ..add(NotificationLoadOneRequested(id)),
                  child: const NotificationDetailPage(),
                );
              },
            ),
            GoRoute(
              path: notificationEdit,
              builder: (_, s) {
                final id = s.pathParameters['id'] ?? '';
                return BlocProvider(
                  create: (_) =>
                      sl<NotificationBloc>()
                        ..add(NotificationLoadOneRequested(id)),
                  child: NotificationFormPage(
                    mode: NotificationFormNode.edit,
                    id: id,
                  ),
                );
              },
            ),

            // --- Phase 9 — Marketing Dashboard (L4) --------
            GoRoute(
              path: marketingDashboard,
              builder: (_, _) => BlocProvider(
                create: (_) => sl<MarketingDashboardCubit>(),
                child: const MarketingDashboardDashboardPage(),
              ),
            ),

            // --- Phase 9 — Sales Dashboard (L4) ------------
            GoRoute(
              path: salesDashboard,
              builder: (_, _) => BlocProvider(
                create: (_) => sl<SalesDashboardCubit>(),
                child: const SalesDashboardDashboardPage(),
              ),
            ),

            // --- Phase 9 — Report Export (L5) --------------
            GoRoute(
              path: reportExport,
              builder: (_, _) => BlocProvider(
                create: (_) => sl<ReportExportCubit>(),
                child: const ReportExportPage(),
              ),
            ),

            // --- Phase 9 — Activity Logs (L1, read-only) ---
            GoRoute(
              path: activityLogList,
              builder: (_, _) => BlocProvider(
                create: (_) =>
                    sl<ActivityLogBloc>()..add(ActivityLogLoadAllRequested()),
                child: const ActivityLogListPage(),
              ),
            ),
            GoRoute(
              path: activityLogDetail,
              builder: (_, s) {
                final id = s.pathParameters['id'] ?? '';
                return BlocProvider(
                  create: (_) =>
                      sl<ActivityLogBloc>()
                        ..add(ActivityLogLoadOneRequested(id)),
                  child: ActivityLogDetailPage(id: id),
                );
              },
            ),

            // -- END GENERATOR ROUTES ------------------------
          ],
        ),
      ],

      errorBuilder: (context, state) =>
          Scaffold(body: Center(child: Text('Route "${state.uri}" not found'))),
    );
  }

  // -- Redirect logic ---------------------------------------
  static String? _redirect(AuthState authState, String location) {
    const authRoutes = {login, register, accountPicker, wrongApp};
    final isAuthRoute = authRoutes.contains(location);
    final isShellRoute = !isAuthRoute && location != splash;

    if (authState is AuthAuthenticated) {
      final hasNoRole =
          !authState.isAdminAppRole && !authState.isOfficerAppRole;

      // Only block pure field officers from admin app
      // Branch managers are allowed in admin app too
      final isPureOfficerInAdminApp =
          authState.isOfficerAppRole && !authState.isAdminAppRole;

      if (isShellRoute && hasNoRole && location != pendingActivation) {
        return pendingActivation;
      }
      if (isShellRoute && isPureOfficerInAdminApp) return wrongApp;

      if ((location == pendingActivation || location == wrongApp) &&
          !hasNoRole &&
          !isPureOfficerInAdminApp) {
        return home;
      }

      if (location == splash) return home;
      return null;
    }

    final isAuthRoute2 = {login, register, accountPicker}.contains(location);
    return switch (authState) {
      AuthInitial() => location == splash ? null : splash,
      AuthLoading() => isShellRoute ? splash : null,
      AuthAccountsUpdated() => location == splash ? home : null,
      AuthNeedsAccountPicker() => isAuthRoute2 ? null : accountPicker,
      AuthUnauthenticated() =>
        isShellRoute || location == splash ? login : null,
      AuthSwitching() => null,
      AuthFailureState() => isShellRoute ? login : null,
      _ => isShellRoute ? login : null,
    };
  }
}

// -- AuthRouterNotifier --------------------------------------
class AuthRouterNotifier extends ChangeNotifier {
  AuthRouterNotifier(AuthBloc authBloc) {
    _subscription = authBloc.stream.listen((_) => notifyListeners());
  }
  late final StreamSubscription<AuthState> _subscription;
  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

// -- Splash screen -------------------------------------------
class _SplashScreen extends StatelessWidget {
  const _SplashScreen();
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: scheme.primaryContainer,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                Icons.lock_outline_rounded,
                size: 36,
                color: scheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'HMSCPPD',
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 32),
            CircularProgressIndicator(color: scheme.primary, strokeWidth: 2.5),
          ],
        ),
      ),
    );
  }
}

class _LogoutFooter extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        final user = state is AuthAuthenticated
            ? state.activeSession.user.displayName
            : '';
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          child: ListTile(
            leading: Icon(Icons.logout, color: scheme.error),
            title: Text(
              'Sign Out',
              style: TextStyle(
                color: scheme.error,
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: user.isNotEmpty
                ? Text(
                    user,
                    style: TextStyle(
                      fontSize: 11,
                      color: scheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  )
                : null,
            onTap: () => context.read<AuthBloc>().add(AuthLogoutRequested()),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      },
    );
  }
}
