import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lottie/lottie.dart';

import '../../modules/home/logic/localization/localization_cubit.dart';
import '../../modules/home/logic/localization/localization_state.dart';
import '../constants/app_assets.dart';
import '../constants/app_strings.dart';
import '../enums/enums.dart';
import '../helpers/shared_preferences_helper.dart';

class LocalizationButton extends StatelessWidget {
  const LocalizationButton({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LocalizationCubit, LocalizationState>(
      builder: (context, state) {
        return IconButton(
          onPressed: () {
            if (state is ChangeAppLanguage) {
              if (state.languageCode == 'ar') {
                SharedPreferencesHelper.setData(
                    AppStrings.language, 'en');
                BlocProvider.of<LocalizationCubit>(context)
                    .changeLanguage(LanguagesTypesEnums.english);
              } else {
                SharedPreferencesHelper.setData(
                    AppStrings.language, 'ar');
                BlocProvider.of<LocalizationCubit>(context)
                    .changeLanguage(LanguagesTypesEnums.arabic);
              }
            }
          },
          icon: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(32.r),
              color: Colors.grey,
            ),
            child: Lottie.asset(AppLotties.localization),
          ),
        );
      },
    );
  }
}
