import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class StorageService {
  static const FlutterSecureStorage _storage =
      FlutterSecureStorage();

  static const String tokenKey = "access_token";

  Future<void> saveToken(String token) async {
    print("Saving token: $token");

    await _storage.write(
      key: tokenKey,
      value: token,
    );

    final stored = await _storage.read(key: tokenKey);

    print("Token after save: $stored");
  }

  Future<String?> getToken() async {
    final token = await _storage.read(
      key: tokenKey,
    );

    print("Reading token: $token");

    return token;
  }

  Future<void> logout() async {
    print("Deleting token");

    await _storage.delete(
      key: tokenKey,
    );
  }
}