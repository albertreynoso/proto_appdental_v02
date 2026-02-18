import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class PinService {
  static const _keyPin = 'pin_hash';
  static const _keyEmail = 'remembered_email';
  static const _keyUid = 'remembered_uid';
  static const _keyPassword = 'remembered_password';

  final _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  Future<bool> hasPinConfigured() async =>
      (await _storage.read(key: _keyPin)) != null;

  Future<String?> getRememberedEmail() => _storage.read(key: _keyEmail);

  Future<void> savePin(String pin) async {
    final hash = sha256.convert(utf8.encode(pin)).toString();
    await _storage.write(key: _keyPin, value: hash);
  }

  Future<bool> verifyPin(String pin) async {
    final stored = await _storage.read(key: _keyPin);
    if (stored == null) return false;
    final hash = sha256.convert(utf8.encode(pin)).toString();
    return hash == stored;
  }

  Future<void> saveEmail(String email) =>
      _storage.write(key: _keyEmail, value: email);

  Future<void> saveUid(String uid) =>
      _storage.write(key: _keyUid, value: uid);

  Future<String?> getRememberedUid() => _storage.read(key: _keyUid);

  Future<void> savePassword(String password) =>
      _storage.write(key: _keyPassword, value: password);

  Future<String?> getRememberedPassword() =>
      _storage.read(key: _keyPassword);

  Future<void> clearPin() => _storage.delete(key: _keyPin);

  Future<void> clearAll() => _storage.deleteAll();
}
