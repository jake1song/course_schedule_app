import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AiKeyStore {
  AiKeyStore({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;
  static const _keyKey = 'aiApiKey';
  static const _urlKey = 'aiApiUrl';
  static const _modelKey = 'aiModel';

  Future<String> readKey() async {
    return await _storage.read(key: _keyKey) ?? '';
  }

  Future<void> saveKey(String key) async {
    await _storage.write(key: _keyKey, value: key);
  }

  Future<String> readUrl() async {
    return await _storage.read(key: _urlKey) ?? 'https://api.deepseek.com';
  }

  Future<String> readModel() async {
    return await _storage.read(key: _modelKey) ?? 'deepseek-chat';
  }

  Future<void> saveModel(String model) async {
    await _storage.write(key: _modelKey, value: model);
  }

  Future<void> clear() async {
    await _storage.delete(key: _keyKey);
  }
}
