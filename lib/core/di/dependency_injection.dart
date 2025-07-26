import 'package:blank_project/modules/home/logic/internet_connection/internet_connection_cubit.dart';
import 'package:blank_project/modules/home/logic/localization/localization_cubit.dart';
import 'package:get_it/get_it.dart';
import 'package:dio/dio.dart';

import '../../modules/home/logic/theme/theme_cubit.dart';
import '../networking/api_service.dart';
import '../networking/dio_factory.dart';


final getIt = GetIt.instance;

Future<void> setupGetIt() async {
  // MARK: - Dio & ApiService.
  Dio dio = DioFactory.getDio();
  getIt.registerLazySingleton<ApiService>(() => ApiService(dio));

  // MARK: - Shared.
  getIt.registerLazySingleton<ThemeCubit>(() => getIt<ThemeCubit>());
  getIt.registerLazySingleton<LocalizationCubit>(() => getIt<LocalizationCubit>());
  getIt.registerLazySingleton<InternetConnectionCubit>(() => getIt<InternetConnectionCubit>());
  // getIt.registerLazySingleton<SharedPreferencesHelper>(() => SharedPreferencesHelper());


  // MARK: - Login.
  // getIt.registerLazySingleton<LoginRepo>(() => LoginRepo(getIt<ApiService>()));
  // getIt.registerLazySingleton<LoginCubit>(() => LoginCubit(getIt<LoginRepo>()));
  // getIt.registerFactory<ToggleObscureTextCubit>(() => ToggleObscureTextCubit());
  // getIt.registerFactory<ToggleRememberMeCubit>(() => ToggleRememberMeCubit());

  // MARK: - Home.
  // getIt.registerLazySingleton<HomeRepo>(() => HomeRepo(getIt<ApiService>()));
  // getIt.registerLazySingleton<HomeCubit>(() => HomeCubit(getIt<HomeRepo>()));

  // MARK: - Shared.
}