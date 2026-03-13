// injection_container.dart
// -------------------------------------------------------------
// Dependency injection setup using get_it.
// -------------------------------------------------------------

// -- GENERATOR FEATURE IMPORTS — append only ------------------

// Actor (HMSCP core – L1)
import 'package:admin_panel/features/actor/data/datasources/actor_remote_datasource.dart';
import 'package:admin_panel/features/actor/data/datasources/actor_local_datasource.dart';
import 'package:admin_panel/features/actor/data/repositories/actor_repository_impl.dart';
import 'package:admin_panel/features/actor/domain/repositories/actor_repository.dart';
import 'package:admin_panel/features/actor/domain/usecases/get_all_actor_usecase.dart';
import 'package:admin_panel/features/actor/domain/usecases/get_actor_usecase.dart';
import 'package:admin_panel/features/actor/domain/usecases/create_actor_usecase.dart';
import 'package:admin_panel/features/actor/domain/usecases/update_actor_usecase.dart';
import 'package:admin_panel/features/actor/domain/usecases/delete_actor_usecase.dart';
import 'package:admin_panel/features/actor/presentation/bloc/actor_bloc.dart';
import 'package:admin_panel/core/database/actor_cache_dao.dart';

// Phase 3 · SMS Gateway (L5) — data/client/ (singular)
import 'package:admin_panel/features/sms_gateway/data/client/sms_gateway_client.dart';
import 'package:admin_panel/features/sms_gateway/domain/services/sms_gateway_service.dart';
import 'package:admin_panel/features/sms_gateway/presentation/cubit/sms_gateway_cubit.dart';

// Phase 3 · WhatsApp (L5)
import 'package:admin_panel/features/whatsapp/data/client/whatsapp_client.dart';
import 'package:admin_panel/features/whatsapp/domain/services/whatsapp_service.dart';
import 'package:admin_panel/features/whatsapp/presentation/cubit/whatsapp_cubit.dart';

// Phase 3 · Mobile Money (L5)
import 'package:admin_panel/features/mobile_money/data/client/mobile_money_client.dart';
import 'package:admin_panel/features/mobile_money/domain/services/mobile_money_service.dart';
import 'package:admin_panel/features/mobile_money/presentation/cubit/mobile_money_cubit.dart';

// Phase 4 · Officers (L2) — includes DomainService
import 'package:admin_panel/features/officer/data/datasources/officer_remote_datasource.dart';
import 'package:admin_panel/features/officer/data/datasources/officer_mock_datasource.dart';
import 'package:admin_panel/features/officer/data/repositories/officer_repository_impl.dart';
import 'package:admin_panel/features/officer/domain/repositories/officer_repository.dart';
import 'package:admin_panel/features/officer/domain/usecases/get_all_officer_usecase.dart';
import 'package:admin_panel/features/officer/domain/usecases/get_officer_usecase.dart';
import 'package:admin_panel/features/officer/domain/usecases/create_officer_usecase.dart';
import 'package:admin_panel/features/officer/domain/usecases/update_officer_usecase.dart';
import 'package:admin_panel/features/officer/domain/usecases/delete_officer_usecase.dart';
import 'package:admin_panel/features/officer/domain/services/officer_domain_service.dart';
import 'package:admin_panel/features/officer/presentation/bloc/officer_bloc.dart';

// Phase 4 · Customers (L1)
import 'package:admin_panel/features/customer/data/datasources/customer_remote_datasource.dart';
import 'package:admin_panel/features/customer/data/datasources/customer_mock_datasource.dart';
import 'package:admin_panel/features/customer/data/repositories/customer_repository_impl.dart';
import 'package:admin_panel/features/customer/domain/repositories/customer_repository.dart';
import 'package:admin_panel/features/customer/domain/usecases/get_all_customer_usecase.dart';
import 'package:admin_panel/features/customer/domain/usecases/get_customer_usecase.dart';
import 'package:admin_panel/features/customer/domain/usecases/create_customer_usecase.dart';
import 'package:admin_panel/features/customer/domain/usecases/update_customer_usecase.dart';
import 'package:admin_panel/features/customer/domain/usecases/delete_customer_usecase.dart';
import 'package:admin_panel/features/customer/presentation/bloc/customer_bloc.dart';

// Phase 5 · Categories (L1)
import 'package:admin_panel/features/category/data/datasources/category_remote_datasource.dart';
import 'package:admin_panel/features/category/data/datasources/category_mock_datasource.dart';
import 'package:admin_panel/features/category/data/repositories/category_repository_impl.dart';
import 'package:admin_panel/features/category/domain/repositories/category_repository.dart';
import 'package:admin_panel/features/category/domain/usecases/get_all_category_usecase.dart';
import 'package:admin_panel/features/category/domain/usecases/get_category_usecase.dart';
import 'package:admin_panel/features/category/domain/usecases/create_category_usecase.dart';
import 'package:admin_panel/features/category/domain/usecases/update_category_usecase.dart';
import 'package:admin_panel/features/category/domain/usecases/delete_category_usecase.dart';
import 'package:admin_panel/features/category/presentation/bloc/category_bloc.dart';

// Phase 5 · Products (L2)
import 'package:admin_panel/features/product/data/datasources/product_remote_datasource.dart';
import 'package:admin_panel/features/product/data/datasources/product_mock_datasource.dart';
import 'package:admin_panel/features/product/data/repositories/product_repository_impl.dart';
import 'package:admin_panel/features/product/domain/repositories/product_repository.dart';
import 'package:admin_panel/features/product/domain/usecases/get_all_product_usecase.dart';
import 'package:admin_panel/features/product/domain/usecases/get_product_usecase.dart';
import 'package:admin_panel/features/product/domain/usecases/create_product_usecase.dart';
import 'package:admin_panel/features/product/domain/usecases/update_product_usecase.dart';
import 'package:admin_panel/features/product/domain/usecases/delete_product_usecase.dart';
import 'package:admin_panel/features/product/domain/services/product_domain_service.dart';
import 'package:admin_panel/features/product/presentation/bloc/product_bloc.dart';

// Phase 6 · Promotions (L3)
import 'package:admin_panel/features/promotion/data/datasources/promotion_remote_datasource.dart';
import 'package:admin_panel/features/promotion/data/repositories/promotion_repository_impl.dart';
import 'package:admin_panel/features/promotion/domain/repositories/promotion_repository.dart';
import 'package:admin_panel/features/promotion/domain/usecases/get_all_promotion_usecase.dart';
import 'package:admin_panel/features/promotion/domain/usecases/get_promotion_usecase.dart';
import 'package:admin_panel/features/promotion/domain/usecases/create_promotion_usecase.dart';
import 'package:admin_panel/features/promotion/domain/usecases/update_promotion_usecase.dart';
import 'package:admin_panel/features/promotion/domain/usecases/delete_promotion_usecase.dart';
import 'package:admin_panel/features/promotion/domain/services/promotion_domain_service.dart';
import 'package:admin_panel/features/promotion/presentation/bloc/promotion_bloc.dart';

// Phase 7 · Visits (L2)
import 'package:admin_panel/features/visit/data/datasources/visit_remote_datasource.dart';
import 'package:admin_panel/features/visit/data/datasources/visit_mock_datasource.dart';
import 'package:admin_panel/features/visit/data/repositories/visit_repository_impl.dart';
import 'package:admin_panel/features/visit/domain/repositories/visit_repository.dart';
import 'package:admin_panel/features/visit/domain/usecases/get_all_visit_usecase.dart';
import 'package:admin_panel/features/visit/domain/usecases/get_visit_usecase.dart';
import 'package:admin_panel/features/visit/domain/usecases/create_visit_usecase.dart';
import 'package:admin_panel/features/visit/domain/usecases/update_visit_usecase.dart';
import 'package:admin_panel/features/visit/domain/usecases/delete_visit_usecase.dart';
import 'package:admin_panel/features/visit/domain/services/visit_domain_service.dart';
import 'package:admin_panel/features/visit/presentation/bloc/visit_bloc.dart';

// Phase 7 · Weekly Plans (L2)
import 'package:admin_panel/features/weekly_plan/data/datasources/weekly_plan_remote_datasource.dart';
import 'package:admin_panel/features/weekly_plan/data/datasources/weekly_plan_mock_datasource.dart';
import 'package:admin_panel/features/weekly_plan/data/repositories/weekly_plan_repository_impl.dart';
import 'package:admin_panel/features/weekly_plan/domain/repositories/weekly_plan_repository.dart';
import 'package:admin_panel/features/weekly_plan/domain/usecases/get_all_weekly_plan_usecase.dart';
import 'package:admin_panel/features/weekly_plan/domain/usecases/get_weekly_plan_usecase.dart';
import 'package:admin_panel/features/weekly_plan/domain/usecases/create_weekly_plan_usecase.dart';
import 'package:admin_panel/features/weekly_plan/domain/usecases/update_weekly_plan_usecase.dart';
import 'package:admin_panel/features/weekly_plan/domain/usecases/delete_weekly_plan_usecase.dart';
import 'package:admin_panel/features/weekly_plan/domain/services/weekly_plan_domain_service.dart';
import 'package:admin_panel/features/weekly_plan/presentation/bloc/weekly_plan_bloc.dart';

// Phase 7 · Daily Reports (L3)
import 'package:admin_panel/features/daily_report/data/datasources/daily_report_remote_datasource.dart';
import 'package:admin_panel/features/daily_report/data/repositories/daily_report_repository_impl.dart';
import 'package:admin_panel/features/daily_report/domain/repositories/daily_report_repository.dart';
import 'package:admin_panel/features/daily_report/domain/usecases/get_all_daily_report_usecase.dart';
import 'package:admin_panel/features/daily_report/domain/usecases/get_daily_report_usecase.dart';
import 'package:admin_panel/features/daily_report/domain/usecases/create_daily_report_usecase.dart';
import 'package:admin_panel/features/daily_report/domain/usecases/update_daily_report_usecase.dart';
import 'package:admin_panel/features/daily_report/domain/usecases/delete_daily_report_usecase.dart';
import 'package:admin_panel/features/daily_report/domain/services/daily_report_domain_service.dart';
import 'package:admin_panel/features/daily_report/presentation/bloc/daily_report_bloc.dart';

// Phase 8 · Conversations (L1)
import 'package:admin_panel/features/conversation/data/datasources/conversation_remote_datasource.dart';
import 'package:admin_panel/features/conversation/data/repositories/conversation_repository_impl.dart';
import 'package:admin_panel/features/conversation/domain/repositories/conversation_repository.dart';
import 'package:admin_panel/features/conversation/domain/usecases/get_all_conversation_usecase.dart';
import 'package:admin_panel/features/conversation/domain/usecases/get_conversation_usecase.dart';
import 'package:admin_panel/features/conversation/domain/usecases/create_conversation_usecase.dart';
import 'package:admin_panel/features/conversation/domain/usecases/update_conversation_usecase.dart';
import 'package:admin_panel/features/conversation/domain/usecases/delete_conversation_usecase.dart';
import 'package:admin_panel/features/conversation/presentation/bloc/conversation_bloc.dart';

// Phase 8 · Orders (L3)
import 'package:admin_panel/features/order/data/datasources/order_remote_datasource.dart';
import 'package:admin_panel/features/order/data/repositories/order_repository_impl.dart';
import 'package:admin_panel/features/order/domain/repositories/order_repository.dart';
import 'package:admin_panel/features/order/domain/usecases/get_all_order_usecase.dart';
import 'package:admin_panel/features/order/domain/usecases/get_order_usecase.dart';
import 'package:admin_panel/features/order/domain/usecases/create_order_usecase.dart';
import 'package:admin_panel/features/order/domain/usecases/update_order_usecase.dart';
import 'package:admin_panel/features/order/domain/usecases/delete_order_usecase.dart';
import 'package:admin_panel/features/order/domain/services/order_domain_service.dart';
import 'package:admin_panel/features/order/presentation/bloc/order_bloc.dart';

// Phase 8 · Payments (L1)
import 'package:admin_panel/features/payment/data/datasources/payment_remote_datasource.dart';
import 'package:admin_panel/features/payment/data/repositories/payment_repository_impl.dart';
import 'package:admin_panel/features/payment/domain/repositories/payment_repository.dart';
import 'package:admin_panel/features/payment/domain/usecases/get_all_payment_usecase.dart';
import 'package:admin_panel/features/payment/domain/usecases/get_payment_usecase.dart';
import 'package:admin_panel/features/payment/domain/usecases/create_payment_usecase.dart';
import 'package:admin_panel/features/payment/domain/usecases/update_payment_usecase.dart';
import 'package:admin_panel/features/payment/domain/usecases/delete_payment_usecase.dart';
import 'package:admin_panel/features/payment/presentation/bloc/payment_bloc.dart';

// Phase 8 · Notifications (L2)
import 'package:admin_panel/features/notification/data/datasources/notification_remote_datasource.dart';
import 'package:admin_panel/features/notification/data/repositories/notification_repository_impl.dart';
import 'package:admin_panel/features/notification/domain/repositories/notification_repository.dart';
import 'package:admin_panel/features/notification/domain/usecases/get_all_notification_usecase.dart';
import 'package:admin_panel/features/notification/domain/usecases/get_notification_usecase.dart';
import 'package:admin_panel/features/notification/domain/usecases/create_notification_usecase.dart';
import 'package:admin_panel/features/notification/domain/usecases/update_notification_usecase.dart';
import 'package:admin_panel/features/notification/domain/usecases/delete_notification_usecase.dart';
import 'package:admin_panel/features/notification/domain/services/notification_domain_service.dart';
import 'package:admin_panel/features/notification/presentation/bloc/notification_bloc.dart';

// Phase 9 · Marketing Dashboard (L4)
import 'package:admin_panel/features/marketing_dashboard/domain/usecases/get_marketing_dashboard_usecase.dart';
import 'package:admin_panel/features/marketing_dashboard/presentation/cubit/marketing_dashboard_cubit.dart';

// Phase 9 · Sales Dashboard (L4)
import 'package:admin_panel/features/sales_dashboard/domain/usecases/get_sales_dashboard_usecase.dart';
import 'package:admin_panel/features/sales_dashboard/presentation/cubit/sales_dashboard_cubit.dart';

// Phase 9 · Report Export (L5)
import 'package:admin_panel/features/report_export/data/client/report_export_client.dart';
import 'package:admin_panel/features/report_export/domain/services/report_export_service.dart';
import 'package:admin_panel/features/report_export/presentation/cubit/report_export_cubit.dart';

// Phase 9 · Activity Logs (L1)
import 'package:admin_panel/features/activity_log/data/datasources/activity_log_remote_datasource.dart';
import 'package:admin_panel/features/activity_log/data/repositories/activity_log_repository_impl.dart';
import 'package:admin_panel/features/activity_log/domain/repositories/activity_log_repository.dart';
import 'package:admin_panel/features/activity_log/domain/usecases/get_all_activity_log_usecase.dart';
import 'package:admin_panel/features/activity_log/domain/usecases/get_activity_log_usecase.dart';
import 'package:admin_panel/features/activity_log/domain/usecases/create_activity_log_usecase.dart';
import 'package:admin_panel/features/activity_log/domain/usecases/update_activity_log_usecase.dart';
import 'package:admin_panel/features/activity_log/domain/usecases/delete_activity_log_usecase.dart';
import 'package:admin_panel/features/activity_log/presentation/bloc/activity_log_bloc.dart';

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

// Add BEFORE each DomainService — one per feature:
import 'package:admin_panel/features/officer/domain/guards/officer_transition_guard.dart';
import 'package:admin_panel/features/product/domain/guards/product_transition_guard.dart';
import 'package:admin_panel/features/promotion/domain/guards/promotion_transition_guard.dart';
import 'package:admin_panel/features/visit/domain/guards/visit_transition_guard.dart';
import 'package:admin_panel/features/weekly_plan/domain/guards/weekly_plan_transition_guard.dart';
import 'package:admin_panel/features/daily_report/domain/guards/daily_report_transition_guard.dart';
import 'package:admin_panel/features/order/domain/guards/order_transition_guard.dart';
import 'package:admin_panel/features/notification/domain/guards/notification_transition_guard.dart';

import 'package:admin_panel/features/marketing_dashboard/data/providers/visit_data_provider_impl.dart';
import 'package:admin_panel/features/marketing_dashboard/data/providers/weekly_plan_data_provider_impl.dart';
import 'package:admin_panel/features/marketing_dashboard/data/providers/daily_report_data_provider_impl.dart';
import 'package:admin_panel/features/marketing_dashboard/data/providers/officer_data_provider_impl.dart';
import 'package:admin_panel/features/marketing_dashboard/data/providers/customer_data_provider_impl.dart';
import 'package:admin_panel/features/marketing_dashboard/domain/providers/visit_data_provider.dart';
import 'package:admin_panel/features/marketing_dashboard/domain/providers/weekly_plan_data_provider.dart';
import 'package:admin_panel/features/marketing_dashboard/domain/providers/daily_report_data_provider.dart';
import 'package:admin_panel/features/marketing_dashboard/domain/providers/officer_data_provider.dart';
import 'package:admin_panel/features/marketing_dashboard/domain/providers/customer_data_provider.dart';
import 'package:admin_panel/features/sales_dashboard/data/providers/order_data_provider_impl.dart';
import 'package:admin_panel/features/sales_dashboard/data/providers/payment_data_provider_impl.dart';
import 'package:admin_panel/features/sales_dashboard/data/providers/product_data_provider_impl.dart';
import 'package:admin_panel/features/sales_dashboard/domain/providers/order_data_provider.dart';
import 'package:admin_panel/features/sales_dashboard/domain/providers/payment_data_provider.dart';
import 'package:admin_panel/features/sales_dashboard/domain/providers/product_data_provider.dart';

final sl = GetIt.instance;

Future<void> initDependencies() async {
  // -- 1. Infrastructure -------------------------------------
  sl.registerLazySingleton<FlutterSecureStorage>(
    () => const FlutterSecureStorage(),
  );
  sl.registerLazySingleton<SecureStorageService>(
    () => SecureStorageService(sl<FlutterSecureStorage>()),
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

  // -- 5. Actor (HMSCP core – L1) ----------------------------
  sl.registerLazySingleton<ActorCacheDao>(() => ActorCacheDao(sl()));
  sl.registerLazySingleton<ActorRemoteDataSource>(
    () => ActorRemoteDataSourceImpl(dio: sl()),
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
  // BARICK FEATURES — Phase 3: External Integrations (L5)
  // Pattern: Client ? Service ? Cubit  (cubit takes service:)
  // ----------------------------------------------------------

  sl.registerLazySingleton(() => SmsGatewayClient(dio: sl()));
  sl.registerLazySingleton(() => SmsGatewayService(client: sl()));
  sl.registerFactory<SmsGatewayCubit>(() => SmsGatewayCubit(service: sl()));

  sl.registerLazySingleton(() => WhatsappClient(dio: sl()));
  sl.registerLazySingleton(() => WhatsappService(client: sl()));
  sl.registerFactory<WhatsappCubit>(() => WhatsappCubit(service: sl()));

  sl.registerLazySingleton(() => MobileMoneyClient(dio: sl()));
  sl.registerLazySingleton(() => MobileMoneyService(client: sl()));
  sl.registerFactory<MobileMoneyCubit>(() => MobileMoneyCubit(service: sl()));

  // ----------------------------------------------------------
  // Phase 4: User & Customer (L2 / L1)
  // L2 repos use remoteDataSource:, blocs need domainService:
  // ----------------------------------------------------------

  // Seq 6 · Officers (L2)
  sl.registerLazySingleton<OfficerRemoteDataSource>(
    () => OfficerMockDataSource(),
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

  // Seq 7 · Customers (L1)
  sl.registerLazySingleton<CustomerRemoteDataSource>(
    () => CustomerMockDataSource(),
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

  // Seq 8 · Categories (L1)
  sl.registerLazySingleton<CategoryRemoteDataSource>(
    () => CategoryMockDataSource(),
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

  // Seq 9 · Products (L2)
  sl.registerLazySingleton<ProductRemoteDataSource>(
    () => ProductMockDataSource(),
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
  // Phase 6: Promotions (L3) — domainService required
  // ----------------------------------------------------------

  sl.registerLazySingleton<PromotionRemoteDataSource>(
    () => PromotionRemoteDataSourceImpl(dio: sl()),
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

  // Seq 11 · Visits (L2)
  sl.registerLazySingleton<VisitRemoteDataSource>(
    () => VisitMockDataSource(),
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
  sl.registerLazySingleton(() => CreateVisitUseCase(sl()));
  sl.registerLazySingleton(() => UpdateVisitUseCase(sl()));
  sl.registerLazySingleton(() => DeleteVisitUseCase(sl()));
  sl.registerFactory<VisitBloc>(
    () => VisitBloc(
      getAllUseCase: sl(),
      getUseCase: sl(),
      createUseCase: sl(),
      updateUseCase: sl(),
      deleteUseCase: sl(),
      domainService: sl(),
    ),
  );

  // Seq 12 · Weekly Plans (L2)
  sl.registerLazySingleton<WeeklyPlanRemoteDataSource>(
    () => WeeklyPlanMockDataSource(),
  );
  sl.registerLazySingleton<WeeklyPlanRepository>(
    () => WeeklyPlanRepositoryImpl(remoteDataSource: sl()),
  );
  sl.registerLazySingleton(() => WeeklyPlanTransitionGuard());
  sl.registerLazySingleton(
    () => WeeklyPlanDomainService(repository: sl(), guard: sl()),
  );
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

  // Seq 13 · Daily Reports (L3)
  sl.registerLazySingleton<DailyReportRemoteDataSource>(
    () => DailyReportRemoteDataSourceImpl(dio: sl()),
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

  // Seq 14 · Conversations (L1)
  sl.registerLazySingleton<ConversationRemoteDataSource>(
    () => ConversationRemoteDataSourceImpl(dio: sl()),
  );
  sl.registerLazySingleton<ConversationRepository>(
    () => ConversationRepositoryImpl(remoteDataSource: sl()),
  );
  sl.registerLazySingleton(() => GetAllConversationUseCase(sl()));
  sl.registerLazySingleton(() => GetConversationUseCase(sl()));
  sl.registerLazySingleton(() => CreateConversationUseCase(sl()));
  sl.registerLazySingleton(() => UpdateConversationUseCase(sl()));
  sl.registerLazySingleton(() => DeleteConversationUseCase(sl()));
  sl.registerFactory<ConversationBloc>(
    () => ConversationBloc(
      getAllUseCase: sl(),
      getUseCase: sl(),
      createUseCase: sl(),
      updateUseCase: sl(),
      deleteUseCase: sl(),
    ),
  );

  // Seq 15 · Orders (L3)
  sl.registerLazySingleton<OrderRemoteDataSource>(
    () => OrderRemoteDataSourceImpl(dio: sl()),
  );
  sl.registerLazySingleton<OrderRepository>(
    () => OrderRepositoryImpl(remoteDataSource: sl()),
  );
  sl.registerLazySingleton(() => OrderTransitionGuard());
  sl.registerLazySingleton(
    () => OrderDomainService(repository: sl(), guard: sl()),
  );
  sl.registerLazySingleton(() => GetAllOrderUseCase(sl()));
  sl.registerLazySingleton(() => GetOrderUseCase(sl()));
  sl.registerLazySingleton(() => CreateOrderUseCase(sl()));
  sl.registerLazySingleton(() => UpdateOrderUseCase(sl()));
  sl.registerLazySingleton(() => DeleteOrderUseCase(sl()));
  sl.registerFactory<OrderBloc>(
    () => OrderBloc(
      getAllUseCase: sl(),
      getUseCase: sl(),
      createUseCase: sl(),
      updateUseCase: sl(),
      deleteUseCase: sl(),
      domainService: sl(),
    ),
  );

  // Seq 16 · Payments (L1)
  sl.registerLazySingleton<PaymentRemoteDataSource>(
    () => PaymentRemoteDataSourceImpl(dio: sl()),
  );
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

  // Seq 17 · Notifications (L2)
  sl.registerLazySingleton<NotificationRemoteDataSource>(
    () => NotificationRemoteDataSourceImpl(dio: sl()),
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
  sl.registerLazySingleton(() => CreateNotificationUseCase(sl()));
  sl.registerLazySingleton(() => UpdateNotificationUseCase(sl()));
  sl.registerLazySingleton(() => DeleteNotificationUseCase(sl()));
  sl.registerFactory<NotificationBloc>(
    () => NotificationBloc(
      getAllUseCase: sl(),
      getUseCase: sl(),
      createUseCase: sl(),
      updateUseCase: sl(),
      deleteUseCase: sl(),
      domainService: sl(),
    ),
  );

  // ----------------------------------------------------------
  // Phase 9: Analytics & Reporting
  // L4 cubits use getProjection:, L5 cubits use service:
  // ----------------------------------------------------------

  // Seq 18 · Marketing Dashboard (L4)
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

  // Seq 19 · Sales Dashboard (L4)
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

  // Seq 20 · Report Export (L5)
  sl.registerLazySingleton(() => ReportExportClient(dio: sl()));
  sl.registerLazySingleton(() => ReportExportService(client: sl()));

  sl.registerFactory<ReportExportCubit>(() => ReportExportCubit(service: sl()));

  // Seq 21 · Activity Logs (L1)
  sl.registerLazySingleton<ActivityLogRemoteDataSource>(
    () => ActivityLogRemoteDataSourceImpl(dio: sl()),
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
