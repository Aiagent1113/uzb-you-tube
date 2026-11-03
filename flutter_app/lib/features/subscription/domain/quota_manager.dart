import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../core/constants/app_constants.dart';

/// Quota & Subscription Domain Manager
/// Enforces Freemium Limits:
/// - 60 min total daily free limit (15 min Neural HD, 45 min Robot voice)
/// - Midnight automatic reset
/// - Secure storage of PRO status and activation tokens
class QuotaManager extends ChangeNotifier {
  static final QuotaManager _instance = QuotaManager._internal();
  factory QuotaManager() => _instance;
  QuotaManager._internal();

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  bool _isPro = false;
  int _hdConsumedSeconds = 0;
  int _robotConsumedSeconds = 0;
  String? _activeLicenseKey;

  bool get isPro => _isPro;
  String? get activeLicenseKey => _activeLicenseKey;
  int get hdConsumedSeconds => _hdConsumedSeconds;
  int get robotConsumedSeconds => _robotConsumedSeconds;
  int get totalConsumedSeconds => _hdConsumedSeconds + _robotConsumedSeconds;

  int get hdRemainingSeconds => _isPro 
      ? 999999 
      : (AppConstants.neuralHdQuotaSeconds - _hdConsumedSeconds).clamp(0, AppConstants.neuralHdQuotaSeconds);

  int get robotRemainingSeconds => _isPro 
      ? 999999 
      : (AppConstants.standardRobotQuotaSeconds - _robotConsumedSeconds).clamp(0, AppConstants.standardRobotQuotaSeconds);

  int get totalRemainingSeconds => _isPro 
      ? 999999 
      : (AppConstants.totalDailyQuotaSeconds - totalConsumedSeconds).clamp(0, AppConstants.totalDailyQuotaSeconds);

  double get quotaProgressPercentage => _isPro 
      ? 1.0 
      : (totalConsumedSeconds / AppConstants.totalDailyQuotaSeconds).clamp(0.0, 1.0);

  Future<void> initialize() async {
    await _checkAndResetDailyQuotas();
    await _loadSavedLicense();
  }

  /// Verifies current date; resets quotas if day has rolled over
  Future<void> _checkAndResetDailyQuotas() async {
    final now = DateTime.now();
    final todayStr = '${now.year}-${now.month}-${now.day}';
    
    final savedDate = await _secureStorage.read(key: AppConstants.storageKeyQuotaDate);
    if (savedDate != todayStr) {
      // New day: reset usage counters
      _hdConsumedSeconds = 0;
      _robotConsumedSeconds = 0;
      await _secureStorage.write(key: AppConstants.storageKeyQuotaDate, value: todayStr);
      await _secureStorage.write(key: AppConstants.storageKeyHdConsumed, value: '0');
      await _secureStorage.write(key: AppConstants.storageKeyRobotConsumed, value: '0');
    } else {
      // Load current day usage
      final hdStr = await _secureStorage.read(key: AppConstants.storageKeyHdConsumed);
      final robotStr = await _secureStorage.read(key: AppConstants.storageKeyRobotConsumed);
      _hdConsumedSeconds = int.tryParse(hdStr ?? '0') ?? 0;
      _robotConsumedSeconds = int.tryParse(robotStr ?? '0') ?? 0;
    }
    notifyListeners();
  }

  Future<void> _loadSavedLicense() async {
    final key = await _secureStorage.read(key: AppConstants.storageKeyLicense);
    if (key != null && key.isNotEmpty) {
      _activeLicenseKey = key;
      _isPro = true;
      notifyListeners();
    }
  }

  /// Register consumed speech seconds
  Future<bool> consumeQuota({required String voiceType, required int seconds}) async {
    if (_isPro) return true; // Unlimited for PRO

    final isNeural = voiceType.contains('Neural');
    if (isNeural) {
      if (_hdConsumedSeconds + seconds > AppConstants.neuralHdQuotaSeconds) {
        // Exceeded HD limit!
        return false;
      }
      _hdConsumedSeconds += seconds;
      await _secureStorage.write(
        key: AppConstants.storageKeyHdConsumed, 
        value: _hdConsumedSeconds.toString()
      );
    } else {
      if (totalConsumedSeconds + seconds > AppConstants.totalDailyQuotaSeconds) {
        // Exceeded overall daily limit!
        return false;
      }
      _robotConsumedSeconds += seconds;
      await _secureStorage.write(
        key: AppConstants.storageKeyRobotConsumed, 
        value: _robotConsumedSeconds.toString()
      );
    }

    notifyListeners();
    return true;
  }

  /// Check if requested voice is currently usable under remaining quotas
  bool canUseVoice(String voiceType) {
    if (_isPro) return true;
    if (voiceType.contains('Neural')) {
      return hdRemainingSeconds > 10;
    }
    return totalRemainingSeconds > 10;
  }

  /// Activate PRO status using license key purchased via Telegram Bot
  Future<bool> activateProLicense(String key) async {
    final trimmed = key.trim().toUpperCase();
    
    // License format check: e.g., UZDUB-PRO-XXXX-XXXX
    if (!trimmed.startsWith('UZDUB-PRO-') || trimmed.length < 18) {
      return false;
    }

    // In production, verifies with backend API using HMAC signed headers
    // For MVP prototype validation:
    _isPro = true;
    _activeLicenseKey = trimmed;
    await _secureStorage.write(key: AppConstants.storageKeyLicense, value: trimmed);
    notifyListeners();
    return true;
  }
}
