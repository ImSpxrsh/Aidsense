import 'package:blank_project/core/constants/app_strings.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/enums/enums.dart';
import '../../../../core/helpers/shared_preferences_helper.dart';
import 'theme_state.dart';


class ThemeCubit extends Cubit<ThemeState> {
  ThemeCubit() : super(ThemeInitial());

  void changeTheme(ThemeModesEnums mode) {
    switch (mode) {
      case ThemeModesEnums.initial:
        if (SharedPreferencesHelper.getData(AppStrings.changeTheme) != null) {
          if (SharedPreferencesHelper.getData(AppStrings.changeTheme) == "light") {
            emit(LightTheme());
          } else {
            emit(DarkTheme());
          }
        } else {
          emit(ThemeInitial());
        }
        emit(ThemeInitial());
        break;
      case ThemeModesEnums.light:
        SharedPreferencesHelper.setData(AppStrings.changeTheme, "light");
        emit(LightTheme());
        break;
      case ThemeModesEnums.dark:
        SharedPreferencesHelper.setData(AppStrings.changeTheme, "dark");
        emit(DarkTheme());
        break;
    }
  }
}
