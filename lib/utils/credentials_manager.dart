import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class CredentialsManager {
  static final CredentialsManager _instance = CredentialsManager._internal();
  final _storage = const FlutterSecureStorage();

  factory CredentialsManager() {
    return _instance;
  }

  CredentialsManager._internal();

  Future<String?> getUsername() async {
    return await _storage.read(key: 'username');
  }

  Future<String?> getPassword() async {
    return await _storage.read(key: 'password');
  }

  Future<void> setCredentials(String username, String password) async {
    await _storage.write(key: 'username', value: username);
    await _storage.write(key: 'password', value: password);
  }

  Future<bool> hasCredentials() async {
    final username = await getUsername();
    final password = await getPassword();
    return username != null && password != null;
  }
}
