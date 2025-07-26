import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../modules/home/logic/theme/theme_cubit.dart';
import '../../modules/home/logic/theme/theme_state.dart';
import '../constants/app_assets.dart';
import '../enums/enums.dart';

class ChangeThemeSwitch extends StatelessWidget {
  const ChangeThemeSwitch({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeCubit, ThemeState>(
      builder: (context, state) {
        return Transform.scale(
          scale: 0.95,
          child: Switch(
            value: state is DarkTheme ? true : false,
            activeTrackColor: Colors.yellow[100],
            activeThumbImage: const NetworkImage(AppImages.lightMode),
            inactiveTrackColor: Colors.black54,
            inactiveThumbImage: const NetworkImage(AppImages.darkMode),
            onChanged: (value) {
              debugPrint("ChangeThemeSwitch: ${state.runtimeType}");
              if (state is DarkTheme) {
                BlocProvider.of<ThemeCubit>(context)
                    .changeTheme(ThemeModesEnums.light);
              } else {
                BlocProvider.of<ThemeCubit>(context)
                    .changeTheme(ThemeModesEnums.dark);
              }
            },
          ),
        );
      },
    );
  }
}
