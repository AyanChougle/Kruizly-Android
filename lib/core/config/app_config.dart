class AppConfig {
  static const String appName = '''Kruizly''';
  static const String appTagline = '''Premium Self-Drive Car Rentals''';
  static const String apiBaseUrl = String.fromEnvironment(
    '''API_BASE_URL''',
    defaultValue: '''https://kruizly.com/api''',
  );
  static const String mediaBaseUrl = String.fromEnvironment(
    '''MEDIA_BASE_URL''',
    defaultValue: '''https://kruizly.com''',
  );
  static const String defaultUpiId = 'svcmerc00314092@svcbank';
  static const String upiId = defaultUpiId;
  static const String upiName = 'Kruizly';
  static const String supportPhone = '''+91 91671 64547''';
  static const String supportEmail = '''support@kruizly.com''';
  static const String companyAddress =
      '''Gavson Business Park, Ghansoli, Navi Mumbai, Maharashtra 400701''';
}
