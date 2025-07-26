import 'package:blank_project/core/helpers/spaces.dart';
import 'package:blank_project/core/utils/app_utils.dart';
import 'package:blank_project/modules/home/logic/internet_connection/internet_connection_cubit.dart';
import 'package:blank_project/modules/home/logic/internet_connection/internet_connection_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/widgets/change_theme_switch.dart';
import '../../../../core/widgets/localization_button.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocListener<InternetConnectionCubit, InternetConnectionState>(
      listener: (context, state) {
        if (state is InternetConnectedState) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.wifi_rounded, color: Colors.white, size: 24.w),
                  horizontalSpace(10.w),
                  Text(state.internetState, style: const TextStyle(color: Colors.white)),
                ],
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 4),
              margin: const EdgeInsets.all(20),
              behavior: SnackBarBehavior.floating,
              elevation: 10.0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              action: SnackBarAction(
                label: 'Dismiss',
                textColor: Colors.blue[200],
                onPressed: () {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                },
              ),
            ),
          );
        } else if (state is InternetNotConnectedState) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.wifi_off_rounded, color: Colors.white, size: 24.w),
                  horizontalSpace(10.w),
                  Text(state.internetState, style: const TextStyle(color: Colors.white)),
                ],
              ),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 4),
              margin: const EdgeInsets.all(14),
              behavior: SnackBarBehavior.floating,
              elevation: 10.0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              action: SnackBarAction(
                label: 'Dismiss',
                textColor: Colors.blue[200],
                onPressed: () {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                },
              ),
            ),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(AppUtils.translate(context, 'homeScreen')),
          actions: const [
            ChangeThemeSwitch(),
            LocalizationButton(),
          ],
        ),
        body: Center(
          child: BlocBuilder<InternetConnectionCubit, InternetConnectionState>(
            builder: (context, state) {
              return Text(
                state is InternetConnectedState
                    ? state.internetState
                    : state is InternetNotConnectedState
                        ? state.internetState
                        : 'No Internet Check!',
              );
            },
          ),
        ),
      ),
    );
  }
}
