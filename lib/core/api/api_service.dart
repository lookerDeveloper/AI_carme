import 'dart:convert';
import 'package:dio/dio.dart';
import '../../../core/utils/app_logger.dart';

class ApiService {
  static const String baseUrl = 'http://10.56.193.133:3000/api';
  static final Dio _dio = Dio(BaseOptions(
    baseUrl: baseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 15),
    headers: {'Content-Type': 'application/json'},
  ));

  static String? _token;

  static void setToken(String? token) {
    _token = token;
    if (token != null) {
      _dio.options.headers['Authorization'] = 'Bearer $token';
      AppLogger.logInfo('Token已设置', tag: 'ApiService');
    } else {
      _dio.options.headers.remove('Authorization');
      AppLogger.logInfo('Token已清除', tag: 'ApiService');
    }
  }

  static String? get token => _token;

  static Future<Map<String, dynamic>> get(
    String endpoint, {
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      AppLogger.logDebug('GET请求: $endpoint', tag: 'ApiService');
      
      final response = await _dio.get(
        endpoint,
        queryParameters: queryParameters,
      );

      AppLogger.logDebug('GET响应: ${endpoint} - ${response.statusCode}', tag: 'ApiService');

      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      }
      throw Exception('HTTP ${response.statusCode}');
    } on DioException catch (e) {
      AppLogger.logError('GET请求失败: $endpoint - ${e.message}', tag: 'ApiService');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> post(
    String endpoint, {
    dynamic data,
    FormData? formData,
  }) async {
    try {
      AppLogger.logDebug('POST请求: $endpoint', tag: 'ApiService');

      final response = await formData != null
          ? await _dio.post(endpoint, data: formData)
          : await _dio.post(endpoint, data: data);

      AppLogger.logDebug('POST响应: ${endpoint} - ${response.statusCode}', tag: 'ApiService');

      if (response.statusCode == 200 || response.statusCode == 201) {
        return response.data as Map<String, dynamic>;
      }
      throw Exception('HTTP ${response.statusCode}');
    } on DioException catch (e) {
      AppLogger.logError('POST请求失败: $endpoint - ${e.message}', tag: 'ApiService');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> put(
    String endpoint, {
    dynamic data,
    FormData? formData,
  }) async {
    try {
      AppLogger.logDebug('PUT请求: $endpoint', tag: 'ApiService');

      final response = await formData != null
          ? await _dio.put(endpoint, data: formData)
          : await _dio.put(endpoint, data: data);

      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      AppLogger.logError('PUT请求失败: $endpoint - ${e.message}', tag: 'ApiService');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> delete(String endpoint) async {
    try {
      AppLogger.logDebug('DELETE请求: $endpoint', tag: 'ApiService');

      final response = await _dio.delete(endpoint);

      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      AppLogger.logError('DELETE请求失败: $endpoint - ${e.message}', tag: 'ApiService');
      rethrow;
    }
  }

  static Future<FormData> createFormData({
    required String filePath,
    required String fieldName,
    Map<String, dynamic>? fields,
  }) async {
    final multipartFile = await MultipartFile.fromFile(filePath);
    
    final map = <String, dynamic>{fieldName: multipartFile};
    if (fields != null) {
      map.addAll(fields);
    }

    return FormData.fromMap(map);
  }
}
