import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';

class LocalStorage {
  static const _settingsBox = 'app_settings';
  static const _cacheBox = 'analysis_cache';
  static const _recordsBox = 'photo_records';

  static Future<void> initialize() async {
    final directory = await getApplicationDocumentsDirectory();
    Hive.init(directory.path);
    await Hive.openBox(_settingsBox);
    await Hive.openBox(_cacheBox);
    await Hive.openBox(_recordsBox);
  }

  static Box getSettingsBox() => Hive.box(_settingsBox);
  static Box getCacheBox() => Hive.box(_cacheBox);
  static Box getRecordsBox() => Hive.box(_recordsBox);

  static Future<void> cacheAnalysisResult(String key, Map<String, dynamic> data) async {
    final box = getCacheBox();
    await box.put(key, data);
  }

  static Map<String, dynamic>? getCachedAnalysis(String key) {
    final box = getCacheBox();
    final data = box.get(key);
    if (data == null) return null;
    return Map<String, dynamic>.from(data as Map);
  }

  static Future<void> clearCache() async {
    await getCacheBox().clear();
  }
}
