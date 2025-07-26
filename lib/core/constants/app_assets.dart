class AssetsPaths {
  static const String assets = 'assets';
  static const String svgs = '$assets/svgs';
  static const String images = '$assets/images';
  static const String icons = '$assets/icons';
  static const String lotties = '$assets/lotties';
}

class AppImages {
  // MARK: - 🎁 Splash.
  static const String splashBackground =
      '${AssetsPaths.images}/splash_background.png';
  // MARK: - 🌗 Change Theme.
  static const String lightMode =
      "https://cdn-icons-png.flaticon.com/512/1340/1340337.png";
  static const String darkMode =
      "https://ps.w.org/dark-mode-for-wp-dashboard/assets/icon-256x256.png?rev=2404672";
}

class AppIcons {}

class AppLotties {
  // MARK: - 🏠 Home.
  static const String localization = '${AssetsPaths.lotties}/localization.json';
}

class AppSvgs {
  // MARK: - 🎉 Onboarding.
  static const String onboarding1 = '${AssetsPaths.svgs}/onboarding1.svg';
  static const String onboarding2 = '${AssetsPaths.svgs}/onboarding2.svg';
  static const String onboarding3 = '${AssetsPaths.svgs}/onboarding3.svg';
}
