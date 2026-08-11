import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static const String _inAppNotificationsKey =
      'settings.in_app_notifications';
  static const String _visitorNotificationsKey =
      'settings.visitor_notifications';
  static const String _deliveryNotificationsKey =
      'settings.delivery_notifications';
  static const String _maintenanceNotificationsKey =
      'settings.maintenance_notifications';
  static const String _securityNotificationsKey =
      'settings.security_notifications';

  static const bool defaultInAppNotifications = true;
  static const bool defaultVisitorNotifications = true;
  static const bool defaultDeliveryNotifications = true;
  static const bool defaultMaintenanceNotifications = true;
  static const bool defaultSecurityNotifications = true;

  Future<SharedPreferences> _prefs() =>
      SharedPreferences.getInstance();

  Future<bool> getInAppNotifications() async {
    final prefs = await _prefs();
    return prefs.getBool(_inAppNotificationsKey) ??
        defaultInAppNotifications;
  }

  Future<bool> getVisitorNotifications() async {
    final prefs = await _prefs();
    return prefs.getBool(_visitorNotificationsKey) ??
        defaultVisitorNotifications;
  }

  Future<bool> getDeliveryNotifications() async {
    final prefs = await _prefs();
    return prefs.getBool(_deliveryNotificationsKey) ??
        defaultDeliveryNotifications;
  }

  Future<bool> getMaintenanceNotifications() async {
    final prefs = await _prefs();
    return prefs.getBool(_maintenanceNotificationsKey) ??
        defaultMaintenanceNotifications;
  }

  Future<bool> getSecurityNotifications() async {
    final prefs = await _prefs();
    return prefs.getBool(_securityNotificationsKey) ??
        defaultSecurityNotifications;
  }

  Future<void> setInAppNotifications(bool value) async {
    final prefs = await _prefs();
    await prefs.setBool(_inAppNotificationsKey, value);
  }

  Future<void> setVisitorNotifications(bool value) async {
    final prefs = await _prefs();
    await prefs.setBool(_visitorNotificationsKey, value);
  }

  Future<void> setDeliveryNotifications(bool value) async {
    final prefs = await _prefs();
    await prefs.setBool(_deliveryNotificationsKey, value);
  }

  Future<void> setMaintenanceNotifications(bool value) async {
    final prefs = await _prefs();
    await prefs.setBool(_maintenanceNotificationsKey, value);
  }

  Future<void> setSecurityNotifications(bool value) async {
    final prefs = await _prefs();
    await prefs.setBool(_securityNotificationsKey, value);
  }

  Future<void> resetNotificationSettings() async {
    final prefs = await _prefs();
    await prefs.setBool(
      _inAppNotificationsKey,
      defaultInAppNotifications,
    );
    await prefs.setBool(
      _visitorNotificationsKey,
      defaultVisitorNotifications,
    );
    await prefs.setBool(
      _deliveryNotificationsKey,
      defaultDeliveryNotifications,
    );
    await prefs.setBool(
      _maintenanceNotificationsKey,
      defaultMaintenanceNotifications,
    );
    await prefs.setBool(
      _securityNotificationsKey,
      defaultSecurityNotifications,
    );
  }
}
