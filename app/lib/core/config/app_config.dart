class AppConfig {
  static const String appName = 'Neviim';
  static const String parishName = 'Paróquia São José do Operário';
  static const String developerCredit = 'Felipe Blois Desenvolvedor';
  static const String instagramLabel = 'Instagram @projetoneviim';
  static const String instagramUrl =
      'https://www.instagram.com/projetoneviim?utm_source=ig_web_button_share_sheet&igsh=ZDNlZDc0MzIxNw==';
  static const String appVersion = '0.1.0';
  static const String currentTermsVersion = '1.0.0';
  static const bool bypassConsent = bool.fromEnvironment(
    'NEVIIM_BYPASS_CONSENT',
    defaultValue: false,
  );
  static const bool enableRemoteConsent = bool.fromEnvironment(
    'NEVIIM_ENABLE_REMOTE_CONSENT',
    defaultValue: false,
  );
  static const bool enablePushEnrollment = bool.fromEnvironment(
    'NEVIIM_ENABLE_PUSH_ENROLLMENT',
    defaultValue: false,
  );
  static const int galleryPageSize = int.fromEnvironment(
    'NEVIIM_GALLERY_PAGE_SIZE',
    defaultValue: 20,
  );

  static const String dpoEmail = instagramUrl;
  static const String dpoName = parishName;

  static const String backendBaseUrl = String.fromEnvironment(
    'NEVIIM_BACKEND_BASE_URL',
    defaultValue: 'http://localhost:8000',
  );

  static const String firebaseAppCheckSiteKey = String.fromEnvironment(
    'NEVIIM_FIREBASE_APP_CHECK_SITE_KEY',
  );

  static const String firebaseApiKey = String.fromEnvironment(
    'NEVIIM_FIREBASE_API_KEY',
  );
  static const String firebaseAppId = String.fromEnvironment(
    'NEVIIM_FIREBASE_APP_ID',
  );
  static const String firebaseMessagingSenderId = String.fromEnvironment(
    'NEVIIM_FIREBASE_MESSAGING_SENDER_ID',
  );
  static const String firebaseProjectId = String.fromEnvironment(
    'NEVIIM_FIREBASE_PROJECT_ID',
  );
  static const String firebaseAuthDomain = String.fromEnvironment(
    'NEVIIM_FIREBASE_AUTH_DOMAIN',
  );
  static const String firebaseStorageBucket = String.fromEnvironment(
    'NEVIIM_FIREBASE_STORAGE_BUCKET',
  );
  static const String firebaseMeasurementId = String.fromEnvironment(
    'NEVIIM_FIREBASE_MEASUREMENT_ID',
  );
  static const String firebaseIosBundleId = String.fromEnvironment(
    'NEVIIM_FIREBASE_IOS_BUNDLE_ID',
  );

  static bool get hasFirebaseConfig {
    return firebaseApiKey.isNotEmpty &&
        firebaseAppId.isNotEmpty &&
        firebaseMessagingSenderId.isNotEmpty &&
        firebaseProjectId.isNotEmpty;
  }
}
