/// Application level constants
class AppConstants {
  static const String appName = 'UzDub YouTube AI';
  static const String appVersion = '1.0.0-mvp';

  // YouTube Mobile Target URL
  static const String youtubeMobileUrl = 'https://m.youtube.com';

  // Voice Identifiers
  static const String voiceMadina = 'uz-UZ-MadinaNeural';
  static const String voiceSardor = 'uz-UZ-SardorNeural';
  static const String voiceRobot = 'robot';

  // Freemium Quotas (in seconds)
  static const int totalDailyQuotaSeconds = 3600; // 60 minutes
  static const int neuralHdQuotaSeconds = 900;    // 15 minutes
  static const int standardRobotQuotaSeconds = 2700; // 45 minutes

  // Telegram Integration
  static const String telegramBotUsername = 'UzDubAI_bot';
  static const String telegramBotUrl = 'https://t.me/UzDubAI_bot';

  // Security Storage Keys
  static const String storageKeyLicense = 'uzdub_secure_pro_license';
  static const String storageKeyQuotaDate = 'uzdub_quota_date';
  static const String storageKeyHdConsumed = 'uzdub_quota_hd_consumed';
  static const String storageKeyRobotConsumed = 'uzdub_quota_robot_consumed';
}
