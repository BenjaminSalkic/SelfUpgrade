import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStorage {
  static const _accessTokenKey = 'access_token';
  static const _idTokenKey = 'id_token';

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<void> saveAccessToken(String token) async {
    await _storage.write(key: _accessTokenKey, value: token);
  }

  Future<void> saveIdToken(String token) async {
    await _storage.write(key: _idTokenKey, value: token);
  }

  Future<String?> getAccessToken() async => await _storage.read(key: _accessTokenKey);
  Future<String?> getIdToken() async => await _storage.read(key: _idTokenKey);

  Future<void> clear() async {
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _idTokenKey);
  }
}
