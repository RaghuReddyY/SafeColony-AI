import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class StorageService {
  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  static const String tokenKey = 'access_token';
  static const String rememberedEmailKey = 'remembered_email';
  static const String rememberedPasswordKey = 'remembered_password';

  Future<void> saveToken(String token) async {
    await _storage.write(key: tokenKey, value: token);
  }

  Future<String?> getToken() async {
    return _storage.read(key: tokenKey);
  }

  /// Stores credentials only when the user explicitly enables Remember me.
  /// flutter_secure_storage is used so the values are protected by the
  /// platform secure storage instead of SharedPreferences/plain text.
  Future<void> saveRememberedCredentials({
    required String email,
    required String password,
  }) async {
    await _storage.write(
      key: rememberedEmailKey,
      value: email.trim().toLowerCase(),
    );
    await _storage.write(
      key: rememberedPasswordKey,
      value: password,
    );
  }

  Future<String?> getRememberedEmail() async {
    return _storage.read(key: rememberedEmailKey);
  }

  Future<String?> getRememberedPassword() async {
    return _storage.read(key: rememberedPasswordKey);
  }

  Future<bool> hasRememberedCredentials() async {
    final email = await getRememberedEmail();
    final password = await getRememberedPassword();
    return email != null && email.isNotEmpty && password != null && password.isNotEmpty;
  }

  Future<void> clearRememberedCredentials() async {
    await _storage.delete(key: rememberedEmailKey);
    await _storage.delete(key: rememberedPasswordKey);
  }

  Future<void> clearToken() async {
    await _storage.delete(key: tokenKey);
  }

  /// Explicit logout clears both the session and remembered credentials.
  /// This prevents a manually logged-out account from being silently restored.
  Future<void> logout() async {
    await clearToken();
    await clearRememberedCredentials();
  }
}
