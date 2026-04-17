class AppConstants {
  AppConstants._();

  static const String appName = '智眸AI相机';
  static const String appNameEn = 'AICam Coach';

  static const double minFrameRate = 30.0;
  static const Duration analysisInterval = Duration(milliseconds: 500);
  static const int maxAnalysisPerSecond = 2;
  static const int imageCompressionSize = 512;
  static const double imageCompressionQuality = 0.7;

  static const double excellentScore = 85.0;
  static const double goodScore = 70.0;
  static const double averageScore = 50.0;

  static const int freeDailyAnalysisLimit = 5;

  static const Duration splashDuration = Duration(seconds: 2);
  static const Duration focusAnimationDuration = Duration(milliseconds: 300);
  static const Duration feedbackDisplayDuration = Duration(seconds: 3);
}
