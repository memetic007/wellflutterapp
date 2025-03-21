import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CredentialsManager {
  static final CredentialsManager _instance = CredentialsManager._internal();
  final _storage = const FlutterSecureStorage();
  SharedPreferences? _webPrefs;

  factory CredentialsManager() {
    return _instance;
  }

  CredentialsManager._internal();

  Future<void> _initWebPrefs() async {
    if (kIsWeb && _webPrefs == null) {
      _webPrefs = await SharedPreferences.getInstance();
    }
  }

  Future<String?> getUsername() async {
    if (kIsWeb) {
      await _initWebPrefs();
      return _webPrefs?.getString('username');
    }
    return await _storage.read(key: 'username');
  }

  Future<String?> getPassword() async {
    if (kIsWeb) {
      await _initWebPrefs();
      return _webPrefs?.getString('password');
    }
    return await _storage.read(key: 'password');
  }

  Future<void> setCredentials(String username, String password) async {
    if (kIsWeb) {
      await _initWebPrefs();
      await _webPrefs?.setString('username', username);
      await _webPrefs?.setString('password', password);
    } else {
      await _storage.write(key: 'username', value: username);
      await _storage.write(key: 'password', value: password);
    }
  }

  Future<bool> hasCredentials() async {
    final username = await getUsername();
    final password = await getPassword();
    return username != null && password != null;
  }

  Future<void> clearCredentials() async {
    if (kIsWeb) {
      await _initWebPrefs();
      await _webPrefs?.remove('username');
      await _webPrefs?.remove('password');
    } else {
      await _storage.delete(key: 'username');
      await _storage.delete(key: 'password');
    }
  }
}
