import 'package:aidsense/modules/home/logic/internet_connection/internet_connection_cubit.dart';
import 'package:aidsense/modules/home/logic/localization/localization_cubit.dart';
import 'package:aidsense/modules/home/ui/screens/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'core/enums/enums.dart';
import 'core/helpers/app_localizations.dart';
import 'core/routing/app_router.dart';
import 'modules/home/logic/localization/localization_state.dart';
import 'modules/home/logic/theme/theme_cubit.dart';
import 'modules/home/logic/theme/theme_state.dart';

class MyApp extends StatelessWidget {
  final AppRouter appRouter;

  const MyApp({super.key, required this.appRouter});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<ThemeCubit>(
            create: (context) =>
                ThemeCubit()..changeTheme(ThemeModesEnums.initial)),
        BlocProvider<LocalizationCubit>(
            create: (context) => LocalizationCubit()
              ..changeLanguage(LanguagesTypesEnums.initial)),
        BlocProvider<InternetConnectionCubit>(
            create: (context) =>
                InternetConnectionCubit()..checkConnectivity()),
      ],
      child: Builder(
        builder: (context) {
          final themeState = context.watch<ThemeCubit>().state;
          final localizationState = context.watch<LocalizationCubit>().state;
          if (localizationState is ChangeAppLanguage) {
            return ScreenUtilInit(
              designSize: const Size(375, 812),
              minTextAdapt: true,
              child: MaterialApp(
                title: 'AidSense',
                debugShowCheckedModeBanner: false,
                theme: themeState is LightTheme
                    ? ThemeData.light()
                    : ThemeData.dark(),
                locale: Locale(localizationState.languageCode!),
                supportedLocales: const [
                  Locale('en'),
                  Locale('ar'),
                ],
                localizationsDelegates: const [
                  AppLocalizations.delegate,
                  GlobalMaterialLocalizations.delegate,
                  GlobalWidgetsLocalizations.delegate,
                  GlobalCupertinoLocalizations.delegate,
                ],
                localeResolutionCallback: (deviceLocale, supportedLocales) {
                  for (var locale in supportedLocales) {
                    if (deviceLocale != null) {
                      if (deviceLocale.languageCode == locale.languageCode) {
                        return deviceLocale;
                      }
                    }
                  }
                  return supportedLocales.first;
                },
                home: const HomeScreen(),
              ),
            );
          } else {
            return const SizedBox.shrink();
          }
        },
      ),
    );
  }
}
