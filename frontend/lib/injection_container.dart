/// "Dependency injection container using GetIt to decouple components."
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';

import 'core/constants/api_constants.dart';
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

import 'features/points/data/datasources/points_remote_data_source.dart';
import 'features/points/data/repositories/points_repository_impl.dart';
import 'features/points/domain/repositories/points_repository.dart';
import 'features/points/domain/usecases/get_points_summary_usecase.dart';
import 'features/points/domain/usecases/get_points_history_usecase.dart';
import 'features/points/domain/usecases/get_leaderboard_usecase.dart';
import 'features/points/presentation/bloc/points_bloc.dart';

final sl = GetIt.instance; // sl stands for Service Locator

Future<void> init() async {
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
  sl.registerLazySingleton<AuthLocalDataSource>(
    () => AuthLocalDataSourceImpl(secureStorage: sl()),
  );

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
    () => RecognitionsRemoteDataSourceImpl(dio: sl()),
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

  //! Core
  sl.registerLazySingleton(
      () => AuthInterceptor(tokenProvider: sl<AuthLocalDataSource>()));
  sl.registerLazySingleton(() => ApiClient(dio: sl(), authInterceptor: sl()));

  //! External
  sl.registerLazySingleton(
    () => Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout:
            const Duration(milliseconds: ApiConstants.connectTimeout),
        receiveTimeout:
            const Duration(milliseconds: ApiConstants.receiveTimeout),
      ),
    ),
  );
  sl.registerLazySingleton(() => const FlutterSecureStorage());
}
