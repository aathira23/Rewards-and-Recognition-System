/// "Dependency injection container using GetIt to decouple components."
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'core/network/web_token_provider.dart';

import 'core/network/auth_interceptor.dart';
import 'core/network/api_client.dart';

import 'features/auth/data/datasources/auth_local_data_source.dart';
import 'features/auth/data/datasources/auth_remote_data_source.dart';
import 'features/auth/data/repositories/auth_repository_impl.dart';
import 'features/auth/domain/repositories/auth_repository.dart';
import 'features/auth/domain/usecases/check_auth_status_usecase.dart';
import 'features/auth/domain/usecases/login_usecase.dart';
import 'features/auth/domain/usecases/logout_usecase.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';

import 'features/profile/data/datasources/profile_remote_data_source.dart';
import 'features/profile/data/repositories/profile_repository_impl.dart';
import 'features/profile/domain/repositories/profile_repository.dart';
import 'features/profile/domain/usecases/get_me_usecase.dart';
import 'features/profile/domain/usecases/get_users_usecase.dart';

import 'features/recognitions/data/datasources/recognitions_remote_data_source.dart';
import 'features/recognitions/data/repositories/recognitions_repository_impl.dart';
import 'features/recognitions/domain/repositories/recognitions_repository.dart';
import 'features/recognitions/domain/usecases/get_badges_usecase.dart';
import 'features/recognitions/domain/usecases/get_recognition_feed_usecase.dart';
import 'features/recognitions/domain/usecases/send_recognition_usecase.dart';
import 'features/recognitions/domain/usecases/get_appreciation_stats_usecase.dart';
import 'features/recognitions/presentation/bloc/recognitions_bloc.dart';

import 'features/catalog/data/datasources/catalog_remote_data_source.dart';
import 'features/catalog/data/repositories/catalog_repository_impl.dart';
import 'features/catalog/domain/repositories/catalog_repository.dart';
import 'features/catalog/domain/usecases/get_catalog_items_usecase.dart';
import 'features/catalog/domain/usecases/redeem_item_usecase.dart';
import 'features/catalog/domain/usecases/get_history_usecase.dart';
import 'features/catalog/domain/usecases/submit_conversion_usecase.dart';
import 'features/catalog/domain/usecases/get_points_rules_usecase.dart';
import 'features/catalog/presentation/bloc/catalog_bloc.dart';

import 'features/points/data/datasources/points_remote_data_source.dart';
import 'features/points/data/repositories/points_repository_impl.dart';
import 'features/points/domain/repositories/points_repository.dart';
import 'features/points/domain/usecases/get_points_summary_usecase.dart';
import 'features/points/domain/usecases/get_points_history_usecase.dart';
import 'features/points/domain/usecases/get_leaderboard_usecase.dart';
import 'features/points/presentation/bloc/points_bloc.dart';

// Notifications
import 'features/notifications/data/datasources/notifications_remote_data_source.dart';
import 'features/notifications/data/repositories/notifications_repository_impl.dart';
import 'features/notifications/domain/repositories/notifications_repository.dart';
import 'features/notifications/domain/usecases/get_notifications_usecase.dart';
import 'features/notifications/domain/usecases/get_unread_count_usecase.dart';
import 'features/notifications/domain/usecases/mark_as_read_usecase.dart';
import 'features/notifications/presentation/bloc/notifications_bloc.dart';

// Celebrations
import 'features/celebrations/data/datasources/celebrations_remote_data_source.dart';
import 'features/celebrations/data/repositories/celebrations_repository_impl.dart';
import 'features/celebrations/domain/repositories/celebrations_repository.dart';
import 'features/celebrations/domain/usecases/get_upcoming_celebrations_usecase.dart';
import 'features/celebrations/domain/usecases/get_celebration_history_usecase.dart';
import 'features/celebrations/presentation/bloc/celebrations_bloc.dart';

// Nominations / Awards
import 'features/nominations/data/datasources/nominations_remote_data_source.dart';
import 'features/nominations/data/repositories/nominations_repository_impl.dart';
import 'features/nominations/domain/repositories/nominations_repository.dart';
import 'features/nominations/domain/usecases/get_award_types_usecase.dart';
import 'features/nominations/domain/usecases/get_nominations_usecase.dart';
import 'features/nominations/domain/usecases/create_nomination_usecase.dart';
import 'features/nominations/domain/usecases/approve_nomination_usecase.dart';
import 'features/nominations/domain/usecases/reject_nomination_usecase.dart';
import 'features/nominations/presentation/bloc/nominations_bloc.dart';

// Analytics
import 'features/analytics/data/datasources/analytics_remote_data_source.dart';
import 'features/analytics/data/repositories/analytics_repository_impl.dart';
import 'features/analytics/domain/repositories/analytics_repository.dart';
import 'features/analytics/domain/usecases/get_analytics_usecase.dart';
import 'features/analytics/presentation/bloc/analytics_bloc.dart';

// Departments
import 'features/departments/data/datasources/department_remote_data_source.dart';
import 'features/departments/data/repositories/department_repository_impl.dart';
import 'features/departments/domain/repositories/department_repository.dart';
import 'features/departments/domain/usecases/get_departments_usecase.dart';
import 'features/departments/domain/usecases/create_department_usecase.dart';
import 'features/departments/domain/usecases/update_department_usecase.dart';
import 'features/departments/domain/usecases/delete_department_usecase.dart';
import 'features/departments/presentation/bloc/department_bloc.dart';

// Config
import 'features/config/data/datasources/config_remote_data_source.dart';
import 'features/config/data/repositories/config_repository_impl.dart';
import 'features/config/domain/repositories/config_repository.dart';
import 'features/config/domain/usecases/get_system_configs_usecase.dart';
import 'features/config/domain/usecases/get_points_rules_config_usecase.dart';
import 'features/config/domain/usecases/update_system_config_usecase.dart';
import 'features/config/presentation/bloc/config_bloc.dart';

// Budgets
import 'features/budgets/data/datasources/budget_remote_data_source.dart';
import 'features/budgets/data/repositories/budget_repository_impl.dart';
import 'features/budgets/domain/repositories/budget_repository.dart';
import 'features/budgets/domain/usecases/get_budget_wallet_usecase.dart';
import 'features/budgets/domain/usecases/allocate_budget_usecase.dart';
import 'features/budgets/domain/usecases/reward_employee_usecase.dart';
import 'features/budgets/presentation/bloc/budget_bloc.dart';

// Reports & Payroll
import 'features/reports/data/datasources/reports_remote_data_source.dart';
import 'features/reports/data/repositories/reports_repository_impl.dart';
import 'features/reports/domain/repositories/reports_repository.dart';
import 'features/reports/domain/usecases/fetch_report_usecase.dart';
import 'features/reports/domain/usecases/export_report_csv_usecase.dart';
import 'features/reports/domain/usecases/fetch_payroll_usecase.dart';
import 'features/reports/domain/usecases/export_payroll_csv_usecase.dart';
import 'features/reports/domain/usecases/fetch_departments_for_reports_usecase.dart';
import 'features/reports/presentation/bloc/reports_bloc.dart';
import 'features/reports/presentation/bloc/payroll_bloc.dart';

// HR Config
import 'features/hr/data/datasources/hr_config_remote_data_source.dart';
import 'features/hr/data/repositories/hr_config_repository_impl.dart';
import 'features/hr/domain/repositories/hr_config_repository.dart';
import 'features/hr/domain/usecases/load_all_hr_config_usecase.dart';
import 'features/hr/domain/usecases/save_hr_config_item_usecase.dart';
import 'features/hr/domain/usecases/toggle_hr_config_item_usecase.dart';
import 'features/hr/domain/usecases/update_hr_config_setting_usecase.dart';
import 'features/hr/presentation/bloc/hr_config_bloc.dart';

// HR Approvals
import 'features/hr/data/datasources/hr_approvals_remote_data_source.dart';
import 'features/hr/data/repositories/hr_approvals_repository_impl.dart';
import 'features/hr/domain/repositories/hr_approvals_repository.dart';
import 'features/hr/presentation/bloc/hr_approvals_bloc.dart';

final sl = GetIt.instance; // sl stands for Service Locator

Future<void> init() async {
  //! External
  sl.registerLazySingleton(() => Dio());
  if (!kIsWeb) {
    sl.registerLazySingleton(() => const FlutterSecureStorage());
  }

  //! Core
  sl.registerLazySingleton(
      () => AuthInterceptor(tokenProvider: sl<AuthLocalDataSource>()));
  sl.registerLazySingleton(() => ApiClient(dio: sl(), authInterceptor: sl()));

  //! Features - Authentication
  // Bloc
  sl.registerFactory(
    () => AuthBloc(
      loginUseCase: sl(),
      logoutUseCase: sl(),
      checkAuthStatusUseCase: sl(),
      getMeUseCase: sl(),
    ),
  );

  // Use cases
  sl.registerLazySingleton(() => LoginUseCase(sl()));
  sl.registerLazySingleton(() => GetMeUseCase(sl()));
  sl.registerLazySingleton(() => GetUsersUseCase(sl()));
  sl.registerLazySingleton(() => LogoutUseCase(sl()));
  sl.registerLazySingleton(() => CheckAuthStatusUseCase(sl()));

  //! Features - Recognitions
  sl.registerLazySingleton(() => GetBadgesUseCase(sl()));
  sl.registerLazySingleton(() => GetRecognitionFeedUseCase(sl()));
  sl.registerLazySingleton(() => SendRecognitionUseCase(sl()));
  sl.registerLazySingleton(() => GetAppreciationStatsUseCase(sl()));

  // Repository
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      remoteDataSource: sl(),
      localDataSource: sl(),
    ),
  );

  // Data sources
  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(client: sl()),
  );
  // On web, use SharedPreferences; on native use FlutterSecureStorage.
  if (kIsWeb) {
    sl.registerLazySingleton<AuthLocalDataSource>(
      () => WebTokenProviderImpl(),
    );
  } else {
    sl.registerLazySingleton<AuthLocalDataSource>(
      () => AuthLocalDataSourceImpl(secureStorage: sl()),
    );
  }

  //! Features - Profile
  // Use cases

  // Repository
  sl.registerLazySingleton<ProfileRepository>(
    () => ProfileRepositoryImpl(remoteDataSource: sl()),
  );

  sl.registerLazySingleton<RecognitionsRepository>(
    () => RecognitionsRepositoryImpl(remoteDataSource: sl()),
  );

  // Data sources
  sl.registerLazySingleton<ProfileRemoteDataSource>(
    () => ProfileRemoteDataSourceImpl(client: sl()),
  );

  sl.registerLazySingleton<RecognitionsRemoteDataSource>(
    () => RecognitionsRemoteDataSourceImpl(client: sl()),
  );

  sl.registerFactory(
    () => RecognitionsBloc(
      getBadgesUseCase: sl(),
      getRecognitionFeedUseCase: sl(),
      sendRecognitionUseCase: sl(),
      getAppreciationStatsUseCase: sl(),
      getUsersUseCase: sl(),
    ),
  );

  sl.registerFactory(
    () => PointsBloc(
      getPointsSummaryUseCase: sl(),
      getPointsHistoryUseCase: sl(),
      getLeaderboardUseCase: sl(),
    ),
  );

  //! Features - Catalog
  // Bloc
  sl.registerFactory(
    () => CatalogBloc(
      getCatalogItemsUseCase: sl(),
      redeemItemUseCase: sl(),
      getHistoryUseCase: sl(),
      submitConversionUseCase: sl(),
      getPointsRulesUseCase: sl(),
    ),
  );

  // Use cases
  sl.registerLazySingleton(() => GetCatalogItemsUseCase(sl()));
  sl.registerLazySingleton(() => RedeemItemUseCase(sl()));
  sl.registerLazySingleton(() => GetHistoryUseCase(sl()));
  sl.registerLazySingleton(() => SubmitConversionUseCase(sl()));
  sl.registerLazySingleton(() => GetPointsRulesUseCase(sl()));

  // Repository
  sl.registerLazySingleton<CatalogRepository>(
    () => CatalogRepositoryImpl(remoteDataSource: sl()),
  );

  // Data sources
  sl.registerLazySingleton<CatalogRemoteDataSource>(
    () => CatalogRemoteDataSourceImpl(client: sl()),
  );

  //! Features - Points
  // Use cases
  sl.registerLazySingleton(() => GetPointsSummaryUseCase(sl()));
  sl.registerLazySingleton(() => GetPointsHistoryUseCase(sl()));
  sl.registerLazySingleton(() => GetLeaderboardUseCase(sl()));

  // Repository
  sl.registerLazySingleton<PointsRepository>(
    () => PointsRepositoryImpl(remoteDataSource: sl()),
  );

  // Data sources
  sl.registerLazySingleton<PointsRemoteDataSource>(
    () => PointsRemoteDataSourceImpl(client: sl()),
  );

  //! Features - Notifications
  // Bloc
  sl.registerFactory(
    () => NotificationsBloc(
      getNotificationsUseCase: sl(),
      getUnreadCountUseCase: sl(),
      markAsReadUseCase: sl(),
    ),
  );
  // Use cases
  sl.registerLazySingleton(() => GetNotificationsUseCase(sl()));
  sl.registerLazySingleton(() => GetUnreadCountUseCase(sl()));
  sl.registerLazySingleton(() => MarkAsReadUseCase(sl()));
  // Repository
  sl.registerLazySingleton<NotificationsRepository>(
    () => NotificationsRepositoryImpl(remoteDataSource: sl()),
  );
  // Data sources
  sl.registerLazySingleton<NotificationsRemoteDataSource>(
    () => NotificationsRemoteDataSourceImpl(client: sl()),
  );

  //! Features - Celebrations
  // Bloc
  sl.registerFactory(
    () => CelebrationsBloc(
      getUpcomingUseCase: sl(),
      getHistoryUseCase: sl(),
    ),
  );
  // Use cases
  sl.registerLazySingleton(() => GetUpcomingCelebrationsUseCase(sl()));
  sl.registerLazySingleton(() => GetCelebrationHistoryUseCase(sl()));
  // Repository
  sl.registerLazySingleton<CelebrationsRepository>(
    () => CelebrationsRepositoryImpl(remoteDataSource: sl()),
  );
  // Data sources
  sl.registerLazySingleton<CelebrationsRemoteDataSource>(
    () => CelebrationsRemoteDataSourceImpl(client: sl()),
  );

  //! Features - Nominations / Awards
  // Bloc
  sl.registerFactory(
    () => NominationsBloc(
      getAwardTypesUseCase: sl(),
      getNominationsUseCase: sl(),
      createNominationUseCase: sl(),
      approveNominationUseCase: sl(),
      rejectNominationUseCase: sl(),
      getUsersUseCase: sl<GetUsersUseCase>(),
    ),
  );
  // Use cases
  sl.registerLazySingleton(() => GetAwardTypesUseCase(sl()));
  sl.registerLazySingleton(() => GetNominationsUseCase(sl()));
  sl.registerLazySingleton(() => CreateNominationUseCase(sl()));
  sl.registerLazySingleton(() => ApproveNominationUseCase(sl()));
  sl.registerLazySingleton(() => RejectNominationUseCase(sl()));
  // Repository
  sl.registerLazySingleton<NominationsRepository>(
    () => NominationsRepositoryImpl(remoteDataSource: sl()),
  );
  // Data sources
  sl.registerLazySingleton<NominationsRemoteDataSource>(
    () => NominationsRemoteDataSourceImpl(client: sl()),
  );

  //! Features - Analytics
  // Bloc
  sl.registerFactory(
    () => AnalyticsBloc(getAnalyticsUseCase: sl()),
  );
  // Use cases
  sl.registerLazySingleton(() => GetAnalyticsUseCase(sl()));
  // Repository
  sl.registerLazySingleton<AnalyticsRepository>(
    () => AnalyticsRepositoryImpl(remoteDataSource: sl()),
  );
  // Data sources
  sl.registerLazySingleton<AnalyticsRemoteDataSource>(
    () => AnalyticsRemoteDataSourceImpl(client: sl()),
  );

  //! Features - Departments
  // Bloc
  sl.registerFactory(
    () => DepartmentBloc(
      getDepartmentsUseCase: sl(),
      createDepartmentUseCase: sl(),
      updateDepartmentUseCase: sl(),
      deleteDepartmentUseCase: sl(),
    ),
  );
  // Use cases
  sl.registerLazySingleton(() => GetDepartmentsUseCase(sl()));
  sl.registerLazySingleton(() => CreateDepartmentUseCase(sl()));
  sl.registerLazySingleton(() => UpdateDepartmentUseCase(sl()));
  sl.registerLazySingleton(() => DeleteDepartmentUseCase(sl()));
  // Repository
  sl.registerLazySingleton<DepartmentRepository>(
    () => DepartmentRepositoryImpl(remoteDataSource: sl()),
  );
  // Data sources
  sl.registerLazySingleton<DepartmentRemoteDataSource>(
    () => DepartmentRemoteDataSourceImpl(client: sl()),
  );

  //! Features - Config
  // Bloc
  sl.registerFactory(
    () => ConfigBloc(
      getSystemConfigsUseCase: sl(),
      getPointsRulesConfigUseCase: sl(),
      updateSystemConfigUseCase: sl(),
    ),
  );
  // Use cases
  sl.registerLazySingleton(() => GetSystemConfigsUseCase(sl()));
  sl.registerLazySingleton(() => GetPointsRulesConfigUseCase(sl()));
  sl.registerLazySingleton(() => UpdateSystemConfigUseCase(sl()));
  // Repository
  sl.registerLazySingleton<ConfigRepository>(
    () => ConfigRepositoryImpl(remoteDataSource: sl()),
  );
  // Data sources
  sl.registerLazySingleton<ConfigRemoteDataSource>(
    () => ConfigRemoteDataSourceImpl(client: sl()),
  );

  //! Features - Budgets
  // Bloc
  sl.registerFactory(
    () => BudgetBloc(
      getBudgetWalletUseCase: sl(),
      allocateBudgetUseCase: sl(),
      rewardEmployeeUseCase: sl(),
      getUsersUseCase: sl(),
      getMeUseCase: sl(),
    ),
  );
  // Use cases
  sl.registerLazySingleton(() => GetBudgetWalletUseCase(sl()));
  sl.registerLazySingleton(() => AllocateBudgetUseCase(sl()));
  sl.registerLazySingleton(() => RewardEmployeeUseCase(sl()));
  // Repository
  sl.registerLazySingleton<BudgetRepository>(
    () => BudgetRepositoryImpl(remoteDataSource: sl()),
  );
  // Data sources
  sl.registerLazySingleton<BudgetRemoteDataSource>(
    () => BudgetRemoteDataSourceImpl(client: sl()),
  );

  //! Features - Reports & Payroll
  // Blocs
  sl.registerFactory(
    () => ReportsBloc(
      fetchReportUseCase: sl(),
      exportReportCsvUseCase: sl(),
      fetchDepartmentsUseCase: sl(),
    ),
  );
  sl.registerFactory(
    () => PayrollBloc(
      fetchPayrollUseCase: sl(),
      exportPayrollCsvUseCase: sl(),
    ),
  );
  // Use cases
  sl.registerLazySingleton(() => FetchReportUseCase(sl()));
  sl.registerLazySingleton(() => ExportReportCsvUseCase(sl()));
  sl.registerLazySingleton(() => FetchPayrollUseCase(sl()));
  sl.registerLazySingleton(() => ExportPayrollCsvUseCase(sl()));
  sl.registerLazySingleton(() => FetchDepartmentsForReportsUseCase(sl()));
  // Repository
  sl.registerLazySingleton<ReportsRepository>(
    () => ReportsRepositoryImpl(remoteDataSource: sl()),
  );
  // Data sources
  sl.registerLazySingleton<ReportsRemoteDataSource>(
    () => ReportsRemoteDataSourceImpl(client: sl()),
  );

  //! Features - HR Config
  // Bloc
  sl.registerFactory(
    () => HrConfigBloc(
      loadAllUseCase: sl(),
      saveItemUseCase: sl(),
      toggleItemUseCase: sl(),
      updateSettingUseCase: sl(),
    ),
  );
  // Use cases
  sl.registerLazySingleton(() => LoadAllHrConfigUseCase(sl()));
  sl.registerLazySingleton(() => SaveHrConfigItemUseCase(sl()));
  sl.registerLazySingleton(() => ToggleHrConfigItemUseCase(sl()));
  sl.registerLazySingleton(() => UpdateHrConfigSettingUseCase(sl()));
  // Repository
  sl.registerLazySingleton<HrConfigRepository>(
    () => HrConfigRepositoryImpl(remoteDataSource: sl()),
  );
  // Data sources
  sl.registerLazySingleton<HrConfigRemoteDataSource>(
    () => HrConfigRemoteDataSourceImpl(client: sl()),
  );

  //! Features - HR Approvals
  // Bloc
  sl.registerFactory(
    () => HrApprovalsBloc(repository: sl()),
  );
  // Repository
  sl.registerLazySingleton<HrApprovalsRepository>(
    () => HrApprovalsRepositoryImpl(remoteDataSource: sl()),
  );
  // Data sources
  sl.registerLazySingleton<HrApprovalsRemoteDataSource>(
    () => HrApprovalsRemoteDataSourceImpl(client: sl()),
  );
}
