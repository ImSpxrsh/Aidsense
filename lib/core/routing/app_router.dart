import 'package:blank_project/modules/onboarding/screens/onboarding_screen.dart';
import 'package:flutter/material.dart';

import '../../modules/home/ui/screens/home_screen.dart';
import 'routes.dart';

class AppRouter {
  Route generateRoute(RouteSettings settings) {
    // MARK: - This arguments variable is used to pass data between routes.
    // final arguments = settings.arguments;

    // MARK: - This switch statement is used to navigate between routes.
    switch (settings.name) {
      case Routes.onboardingScreen:
        return MaterialPageRoute(builder: (_) => const OnboardingScreen());
      // case Routes.loginScreen:
      //   return MaterialPageRoute(
      //     builder: (_) => MultiBlocProvider(
      //       providers: [
      //         BlocProvider<LoginCubit>(
      //           create: (BuildContext context) => getIt<LoginCubit>(),
      //         ),
      //         BlocProvider<ToggleRememberMeCubit>(
      //           create: (BuildContext context) => getIt<ToggleRememberMeCubit>(),
      //         ),
      //         BlocProvider<ToggleObscureTextCubit>(
      //           create: (BuildContext context) => getIt<ToggleObscureTextCubit>(),
      //         ),
      //       ],
      //       child: const LoginScreen(),
      //     ),
      //   );
      case Routes.homeScreen:
        return MaterialPageRoute(
          builder: (_) => const HomeScreen(),
          // builder: (_) => BlocProvider(
          //   create: (BuildContext context) =>
          //       ThemeCubit()..changeTheme(ThemeStatesEnums.initial),
          //   child: BlocBuilder<ThemeCubit, ThemeState>(
          //     builder: (context, state) {
          //       return const HomeScreen();
          //     },
          //   ),
          // ),
        );
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('No route defined for ${settings.name}'),
            ),
          ),
        );
    }
  }
}
