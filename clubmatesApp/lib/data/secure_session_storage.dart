import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Keeps the Supabase session in the iOS Keychain / Android Keystore instead
/// of plain shared preferences, so another app or a device backup can't lift
/// the login and read a member's chats.
class SecureSessionStorage extends LocalStorage {
  SecureSessionStorage(String supabaseUrl)
    : _key = 'sb-${Uri.parse(supabaseUrl).host.split('.').first}-auth-token';

  final String _key;

  static const _installMarker = 'clubmates.session_in_secure_storage';
  static const _storage = FlutterSecureStorage(
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  @override
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final legacy = prefs.getString(_key);
    if (legacy != null) {
      await _storage.write(key: _key, value: legacy);
      await prefs.remove(_key);
    } else if (!prefs.containsKey(_installMarker)) {
      // Keychain entries survive an uninstall; a fresh install starts signed out.
      await _storage.delete(key: _key);
    }
    await prefs.setBool(_installMarker, true);
  }

  @override
  Future<bool> hasAccessToken() => _storage.containsKey(key: _key);

  @override
  Future<String?> accessToken() => _storage.read(key: _key);

  @override
  Future<void> persistSession(String persistSessionString) =>
      _storage.write(key: _key, value: persistSessionString);

  @override
  Future<void> removePersistedSession() => _storage.delete(key: _key);
}
