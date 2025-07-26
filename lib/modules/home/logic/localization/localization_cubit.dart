import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/enums/enums.dart';
import '../../../../core/helpers/shared_preferences_helper.dart';
import 'localization_state.dart';

class LocalizationCubit extends Cubit<LocalizationState> {
  LocalizationCubit() : super(LocalizationInitial());

  changeLanguage(LanguagesTypesEnums language) {
    switch (language) {
      case LanguagesTypesEnums.initial:
        if (SharedPreferencesHelper.getData(AppStrings.language) != null) {
          if (SharedPreferencesHelper.getData(AppStrings.language) == 'ar') {
            emit(ChangeAppLanguage(languageCode: 'ar'));
          } else {
            emit(ChangeAppLanguage(languageCode: 'en'));
          }
        }
        break;
      case LanguagesTypesEnums.arabic:
        SharedPreferencesHelper.setData(AppStrings.language, 'ar');
        emit(ChangeAppLanguage(languageCode: 'ar'));
        break;
      case LanguagesTypesEnums.english:
        SharedPreferencesHelper.setData(AppStrings.language, 'en');
        emit(ChangeAppLanguage(languageCode: 'en'));
        break;
      default:
        emit(ChangeAppLanguage(languageCode: 'en'));
    }
  }
}