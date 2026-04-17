import 'dart:developer' as developer;
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

enum LogLevel { debug, info, warn, error }

class AppLogger {
  static const String _tag = 'AICamCoach';
  static bool _isInitialized = false;
  static late Directory _logDir;
  static LogLevel _minLevel = LogLevel.debug;
  static List<String> _logBuffer = [];
  static const int _maxBufferSize = 500;

  static Future<void> initialize({LogLevel minLevel = LogLevel.debug}) async {
    if (_isInitialized) return;
    _minLevel = minLevel;
    try {
      final appDir = await getApplicationDocumentsDirectory();
      _logDir = Directory('${appDir.path}/logs');
      if (!await _logDir.exists()) {
        await _logDir.create(recursive: true);
      }
      _isInitialized = true;
      logInfo('日志系统初始化完成', tag: 'System');
    } catch (e) {
      developer.log('日志目录创建失败: $e', name: _tag, error: e);
    }
  }

  static void logDebug(String message, {String? tag, Object? error, StackTrace? stackTrace}) {
    _log(LogLevel.debug, message, tag: tag, error: error, stackTrace: stackTrace);
  }

  static void logInfo(String message, {String? tag, Object? error, StackTrace? stackTrace}) {
    _log(LogLevel.info, message, tag: tag, error: error, stackTrace: stackTrace);
  }

  static void logWarn(String message, {String? tag, Object? error, StackTrace? stackTrace}) {
    _log(LogLevel.warn, message, tag: tag, error: error, stackTrace: stackTrace);
  }

  static void logError(String message, {String? tag, Object? error, StackTrace? stackTrace}) {
    _log(LogLevel.error, message, tag: tag, error: error, stackTrace: stackTrace);
  }

  static void _log(LogLevel level, String message, {String? tag, Object? error, StackTrace? stackTrace}) {
    if (level.index < _minLevel.index) return;

    final timestamp = DateTime.now().toString().substring(0, 19);
    final levelStr = level.name.toUpperCase();
    final tagStr = tag ?? 'General';
    final logLine = '[$timestamp] [$levelStr] [$tagStr] $message';

    if (kDebugMode) {
      final color = _getColorForLevel(level);
      debugPrint('$color$logLine\x1B[0m');
    }

    _logBuffer.add(logLine);
    if (_logBuffer.length > _maxBufferSize) {
      _logBuffer.removeAt(0);
    }

    developer.log(message, name: '$_tag/$tagStr', error: error, stackTrace: stackTrace, level: _getDeveloperLevel(level));

    if (_isInitialized && level == LogLevel.error) {
      _writeToFile(logLine);
    }
  }

  static String _getColorForLevel(LogLevel level) {
    switch (level) {
      case LogLevel.debug:
        return '\x1B[36m';
      case LogLevel.info:
        return '\x1B[32m';
      case LogLevel.warn:
        return '\x1B[33m';
      case LogLevel.error:
        return '\x1B[31m';
    }
  }

  static int _getDeveloperLevel(LogLevel level) {
    switch (level) {
      case LogLevel.debug:
        return 500;
      case LogLevel.info:
        return 800;
      case LogLevel.warn:
        return 900;
      case LogLevel.error:
        return 1000;
    }
  }

  static Future<void> _writeToFile(String logLine) async {
    try {
      final dateStr = DateTime.now().toString().substring(0, 10);
      final file = File('${_logDir.path}/$dateStr.log');
      await file.writeAsString('$logLine\n', mode: FileMode.append);
    } catch (e) {
      developer.log('写入日志文件失败: $e', name: _tag, error: e);
    }
  }

  static List<String> getRecentLogs({int count = 100}) {
    final start = (_logBuffer.length - count).clamp(0, _logBuffer.length);
    return _logBuffer.sublist(start);
  }

  static Future<List<String>> readLogFile(DateTime date) async {
    if (!_isInitialized) return [];
    try {
      final dateStr = date.toString().substring(0, 10);
      final file = File('${_logDir.path}/$dateStr.log');
      if (await file.exists()) {
        final content = await file.readAsString();
        return content.split('\n').where((line) => line.isNotEmpty).toList();
      }
    } catch (e) {
      AppLogger.logError('读取日志文件失败', tag: 'Logger', error: e);
    }
    return [];
  }

  static Future<void> clearLogFiles() async {
    if (!_isInitialized) return;
    try {
      if (await _logDir.exists()) {
        await for (final entity in _logDir.list()) {
          if (entity is File) {
            await entity.delete();
          }
        }
      }
      _logBuffer.clear();
      logInfo('日志文件已清理', tag: 'Logger');
    } catch (e) {
      logError('清理日志失败', tag: 'Logger', error: e);
    }
  }
}
