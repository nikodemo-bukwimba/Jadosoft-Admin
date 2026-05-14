// injection_container.dart
// -------------------------------------------------------------
// Dependency injection setup using get_it.
// -------------------------------------------------------------

// -- GENERATOR FEATURE IMPORTS ? append only ------------------

// Actor (HMSCP core ? L1)
import 'package:jadosoft_admin/features/actor/data/datasources/actor_remote_datasource.dart';
import 'package:jadosoft_admin/features/actor/data/datasources/actor_local_datasource.dart';
import 'package:jadosoft_admin/features/actor/data/repositories/actor_repository_impl.dart';
import 'package:jadosoft_admin/features/actor/domain/repositories/actor_repository.dart';
import 'package:jadosoft_admin/features/actor/domain/usecases/get_all_actor_usecase.dart';
import 'package:jadosoft_admin/features/actor/domain/usecases/get_actor_usecase.dart';
import 'package:jadosoft_admin/features/actor/domain/usecases/create_actor_usecase.dart';
import 'package:jadosoft_admin/features/actor/domain/usecases/update_actor_usecase.dart';
import 'package:jadosoft_admin/features/actor/domain/usecases/delete_actor_usecase.dart';
import 'package:jadosoft_admin/features/actor/presentation/bloc/actor_bloc.dart';
import 'package:jadosoft_admin/core/database/actor_cache_dao.dart';

// Phase 3 ? SMS Gateway (L5) ? data/client/ (singular)
import 'package:jadosoft_admin/features/sms_gateway/data/client/sms_gateway_client.dart';
import 'package:jadosoft_admin/features/sms_gateway/domain/services/sms_gateway_service.dart';
import 'package:jadosoft_admin/features/sms_gateway/presentation/cubit/sms_gateway_cubit.dart';

// Phase 3 ? WhatsApp (L5)
import 'package:jadosoft_admin/features/whatsapp/data/client/whatsapp_client.dart';
import 'package:jadosoft_admin/features/whatsapp/domain/services/whatsapp_service.dart';
import 'package:jadosoft_admin/features/whatsapp/presentation/cubit/whatsapp_cubit.dart';

// Phase 3 ? Mobile Money (L5)
import 'package:jadosoft_admin/features/mobile_money/data/client/mobile_money_client.dart';
import 'package:jadosoft_admin/features/mobile_money/domain/services/mobile_money_service.dart';
import 'package:jadosoft_admin/features/mobile_money/presentation/cubit/mobile_money_cubit.dart';

// Phase 4 ? Officers (L2) ? includes DomainService
import 'package:jadosoft_admin/features/officer/data/datasources/officer_remote_datasource.dart';
import 'package:jadosoft_admin/features/officer/data/repositories/officer_repository_impl.dart';
import 'package:jadosoft_admin/features/officer/domain/repositories/officer_repository.dart';
import 'package:jadosoft_admin/features/officer/domain/usecases/get_all_officer_usecase.dart';
import 'package:jadosoft_admin/features/officer/domain/usecases/get_officer_usecase.dart';
import 'package:jadosoft_admin/features/officer/domain/usecases/create_officer_usecase.dart';
import 'package:jadosoft_admin/features/officer/domain/usecases/update_officer_usecase.dart';
import 'package:jadosoft_admin/features/officer/domain/usecases/delete_officer_usecase.dart';
import 'package:jadosoft_admin/features/officer/domain/services/officer_domain_service.dart';
import 'package:jadosoft_admin/features/officer/presentation/bloc/officer_bloc.dart';

// Phase 4 ? Customers (L1)
import 'package:jadosoft_admin/features/customer/data/datasources/customer_remote_datasource.dart';
import 'package:jadosoft_admin/features/customer/data/repositories/customer_repository_impl.dart';
import 'package:jadosoft_admin/features/customer/domain/repositories/customer_repository.dart';
import 'package:jadosoft_admin/features/customer/domain/usecases/get_all_customer_usecase.dart';
import 'package:jadosoft_admin/features/customer/domain/usecases/get_customer_usecase.dart';
import 'package:jadosoft_admin/features/customer/domain/usecases/create_customer_usecase.dart';
import 'package:jadosoft_admin/features/customer/domain/usecases/update_customer_usecase.dart';
import 'package:jadosoft_admin/features/customer/domain/usecases/delete_customer_usecase.dart';
import 'package:jadosoft_admin/features/customer/presentation/bloc/customer_bloc.dart';

// Phase 5 ? Categories (L1)
import 'package:jadosoft_admin/features/category/data/datasources/category_remote_datasource.dart';
import 'package:jadosoft_admin/features/category/data/repositories/category_repository_impl.dart';
import 'package:jadosoft_admin/features/category/domain/repositories/category_repository.dart';
import 'package:jadosoft_admin/features/category/domain/usecases/get_all_category_usecase.dart';
import 'package:jadosoft_admin/features/category/domain/usecases/get_category_usecase.dart';
import 'package:jadosoft_admin/features/category/domain/usecases/create_category_usecase.dart';
import 'package:jadosoft_admin/features/category/domain/usecases/update_category_usecase.dart';
import 'package:jadosoft_admin/features/category/domain/usecases/delete_category_usecase.dart';
import 'package:jadosoft_admin/features/category/presentation/bloc/category_bloc.dart';

// Phase 5 — Products (L2)
import 'package:jadosoft_admin/features/product/data/datasources/product_remote_datasource.dart';
import 'package:jadosoft_admin/features/product/data/datasources/product_api_datasource.dart';
import 'package:jadosoft_admin/features/product/data/repositories/product_repository_impl.dart';
import 'package:jadosoft_admin/features/product/domain/repositories/product_repository.dart';
import 'package:jadosoft_admin/features/product/domain/guards/product_transition_guard.dart';
import 'package:jadosoft_admin/features/product/domain/services/product_domain_service.dart';
import 'package:jadosoft_admin/features/product/domain/usecases/create_product_usecase.dart';
import 'package:jadosoft_admin/features/product/domain/usecases/delete_product_usecase.dart';
import 'package:jadosoft_admin/features/product/domain/usecases/get_all_product_usecase.dart';
import 'package:jadosoft_admin/features/product/domain/usecases/get_product_usecase.dart';
import 'package:jadosoft_admin/features/product/domain/usecases/update_product_usecase.dart';
import 'package:jadosoft_admin/features/product/presentation/bloc/product_bloc.dart';

// Phase 6 ? Promotions (L3)
import 'package:jadosoft_admin/features/promotion/data/datasources/promotion_remote_datasource.dart';
import 'package:jadosoft_admin/features/promotion/data/repositories/promotion_repository_impl.dart';
import 'package:jadosoft_admin/features/promotion/domain/repositories/promotion_repository.dart';
import 'package:jadosoft_admin/features/promotion/domain/usecases/get_all_promotion_usecase.dart';
import 'package:jadosoft_admin/features/promotion/domain/usecases/get_promotion_usecase.dart';
import 'package:jadosoft_admin/features/promotion/domain/usecases/create_promotion_usecase.dart';
import 'package:jadosoft_admin/features/promotion/domain/usecases/update_promotion_usecase.dart';
import 'package:jadosoft_admin/features/promotion/domain/usecases/delete_promotion_usecase.dart';
import 'package:jadosoft_admin/features/promotion/domain/services/promotion_domain_service.dart';
import 'package:jadosoft_admin/features/promotion/presentation/bloc/promotion_bloc.dart';

// Phase 7 ? Visits (L2)
import 'package:jadosoft_admin/features/visit/data/datasources/visit_remote_datasource.dart';
import 'package:jadosoft_admin/features/visit/data/datasources/visit_api_datasource.dart';
import 'package:jadosoft_admin/features/visit/data/repositories/visit_repository_impl.dart';
import 'package:jadosoft_admin/features/visit/domain/repositories/visit_repository.dart';
import 'package:jadosoft_admin/features/visit/domain/usecases/get_all_visit_usecase.dart';
import 'package:jadosoft_admin/features/visit/domain/usecases/get_visit_usecase.dart';
import 'package:jadosoft_admin/features/visit/domain/usecases/get_customer_visits_usecase.dart';
import 'package:jadosoft_admin/features/visit/domain/usecases/create_visit_usecase.dart';
import 'package:jadosoft_admin/features/visit/domain/usecases/update_visit_usecase.dart';
import 'package:jadosoft_admin/features/visit/domain/usecases/delete_visit_usecase.dart';
import 'package:jadosoft_admin/features/visit/domain/services/visit_domain_service.dart';
import 'package:jadosoft_admin/features/visit/presentation/bloc/visit_bloc.dart';

// Phase 7 ? Weekly Plans (L2)
import 'package:jadosoft_admin/features/weekly_plan/data/datasources/weekly_plan_remote_datasource.dart';
import 'package:jadosoft_admin/features/weekly_plan/data/repositories/weekly_plan_repository_impl.dart';
import 'package:jadosoft_admin/features/weekly_plan/domain/repositories/weekly_plan_repository.dart';
import 'package:jadosoft_admin/features/weekly_plan/domain/usecases/get_all_weekly_plan_usecase.dart';
import 'package:jadosoft_admin/features/weekly_plan/domain/usecases/get_weekly_plan_usecase.dart';
import 'package:jadosoft_admin/features/weekly_plan/domain/usecases/create_weekly_plan_usecase.dart';
import 'package:jadosoft_admin/features/weekly_plan/domain/usecases/update_weekly_plan_usecase.dart';
import 'package:jadosoft_admin/features/weekly_plan/domain/usecases/delete_weekly_plan_usecase.dart';
import 'package:jadosoft_admin/features/weekly_plan/domain/services/weekly_plan_domain_service.dart';
import 'package:jadosoft_admin/features/weekly_plan/presentation/bloc/weekly_plan_bloc.dart';

// Phase 7 ? Daily Reports (L3)
import 'package:jadosoft_admin/features/daily_report/data/datasources/daily_report_remote_datasource.dart';
import 'package:jadosoft_admin/features/daily_report/data/repositories/daily_report_repository_impl.dart';
import 'package:jadosoft_admin/features/daily_report/domain/repositories/daily_report_repository.dart';
import 'package:jadosoft_admin/features/daily_report/domain/usecases/get_all_daily_report_usecase.dart';
import 'package:jadosoft_admin/features/daily_report/domain/usecases/get_daily_report_usecase.dart';
import 'package:jadosoft_admin/features/daily_report/domain/usecases/create_daily_report_usecase.dart';
import 'package:jadosoft_admin/features/daily_report/domain/usecases/update_daily_report_usecase.dart';
import 'package:jadosoft_admin/features/daily_report/domain/usecases/delete_daily_report_usecase.dart';
import 'package:jadosoft_admin/features/daily_report/domain/services/daily_report_domain_service.dart';
import 'package:jadosoft_admin/features/daily_report/presentation/bloc/daily_report_bloc.dart';

// Phase 8 ? Conversations (L1)
import 'package:jadosoft_admin/features/conversation/data/datasources/conversation_remote_datasource.dart';
// import 'package:jadosoft_admin/features/conversation/data/datasources/conversation_mock_datasource.dart';
import 'package:jadosoft_admin/features/conversation/data/repositories/conversation_repository_impl.dart';
import 'package:jadosoft_admin/features/conversation/domain/repositories/conversation_repository.dart';
import 'package:jadosoft_admin/features/conversation/domain/usecases/get_all_conversation_usecase.dart';
import 'package:jadosoft_admin/features/conversation/domain/usecases/get_conversation_usecase.dart';
import 'package:jadosoft_admin/features/conversation/domain/usecases/create_conversation_usecase.dart';
import 'package:jadosoft_admin/features/conversation/domain/usecases/update_conversation_usecase.dart';
import 'package:jadosoft_admin/features/conversation/domain/usecases/delete_conversation_usecase.dart';
import 'package:jadosoft_admin/features/conversation/presentation/bloc/conversation_bloc.dart';

// Phase 8 ? Orders (L3)
import 'package:jadosoft_admin/features/order/data/datasources/order_remote_datasource.dart';
import 'package:jadosoft_admin/features/order/data/repositories/order_repository_impl.dart';
import 'package:jadosoft_admin/features/order/domain/repositories/order_repository.dart';
import 'package:jadosoft_admin/features/order/domain/usecases/get_all_order_usecase.dart';
import 'package:jadosoft_admin/features/order/domain/usecases/get_order_usecase.dart';
import 'package:jadosoft_admin/features/order/domain/usecases/create_order_usecase.dart';
import 'package:jadosoft_admin/features/order/domain/usecases/update_order_usecase.dart';
import 'package:jadosoft_admin/features/order/domain/usecases/delete_order_usecase.dart';
import 'package:jadosoft_admin/features/order/domain/services/order_domain_service.dart';
import 'package:jadosoft_admin/features/order/presentation/bloc/order_bloc.dart';
import 'package:jadosoft_admin/features/order/domain/usecases/deduct_product_quantity_usecase.dart';
import 'package:jadosoft_admin/features/order/domain/usecases/mark_order_paid_usecase.dart';

// Phase 8 ? Payments (L1)
import 'package:jadosoft_admin/features/payment/data/datasources/payment_remote_datasource.dart';
import 'package:jadosoft_admin/features/payment/data/repositories/payment_repository_impl.dart';
import 'package:jadosoft_admin/features/payment/domain/repositories/payment_repository.dart';
import 'package:jadosoft_admin/features/payment/domain/usecases/get_all_payment_usecase.dart';
import 'package:jadosoft_admin/features/payment/domain/usecases/get_payment_usecase.dart';
import 'package:jadosoft_admin/features/payment/domain/usecases/create_payment_usecase.dart';
import 'package:jadosoft_admin/features/payment/domain/usecases/update_payment_usecase.dart';
import 'package:jadosoft_admin/features/payment/domain/usecases/delete_payment_usecase.dart';
import 'package:jadosoft_admin/features/payment/presentation/bloc/payment_bloc.dart';

// Phase 8 ? Notifications (L2)
import 'package:jadosoft_admin/features/notification/data/datasources/notification_remote_datasource.dart';
import 'package:jadosoft_admin/features/notification/data/repositories/notification_repository_impl.dart';
import 'package:jadosoft_admin/features/notification/domain/repositories/notification_repository.dart';
import 'package:jadosoft_admin/features/notification/domain/usecases/get_all_notification_usecase.dart';
import 'package:jadosoft_admin/features/notification/domain/usecases/get_notification_usecase.dart';
import 'package:jadosoft_admin/features/notification/domain/services/notification_domain_service.dart';
import 'package:jadosoft_admin/features/notification/presentation/bloc/notification_bloc.dart';

// Phase 9 ? Marketing Dashboard (L4)
import 'package:jadosoft_admin/features/marketing_dashboard/domain/usecases/get_marketing_dashboard_usecase.dart';
import 'package:jadosoft_admin/features/marketing_dashboard/presentation/cubit/marketing_dashboard_cubit.dart';

// Phase 9 ? Sales Dashboard (L4)
import 'package:jadosoft_admin/features/sales_dashboard/domain/usecases/get_sales_dashboard_usecase.dart';
import 'package:jadosoft_admin/features/sales_dashboard/presentation/cubit/sales_dashboard_cubit.dart';

// Phase 9 ? Report Export (L5)
import 'package:jadosoft_admin/features/report_export/data/client/report_export_client.dart';
import 'package:jadosoft_admin/features/report_export/domain/services/report_export_service.dart';
import 'package:jadosoft_admin/features/report_export/presentation/cubit/report_export_cubit.dart';
import 'package:jadosoft_admin/features/report_export/domain/services/report_pdf_generator.dart';

// Phase 9 ? Activity Logs (L1)
import 'package:jadosoft_admin/features/activity_log/data/datasources/activity_log_remote_datasource.dart';
import 'package:jadosoft_admin/features/activity_log/data/repositories/activity_log_repository_impl.dart';
import 'package:jadosoft_admin/features/activity_log/domain/repositories/activity_log_repository.dart';
import 'package:jadosoft_admin/features/activity_log/domain/usecases/get_all_activity_log_usecase.dart';
import 'package:jadosoft_admin/features/activity_log/domain/usecases/get_activity_log_usecase.dart';
import 'package:jadosoft_admin/features/activity_log/domain/usecases/create_activity_log_usecase.dart';
import 'package:jadosoft_admin/features/activity_log/domain/usecases/update_activity_log_usecase.dart';
import 'package:jadosoft_admin/features/activity_log/domain/usecases/delete_activity_log_usecase.dart';
import 'package:jadosoft_admin/features/activity_log/presentation/bloc/activity_log_bloc.dart';

// -- END GENERATOR FEATURE IMPORTS ----------------------------

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';

import '../../core/database/app_database.dart';
import '../../core/database/dashboard_cache_dao.dart';
import '../../core/database/profile_cache_dao.dart';
import '../../core/network/auth_interceptor.dart';
import '../../core/network/dio_client.dart';
import '../../core/network/token_refresh_config.dart';
import '../../core/storage/secure_storage_service.dart';
import '../../features/auth/data/datasources/auth_local_datasource.dart';
import '../../features/auth/data/datasources/auth_remote_datasource.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/domain/usecases/auth_usecases.dart';
import 'package:jadosoft_admin/core/context/org_context.dart';
import '../../features/auth/domain/usecases/login_usecase.dart';
import '../../features/auth/domain/usecases/logout_usecase.dart';
import '../../features/auth/domain/usecases/register_usecase.dart';
import '../../features/auth/domain/usecases/switch_account_usecase.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/dashboard/data/datasources/dashboard_remote_datasource.dart';
import '../../features/dashboard/data/repositories/dashboard_repository_impl.dart';
import '../../features/dashboard/domain/repositories/dashboard_repository.dart';
import '../../features/dashboard/domain/usecases/get_dashboard_stats_usecase.dart';
import '../../features/dashboard/presentation/bloc/dashboard_bloc.dart';
import '../../features/profile/data/datasources/profile_remote_datasource.dart';
import '../../features/profile/data/repositories/profile_repository_impl.dart';
import '../../features/profile/domain/repositories/profile_repository.dart';
import '../../features/profile/domain/usecases/get_profile_usecase.dart';
import '../../features/profile/presentation/bloc/profile_bloc.dart';

// Add BEFORE each DomainService ? one per feature:
import 'package:jadosoft_admin/features/officer/domain/guards/officer_transition_guard.dart';
import 'package:jadosoft_admin/features/promotion/domain/guards/promotion_transition_guard.dart';
import 'package:jadosoft_admin/features/visit/domain/guards/visit_transition_guard.dart';
import 'package:jadosoft_admin/features/weekly_plan/domain/guards/weekly_plan_transition_guard.dart';
import 'package:jadosoft_admin/features/daily_report/domain/guards/daily_report_transition_guard.dart';
import 'package:jadosoft_admin/features/order/domain/guards/order_transition_guard.dart';
import 'package:jadosoft_admin/features/notification/domain/guards/notification_transition_guard.dart';

import 'package:jadosoft_admin/features/marketing_dashboard/data/providers/visit_data_provider_impl.dart';
import 'package:jadosoft_admin/features/marketing_dashboard/data/providers/weekly_plan_data_provider_impl.dart';
import 'package:jadosoft_admin/features/marketing_dashboard/data/providers/daily_report_data_provider_impl.dart';
import 'package:jadosoft_admin/features/marketing_dashboard/data/providers/officer_data_provider_impl.dart';
import 'package:jadosoft_admin/features/marketing_dashboard/data/providers/customer_data_provider_impl.dart';
import 'package:jadosoft_admin/features/marketing_dashboard/domain/providers/visit_data_provider.dart';
import 'package:jadosoft_admin/features/marketing_dashboard/domain/providers/weekly_plan_data_provider.dart';
import 'package:jadosoft_admin/features/marketing_dashboard/domain/providers/daily_report_data_provider.dart';
import 'package:jadosoft_admin/features/marketing_dashboard/domain/providers/officer_data_provider.dart';
import 'package:jadosoft_admin/features/marketing_dashboard/domain/providers/customer_data_provider.dart';
import 'package:jadosoft_admin/features/sales_dashboard/data/providers/order_data_provider_impl.dart';
import 'package:jadosoft_admin/features/sales_dashboard/data/providers/payment_data_provider_impl.dart';
import 'package:jadosoft_admin/features/sales_dashboard/data/providers/product_data_provider_impl.dart';
import 'package:jadosoft_admin/features/sales_dashboard/domain/providers/order_data_provider.dart';
import 'package:jadosoft_admin/features/sales_dashboard/domain/providers/payment_data_provider.dart';
import 'package:jadosoft_admin/features/sales_dashboard/domain/providers/product_data_provider.dart';
import 'package:jadosoft_admin/features/payment/data/datasources/payment_mock_datasource.dart';

// SMS Gateway
import 'package:jadosoft_admin/features/sms_gateway/data/client/sms_gateway_mock_client.dart';

// WhatsApp
import 'package:jadosoft_admin/features/whatsapp/data/client/whatsapp_mock_client.dart';

// Mobile Money
import 'package:jadosoft_admin/features/mobile_money/data/client/mobile_money_mock_client.dart';

//Organization
import 'package:jadosoft_admin/features/organization/data/datasources/organization_remote_datasource.dart';
import 'package:jadosoft_admin/features/organization/data/repositories/organization_repository_impl.dart';
import 'package:jadosoft_admin/features/organization/domain/repositories/organization_repository.dart';
import 'package:jadosoft_admin/features/organization/presentation/bloc/organization_bloc.dart';

final sl = GetIt.instance;

Future<void> initDependencies() async {
  // -- 1. Infrastructure -------------------------------------
  sl.registerLazySingleton<FlutterSecureStorage>(
    () => const FlutterSecureStorage(),
  );
  sl.registerLazySingleton<SecureStorageService>(
    () => SecureStorageService(sl<FlutterSecureStorage>()),
  );
  sl.registerLazySingleton<OrgContext>(
    () => OrgContext(storage: sl<SecureStorageService>()),
  );
  sl.registerLazySingleton<TokenRefreshConfig>(
    () => const TokenRefreshConfig.disabled(),
  );
  sl.registerLazySingleton<AuthInterceptor>(
    () => AuthInterceptor(
      sl<SecureStorageService>(),
      refreshConfig: sl<TokenRefreshConfig>(),
    ),
  );
  sl.registerLazySingleton<Dio>(
    () => buildSecureDioClient(authInterceptor: sl<AuthInterceptor>()),
  );

  // -- 2. Local cache (Drift) --------------------------------
  sl.registerLazySingleton<AppDatabase>(() => AppDatabase());
  sl.registerLazySingleton<ProfileCacheDao>(
    () => sl<AppDatabase>().profileCacheDao,
  );
  sl.registerLazySingleton<DashboardCacheDao>(
    () => sl<AppDatabase>().dashboardCacheDao,
  );

  // -- 3. Auth -----------------------------------------------
  sl.registerLazySingleton<AuthLocalDataSource>(
    () => AuthLocalDataSourceImpl(sl<SecureStorageService>()),
  );
  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(sl<Dio>()),
  );
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      remote: sl<AuthRemoteDataSource>(),
      local: sl<AuthLocalDataSource>(),
      orgContext: sl<OrgContext>(),
    ),
  );
  sl.registerLazySingleton(() => LoginUseCase(sl<AuthRepository>()));
  sl.registerLazySingleton(() => RegisterUseCase(sl<AuthRepository>()));
  sl.registerLazySingleton(() => LogoutUseCase(sl<AuthRepository>()));
  sl.registerLazySingleton(() => LogoutAccountUseCase(sl<AuthRepository>()));
  sl.registerLazySingleton(() => SwitchAccountUseCase(sl<AuthRepository>()));
  sl.registerLazySingleton(() => GetActiveSessionUseCase(sl<AuthRepository>()));
  sl.registerLazySingleton(() => GetSavedAccountsUseCase(sl<AuthRepository>()));
  sl.registerLazySingleton(() => RefreshSessionUseCase(sl<AuthRepository>()));
  sl.registerFactory<AuthBloc>(
    () => AuthBloc(
      login: sl<LoginUseCase>(),
      register: sl<RegisterUseCase>(),
      logout: sl<LogoutUseCase>(),
      logoutAccount: sl<LogoutAccountUseCase>(),
      switchAccount: sl<SwitchAccountUseCase>(),
      getActiveSession: sl<GetActiveSessionUseCase>(),
      getSavedAccounts: sl<GetSavedAccountsUseCase>(),
      refreshSession: sl<RefreshSessionUseCase>(),
      orgContext: sl<OrgContext>(), // FIX: added
    ),
  );

  // -- 4. Profile & Dashboard (pre-existing) -----------------
  sl.registerLazySingleton<ProfileRemoteDataSource>(
    () => ProfileRemoteDataSourceImpl(sl<Dio>()),
  );
  sl.registerLazySingleton<ProfileRepository>(
    () => ProfileRepositoryImpl(
      remote: sl<ProfileRemoteDataSource>(),
      cacheDao: sl<ProfileCacheDao>(),
      storage: sl<SecureStorageService>(),
    ),
  );
  sl.registerLazySingleton(() => GetProfileUseCase(sl<ProfileRepository>()));
  sl.registerFactory<ProfileBloc>(() => ProfileBloc(sl<GetProfileUseCase>()));
  sl.registerLazySingleton<DashboardRemoteDataSource>(
    () => DashboardRemoteDataSourceImpl(sl<Dio>()),
  );
  sl.registerLazySingleton<DashboardRepository>(
    () => DashboardRepositoryImpl(
      remote: sl<DashboardRemoteDataSource>(),
      cacheDao: sl<DashboardCacheDao>(),
    ),
  );
  sl.registerLazySingleton(
    () => GetDashboardStatsUseCase(sl<DashboardRepository>()),
  );
  sl.registerFactory<DashboardBloc>(
    () => DashboardBloc(getDashboardStats: sl<GetDashboardStatsUseCase>()),
  );

  // -- 5. Actor (HMSCP core ? L1) ----------------------------
  sl.registerLazySingleton<ActorCacheDao>(() => ActorCacheDao(sl()));
  sl.registerLazySingleton<ActorRemoteDataSource>(
    () => ActorRemoteDataSourceImpl(dio: sl(), orgContext: sl<OrgContext>()),
  );
  sl.registerLazySingleton<ActorLocalDataSource>(
    () => ActorLocalDataSourceImpl(dao: sl()),
  );
  sl.registerLazySingleton<ActorRepository>(
    () => ActorRepositoryImpl(remote: sl(), local: sl()),
  );
  sl.registerLazySingleton(() => GetAllActorUseCase(sl()));
  sl.registerLazySingleton(() => GetActorUseCase(sl()));
  sl.registerLazySingleton(() => CreateActorUseCase(sl()));
  sl.registerLazySingleton(() => UpdateActorUseCase(sl()));
  sl.registerLazySingleton(() => DeleteActorUseCase(sl()));
  sl.registerFactory<ActorBloc>(
    () => ActorBloc(
      getAllUseCase: sl(),
      getUseCase: sl(),
      createUseCase: sl(),
      updateUseCase: sl(),
      deleteUseCase: sl(),
    ),
  );

  // ----------------------------------------------------------
  // BARICK FEATURES ? Phase 3: External Integrations (L5)
  // Pattern: Client ? Service ? Cubit  (cubit takes service:)
  // ----------------------------------------------------------
  // ── SMS Gateway ──────────────────────────────────────────────
  // DEVELOPMENT (mock — active now):
  sl.registerLazySingleton<SmsGatewayClient>(() => SmsGatewayMockClient());
  // PRODUCTION (real — swap when Laravel API is ready):
  // sl.registerLazySingleton<SmsGatewayClient>(
  //   () => SmsGatewayClientImpl(dio: sl(), orgContext: sl()));

  sl.registerLazySingleton(() => SmsGatewayService(client: sl()));
  sl.registerFactory<SmsGatewayCubit>(() => SmsGatewayCubit(service: sl()));

  // ── WhatsApp ─────────────────────────────────────────────────
  // DEVELOPMENT (mock — active now):
  sl.registerLazySingleton<WhatsappClient>(() => WhatsappMockClient());
  // PRODUCTION (real — swap when Laravel API is ready):
  // sl.registerLazySingleton<WhatsappClient>(
  //   () => WhatsappClientImpl(dio: sl(), orgContext: sl()));

  sl.registerLazySingleton(() => WhatsappService(client: sl()));
  sl.registerFactory<WhatsappCubit>(() => WhatsappCubit(service: sl()));

  // ── Mobile Money ─────────────────────────────────────────────
  // DEVELOPMENT (mock — active now):
  sl.registerLazySingleton<MobileMoneyClient>(() => MobileMoneyMockClient());
  // PRODUCTION (real — swap when Laravel API is ready):
  // sl.registerLazySingleton<MobileMoneyClient>(
  //   () => MobileMoneyClientImpl(dio: sl(), orgContext: sl()));

  sl.registerLazySingleton(() => MobileMoneyService(client: sl()));
  sl.registerFactory<MobileMoneyCubit>(() => MobileMoneyCubit(service: sl()));

  // ----------------------------------------------------------
  // Phase 4: User & Customer (L2 / L1)
  // L2 repos use remoteDataSource:, blocs need domainService:
  // ----------------------------------------------------------

  // Seq 6 ? Officers (L2)
  // sl.registerLazySingleton<OfficerRemoteDataSource>(
  //   () => OfficerMockDataSource(),
  // );
  sl.registerLazySingleton<OfficerRemoteDataSource>(
    () => OfficerRemoteDataSourceImpl(dio: sl(), orgContext: sl()),
  );
  sl.registerLazySingleton<OfficerRepository>(
    () => OfficerRepositoryImpl(remoteDataSource: sl()),
  );
  sl.registerLazySingleton(() => OfficerTransitionGuard());
  sl.registerLazySingleton(
    () => OfficerDomainService(repository: sl(), guard: sl()),
  );
  sl.registerLazySingleton(() => GetAllOfficerUseCase(sl()));
  sl.registerLazySingleton(() => GetOfficerUseCase(sl()));
  sl.registerLazySingleton(() => CreateOfficerUseCase(sl()));
  sl.registerLazySingleton(() => UpdateOfficerUseCase(sl()));
  sl.registerLazySingleton(() => DeleteOfficerUseCase(sl()));
  sl.registerFactory<OfficerBloc>(
    () => OfficerBloc(
      getAllUseCase: sl(),
      getUseCase: sl(),
      createUseCase: sl(),
      updateUseCase: sl(),
      deleteUseCase: sl(),
      domainService: sl(),
    ),
  );

  // Seq 6b — Organization Management
  sl.registerLazySingleton<OrganizationRemoteDataSource>(
    () => OrganizationRemoteDataSource(dio: sl(), orgContext: sl()),
  );
  sl.registerLazySingleton<OrganizationRepository>(
    () => OrganizationRepositoryImpl(remote: sl()),
  );
  sl.registerFactory<OrganizationBloc>(
    () => OrganizationBloc(repository: sl(), orgContext: sl()),
  );

  // Seq 7 ? Customers (L1)
  // sl.registerLazySingleton<CustomerRemoteDataSource>(
  //   () => CustomerMockDataSource(),
  // );
  //   sl.registerLazySingleton<CustomerRemoteDataSource>(
  //   () => CustomerRemoteDataSourceImpl(dio: sl(), orgContext: sl()),
  // );
  sl.registerLazySingleton<CustomerRemoteDataSource>(
    () => CustomerRemoteDataSourceImpl(
      dio: sl<Dio>(),
      orgContext: sl<OrgContext>(),
    ),
  );
  sl.registerLazySingleton<CustomerRepository>(
    () => CustomerRepositoryImpl(remoteDataSource: sl()),
  );
  sl.registerLazySingleton(() => GetAllCustomerUseCase(sl()));
  sl.registerLazySingleton(() => GetCustomerUseCase(sl()));
  sl.registerLazySingleton(() => CreateCustomerUseCase(sl()));
  sl.registerLazySingleton(() => UpdateCustomerUseCase(sl()));
  sl.registerLazySingleton(() => DeleteCustomerUseCase(sl()));
  sl.registerFactory<CustomerBloc>(
    () => CustomerBloc(
      getAllUseCase: sl(),
      getUseCase: sl(),
      createUseCase: sl(),
      updateUseCase: sl(),
      deleteUseCase: sl(),
    ),
  );

  // ----------------------------------------------------------
  // Phase 5: Product & Category (L1 / L2)
  // ----------------------------------------------------------

  // Seq 8 ? Categories (L1)
  sl.registerLazySingleton<CategoryRemoteDataSource>(
    () => CategoryRemoteDataSourceImpl(dio: sl(), orgContext: sl()),
  );
  sl.registerLazySingleton<CategoryRepository>(
    () => CategoryRepositoryImpl(remoteDataSource: sl()),
  );
  sl.registerLazySingleton(() => GetAllCategoryUseCase(sl()));
  sl.registerLazySingleton(() => GetCategoryUseCase(sl()));
  sl.registerLazySingleton(() => CreateCategoryUseCase(sl()));
  sl.registerLazySingleton(() => UpdateCategoryUseCase(sl()));
  sl.registerLazySingleton(() => DeleteCategoryUseCase(sl()));
  sl.registerFactory<CategoryBloc>(
    () => CategoryBloc(
      getAllUseCase: sl(),
      getUseCase: sl(),
      createUseCase: sl(),
      updateUseCase: sl(),
      deleteUseCase: sl(),
    ),
  );

  // Seq 9 — Products (L2) — using mock until API is ready

  //comment/delete this on real api
  // sl.registerLazySingleton<ProductRemoteDataSource>(
  //   () => ProductMockDataSource(),
  // );
  // uncomment this on real api
  sl.registerLazySingleton<ProductRemoteDataSource>(
    () => ProductApiDataSource(dio: sl(), orgContext: sl()),
  );

  sl.registerLazySingleton<ProductRepository>(
    () => ProductRepositoryImpl(remoteDataSource: sl()),
  );
  sl.registerLazySingleton(() => ProductTransitionGuard());
  sl.registerLazySingleton(
    () => ProductDomainService(repository: sl(), guard: sl()),
  );
  sl.registerLazySingleton(() => GetAllProductUseCase(sl()));
  sl.registerLazySingleton(() => GetProductUseCase(sl()));
  sl.registerLazySingleton(() => CreateProductUseCase(sl()));
  sl.registerLazySingleton(() => UpdateProductUseCase(sl()));
  sl.registerLazySingleton(() => DeleteProductUseCase(sl()));
  sl.registerFactory<ProductBloc>(
    () => ProductBloc(
      getAllUseCase: sl(),
      getUseCase: sl(),
      createUseCase: sl(),
      updateUseCase: sl(),
      deleteUseCase: sl(),
      domainService: sl(),
    ),
  );

  // ----------------------------------------------------------
  // Phase 6: Promotions (L3) ? domainService required
  // ----------------------------------------------------------

  sl.registerLazySingleton<PromotionRemoteDataSource>(
    () => PromotionRemoteDataSourceImpl(dio: sl(), orgContext: sl()),
  );
  sl.registerLazySingleton<PromotionRepository>(
    () => PromotionRepositoryImpl(remoteDataSource: sl()),
  );
  sl.registerLazySingleton(() => PromotionTransitionGuard());
  sl.registerLazySingleton(
    () => PromotionDomainService(repository: sl(), guard: sl()),
  );
  sl.registerLazySingleton(() => GetAllPromotionUseCase(sl()));
  sl.registerLazySingleton(() => GetPromotionUseCase(sl()));
  sl.registerLazySingleton(() => CreatePromotionUseCase(sl()));
  sl.registerLazySingleton(() => UpdatePromotionUseCase(sl()));
  sl.registerLazySingleton(() => DeletePromotionUseCase(sl()));
  sl.registerFactory<PromotionBloc>(
    () => PromotionBloc(
      getAllUseCase: sl(),
      getUseCase: sl(),
      createUseCase: sl(),
      updateUseCase: sl(),
      deleteUseCase: sl(),
      domainService: sl(),
    ),
  );

  // ----------------------------------------------------------
  // Phase 7: Field Operations (L2 / L3)
  // ----------------------------------------------------------

  // Seq 11 ? Visits (L2)
  // sl.registerLazySingleton<VisitRemoteDataSource>(() => VisitMockDataSource());
  sl.registerLazySingleton<VisitRemoteDataSource>(
    () => VisitApiDataSource(dio: sl(), orgContext: sl()),
  );
  sl.registerLazySingleton<VisitRepository>(
    () => VisitRepositoryImpl(remoteDataSource: sl()),
  );
  sl.registerLazySingleton(() => VisitTransitionGuard());
  sl.registerLazySingleton(
    () => VisitDomainService(repository: sl(), guard: sl()),
  );
  sl.registerLazySingleton(() => GetAllVisitUseCase(sl()));
  sl.registerLazySingleton(() => GetVisitUseCase(sl()));
  sl.registerLazySingleton(() => GetCustomerVisitsUseCase(sl()));
  sl.registerLazySingleton(() => CreateVisitUseCase(sl()));
  sl.registerLazySingleton(() => UpdateVisitUseCase(sl()));
  sl.registerLazySingleton(() => DeleteVisitUseCase(sl()));
  sl.registerFactory<VisitBloc>(
    () => VisitBloc(
      getAllUseCase: sl(),
      getUseCase: sl(),
      getCustomerVisitsUseCase: sl(),
      createUseCase: sl(),
      updateUseCase: sl(),
      deleteUseCase: sl(),
      domainService: sl(),
    ),
  );

  // Seq 12 — Weekly Plans (L2)
  // DEVELOPMENT (mock — active now):
  // sl.registerLazySingleton<WeeklyPlanRemoteDataSource>(
  //   () => WeeklyPlanMockDataSource(),
  // );
  // PRODUCTION (real — swap when Laravel API is ready):
  sl.registerLazySingleton<WeeklyPlanRemoteDataSource>(
    () => WeeklyPlanRemoteDataSourceImpl(dio: sl(), orgContext: sl()),
  );
  sl.registerLazySingleton<WeeklyPlanRepository>(
    () => WeeklyPlanRepositoryImpl(remoteDataSource: sl()),
  );
  sl.registerLazySingleton(() => WeeklyPlanTransitionGuard());
  sl.registerLazySingleton(() => WeeklyPlanDomainService(repository: sl()));
  sl.registerLazySingleton(() => GetAllWeeklyPlanUseCase(sl()));
  sl.registerLazySingleton(() => GetWeeklyPlanUseCase(sl()));
  sl.registerLazySingleton(() => CreateWeeklyPlanUseCase(sl()));
  sl.registerLazySingleton(() => UpdateWeeklyPlanUseCase(sl()));
  sl.registerLazySingleton(() => DeleteWeeklyPlanUseCase(sl()));
  sl.registerFactory<WeeklyPlanBloc>(
    () => WeeklyPlanBloc(
      getAllUseCase: sl(),
      getUseCase: sl(),
      createUseCase: sl(),
      updateUseCase: sl(),
      deleteUseCase: sl(),
      domainService: sl(),
    ),
  );

  // Seq 13 — Daily Reports (L3)
  // DEVELOPMENT (mock — active now):
  // sl.registerLazySingleton<DailyReportRemoteDataSource>(
  //   () => DailyReportMockDataSource(),
  // );
  // PRODUCTION (real — swap when Laravel API is ready):
  sl.registerLazySingleton<DailyReportRemoteDataSource>(
    () => DailyReportRemoteDataSourceImpl(dio: sl(), orgContext: sl()),
  );
  sl.registerLazySingleton<DailyReportRepository>(
    () => DailyReportRepositoryImpl(remoteDataSource: sl()),
  );
  sl.registerLazySingleton(() => DailyReportTransitionGuard());
  sl.registerLazySingleton(
    () => DailyReportDomainService(repository: sl(), guard: sl()),
  );
  sl.registerLazySingleton(() => GetAllDailyReportUseCase(sl()));
  sl.registerLazySingleton(() => GetDailyReportUseCase(sl()));
  sl.registerLazySingleton(() => CreateDailyReportUseCase(sl()));
  sl.registerLazySingleton(() => UpdateDailyReportUseCase(sl()));
  sl.registerLazySingleton(() => DeleteDailyReportUseCase(sl()));
  sl.registerFactory<DailyReportBloc>(
    () => DailyReportBloc(
      getAllUseCase: sl(),
      getUseCase: sl(),
      createUseCase: sl(),
      updateUseCase: sl(),
      deleteUseCase: sl(),
      domainService: sl(),
    ),
  );

  // ----------------------------------------------------------
  // Phase 8: Communication & Commerce
  // ----------------------------------------------------------

  // Seq 14 — Conversations (L1)
  sl.registerLazySingleton<ConversationRemoteDataSource>(
    () => ConversationRemoteDataSourceImpl(dio: sl<Dio>()),
  );
  sl.registerLazySingleton<ConversationRepository>(
    () => ConversationRepositoryImpl(remoteDataSource: sl()),
  );
  sl.registerLazySingleton(() => GetAllConversationUseCase(sl()));
  sl.registerLazySingleton(() => GetConversationUseCase(sl()));
  sl.registerLazySingleton(() => CreateConversationUseCase(sl()));
  sl.registerLazySingleton(() => UpdateConversationUseCase(sl()));
  sl.registerLazySingleton(() => DeleteConversationUseCase(sl()));

  // ── ConversationBloc factory: identity resolved at call time ──
  // Do NOT resolve actorId at startup — OrgContext is not yet
  // populated. Instead, read it fresh from OrgContext each time
  // the factory is called (which is once per route).
  sl.registerFactoryParam<ConversationBloc, String, String>(
    (actorId, actorName) => ConversationBloc(
      getAllUseCase: sl(),
      getUseCase: sl(),
      createUseCase: sl(),
      updateUseCase: sl(),
      deleteUseCase: sl(),
      dataSource: sl(),
      currentUserId: actorId,
      currentUserName: actorName,
      currentUserRole: sl<OrgContext>().orgRole.name,
    ),
  );

  // Seq 15 — Orders (L3)
  // DEVELOPMENT (mock — active now):
  // sl.registerLazySingleton<OrderRemoteDataSource>(() => OrderMockDataSource());
  // PRODUCTION (real — swap when Laravel API is ready):
  sl.registerLazySingleton<OrderRemoteDataSource>(
    () => OrderRemoteDataSourceImpl(dio: sl(), orgContext: sl()),
  );
  sl.registerLazySingleton<OrderRepository>(
    () => OrderRepositoryImpl(remoteDataSource: sl()),
  );
  sl.registerLazySingleton(() => OrderTransitionGuard());
  sl.registerLazySingleton(
    () => OrderDomainService(repository: sl(), guard: sl()),
  );
  // FIX: GetAllOrderUseCase is now imported solely from get_all_order_usecase.dart.
  // create_order_usecase.dart no longer re-exports it, so there is no ambiguity.
  sl.registerLazySingleton(() => GetAllOrderUseCase(sl()));
  sl.registerLazySingleton(() => GetOrderUseCase(sl()));
  // FIX: DeductProductQuantityUseCase has a const no-arg constructor.
  sl.registerLazySingleton(() => DeductProductQuantityUseCase());
  sl.registerLazySingleton(
    () => CreateOrderUseCase(repository: sl(), deductQuantity: sl()),
  );
  sl.registerLazySingleton(() => UpdateOrderUseCase(sl()));
  sl.registerLazySingleton(() => DeleteOrderUseCase(sl()));
  sl.registerLazySingleton(() => MarkOrderPaidUseCase(sl()));
  sl.registerFactory<OrderBloc>(
    () => OrderBloc(
      getAllUseCase: sl(),
      getUseCase: sl(),
      createUseCase: sl(),
      updateUseCase: sl(),
      deleteUseCase: sl(),
      domainService: sl(),
      markPaidUseCase: sl(),
    ),
  );

  // Seq 16 — Payments (L1)
  // DEVELOPMENT (mock — active now):
  sl.registerLazySingleton<PaymentRemoteDataSource>(
    () => PaymentMockDataSource(),
  );
  // PRODUCTION (real — swap when Laravel API is ready):
  // sl.registerLazySingleton<PaymentRemoteDataSource>(
  //   () => PaymentRemoteDataSourceImpl(dio: sl(), orgContext: sl()),
  // );
  sl.registerLazySingleton<PaymentRepository>(
    () => PaymentRepositoryImpl(remoteDataSource: sl()),
  );
  sl.registerLazySingleton(() => GetAllPaymentUseCase(sl()));
  sl.registerLazySingleton(() => GetPaymentUseCase(sl()));
  sl.registerLazySingleton(() => CreatePaymentUseCase(sl()));
  sl.registerLazySingleton(() => UpdatePaymentUseCase(sl()));
  sl.registerLazySingleton(() => DeletePaymentUseCase(sl()));
  sl.registerFactory<PaymentBloc>(
    () => PaymentBloc(
      getAllUseCase: sl(),
      getUseCase: sl(),
      createUseCase: sl(),
      updateUseCase: sl(),
      deleteUseCase: sl(),
    ),
  );

  // Seq 17 — Notifications (L2)
  // Phase N — Notifications (Delivery Center)
  sl.registerLazySingleton<NotificationRemoteDataSource>(
    () => NotificationRemoteDataSourceImpl(dio: sl(), orgContext: sl()),
  );
  sl.registerLazySingleton<NotificationRepository>(
    () => NotificationRepositoryImpl(remoteDataSource: sl()),
  );
  sl.registerLazySingleton(() => NotificationTransitionGuard());
  sl.registerLazySingleton(
    () => NotificationDomainService(repository: sl(), guard: sl()),
  );
  sl.registerLazySingleton(() => GetAllNotificationUseCase(sl()));
  sl.registerLazySingleton(() => GetNotificationUseCase(sl()));
  sl.registerFactory<NotificationBloc>(
    () => NotificationBloc(
      getAllUseCase: sl(),
      getUseCase: sl(),
      domainService: sl(),
    ),
  );

  // ----------------------------------------------------------
  // Phase 9: Analytics & Reporting
  // L4 cubits use getProjection:, L5 cubits use service:
  // ----------------------------------------------------------

  // Seq 18 ? Marketing Dashboard (L4)
  sl.registerLazySingleton<VisitDataProvider>(
    () => VisitDataProviderImpl(repository: sl()),
  );
  sl.registerLazySingleton<WeeklyPlanDataProvider>(
    () => WeeklyPlanDataProviderImpl(repository: sl()),
  );
  sl.registerLazySingleton<DailyReportDataProvider>(
    () => DailyReportDataProviderImpl(repository: sl()),
  );
  sl.registerLazySingleton<OfficerDataProvider>(
    () => OfficerDataProviderImpl(repository: sl()),
  );
  sl.registerLazySingleton<CustomerDataProvider>(
    () => CustomerDataProviderImpl(repository: sl()),
  );
  sl.registerLazySingleton(
    () => GetMarketingDashboardUseCase(
      visitProvider: sl(),
      weeklyPlanProvider: sl(),
      dailyReportProvider: sl(),
      officerProvider: sl(),
      customerProvider: sl(),
    ),
  );
  sl.registerFactory<MarketingDashboardCubit>(
    () => MarketingDashboardCubit(getProjection: sl()),
  );

  // Seq 19 ? Sales Dashboard (L4)
  sl.registerLazySingleton<OrderDataProvider>(
    () => OrderDataProviderImpl(repository: sl()),
  );
  sl.registerLazySingleton<PaymentDataProvider>(
    () => PaymentDataProviderImpl(repository: sl()),
  );
  sl.registerLazySingleton<ProductDataProvider>(
    () => ProductDataProviderImpl(repository: sl()),
  );
  sl.registerLazySingleton(
    () => GetSalesDashboardUseCase(
      orderProvider: sl(),
      paymentProvider: sl(),
      productProvider: sl(),
    ),
  );
  sl.registerFactory<SalesDashboardCubit>(
    () => SalesDashboardCubit(getProjection: sl()),
  );

  // Seq 20 ? Report Export (L5)
  //     sl.registerLazySingleton<ReportExportClient>(
  //       () => ReportExportClientImpl(dio: sl()));
  // sl.registerLazySingleton<ReportExportClient>(() => ReportExportMockClient());
  sl.registerLazySingleton<ReportExportService>(
    () => ReportExportService(client: sl<ReportExportClient>()),
  );
  sl.registerFactory<ReportExportCubit>(
    () => ReportExportCubit(service: sl<ReportExportService>()),
  );

  // Seq 21 — Activity Logs (L1)
  // DEVELOPMENT (mock — active now):
  // sl.registerLazySingleton<ActivityLogRemoteDataSource>(
  //   () => ActivityLogMockDataSource(),
  // );
  // PRODUCTION (real — swap when Laravel API is ready):
  sl.registerLazySingleton<ActivityLogRemoteDataSource>(
    () => ActivityLogRemoteDataSourceImpl(dio: sl(), orgContext: sl()),
  );
  sl.registerLazySingleton<ActivityLogRepository>(
    () => ActivityLogRepositoryImpl(remoteDataSource: sl()),
  );
  sl.registerLazySingleton(() => GetAllActivityLogUseCase(sl()));
  sl.registerLazySingleton(() => GetActivityLogUseCase(sl()));
  sl.registerLazySingleton(() => CreateActivityLogUseCase(sl()));
  sl.registerLazySingleton(() => UpdateActivityLogUseCase(sl()));
  sl.registerLazySingleton(() => DeleteActivityLogUseCase(sl()));
  sl.registerFactory<ActivityLogBloc>(
    () => ActivityLogBloc(
      getAllUseCase: sl(),
      getUseCase: sl(),
      createUseCase: sl(),
      updateUseCase: sl(),
      deleteUseCase: sl(),
    ),
  );
}
