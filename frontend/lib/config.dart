class AppConfig {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8000',
  );

  static String roastUrl(String mode) => '$baseUrl/roast?mode=$mode';
  static String resultUrl(String id) => '$baseUrl/result/$id';
  static String get statsUrl => '$baseUrl/stats';
  static String get healthUrl => '$baseUrl/health';

  // Mode keys — must match backend MODES dict keys
  static const String modeNormal = 'normal';
  static const String modeSavage = 'savage';
  static const String modeRecruiter = 'recruiter';

  // UI labels for each mode (change these without touching the backend)
  static const Map<String, String> modeLabels = {
    modeNormal: 'Balanced',
    modeSavage: 'Savage',
    modeRecruiter: 'Recruiter',
  };
}
