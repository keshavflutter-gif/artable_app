import 'package:artable_app/core/storage/local_storage.dart';

class StorageService {
  StorageService();

  Future<void> saveString(String key, String value) =>
      LocalStorage.setString(key, value);

  Future<String?> readString(String key) => LocalStorage.getString(key);

  Future<void> remove(String key) => LocalStorage.remove(key);

  Future<void> clearAll() => LocalStorage.clear();
}
