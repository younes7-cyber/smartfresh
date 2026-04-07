class AppRoutes {
  static const splash = '/';
  static const login = '/login';
  static const signup = '/signup';
  static const forgotPassword = '/forgot-password';
  static const verifyEmail = '/verify-email';
  static const main = '/main';
  static const dashboard = '/dashboard';
  static const notifications = '/notifications';
  static const scan = '/scan';
  static const zones = '/zones';
  static const settings = '/settings';
  static const barcodeGenerator = '/barcode-generator';
}

class AppDurations {
  static const short = Duration(milliseconds: 300);
  static const medium = Duration(milliseconds: 600);
  static const long = Duration(milliseconds: 1500);
}

class AppPins {
  static const expiredBox = '2580';
}

class AppDimensions {
  static const defaultPadding = 16.0;
  static const cardRadius = 24.0;
  static const chipRadius = 999.0;
}

class AppStrings {
  static const appName = 'SmartFresh';
  static const logoAsset = 'assets/logo.jpg';
}
