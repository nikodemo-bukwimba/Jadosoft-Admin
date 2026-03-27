// ============================================================================
// ORGANIZATION FEATURE — DI REGISTRATION
// ============================================================================
//
// Add to injection_container.dart imports:
//   import 'package:admin_panel/features/organization/data/datasources/organization_remote_datasource.dart';
//   import 'package:admin_panel/features/organization/data/repositories/organization_repository_impl.dart';
//   import 'package:admin_panel/features/organization/domain/repositories/organization_repository.dart';
//   import 'package:admin_panel/features/organization/presentation/bloc/organization_bloc.dart';
//
// Add to initDependencies() body:
//
//   // Seq 6b — Organization Management
//   sl.registerLazySingleton<OrganizationRemoteDataSource>(
//     () => OrganizationRemoteDataSource(dio: sl(), orgContext: sl()),
//   );
//   sl.registerLazySingleton<OrganizationRepository>(
//     () => OrganizationRepositoryImpl(remote: sl()),
//   );
//   sl.registerFactory<OrganizationBloc>(
//     () => OrganizationBloc(repository: sl(), orgContext: sl()),
//   );
//
// Add to app_router.dart:
//   import '../../features/organization/presentation/bloc/organization_bloc.dart';
//   import '../../features/organization/presentation/bloc/organization_event.dart';
//   import '../../features/organization/presentation/pages/organization_hub_page.dart';
//
//   // Route constants:
//   static const String orgHub = '/organization';
//
//   // Route definition inside ShellRoute:
//   GoRoute(
//     path: orgHub,
//     builder: (_, _) => BlocProvider(
//       create: (_) => sl<OrganizationBloc>()..add(OrgLoadRequested()),
//       child: const OrganizationHubPage(),
//     ),
//   ),
//
// Add to shell_nav_items.dart:
//   if (auth.can('org.manage'))
//     NavItem(
//       id: 'organization',
//       label: 'Organization',
//       icon: Icons.business_outlined,
//       path: AppRouter.orgHub,
//     ),
// ============================================================================
