class AppConfig {
  static final Uri apiBaseUrl = Uri.parse('http://81.71.137.84:8080/api');
  static final Uri webBaseUrl = Uri.parse('http://81.71.137.84:8080/');
  static const String jpushAppKey = String.fromEnvironment('JPUSH_APP_KEY');
  static const String jpushChannel = String.fromEnvironment(
    'JPUSH_CHANNEL',
    defaultValue: 'developer-default',
  );
  static const bool jpushProduction = bool.fromEnvironment('JPUSH_PRODUCTION');
}
