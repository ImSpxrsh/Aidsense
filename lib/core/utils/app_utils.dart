import 'package:flutter/material.dart';

import '../helpers/app_localizations.dart';

class AppUtils {
    static translate(BuildContext context, String key) {
        return AppLocalizations.of(context).translate(key);
    }
}