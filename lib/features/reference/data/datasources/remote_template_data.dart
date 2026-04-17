import 'dart:convert';
import '../../../../core/api/api_service.dart';
import '../../../../core/utils/app_logger.dart';
import '../../domain/entities/template.dart';

class RemoteTemplateDataSource {
  Future<List<Template>> getTemplates({String? category, String? search}) async {
    try {
      AppLogger.logInfo('从服务器获取模板列表', tag: 'Template');
      
      final queryParams = <String, dynamic>{};
      if (category != null && category.isNotEmpty) {
        queryParams['category'] = category;
      }
      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }

      final response = await ApiService.get('/templates', queryParameters: queryParams);

      if (response['success'] == true) {
        final List<dynamic> templatesJson = response['data'];
        final templates = templatesJson.map((json) => _fromJson(json)).toList();
        
        AppLogger.logInfo('成功获取 ${templates.length} 个模板', tag: 'Template');
        
        if (templates.isEmpty) {
          AppLogger.logWarn('模板列表为空，使用默认占位符', tag: 'Template');
          return _getDefaultPlaceholderTemplates();
        }
        
        return templates;
      }

      AppLogger.logError('获取模板失败: ${response['message']}', tag: 'Template');
      return _getDefaultPlaceholderTemplates();
    } catch (e) {
      AppLogger.logError('获取模板异常: $e', tag: 'Template');
      AppLogger.logInfo('网络请求失败，显示默认模板', tag: 'Template');
      return _getDefaultPlaceholderTemplates();
    }
  }

  Future<List<Template>> searchTemplates(String query) async {
    return getTemplates(search: query);
  }

  Template _fromJson(Map<String, dynamic> json) {
    List<String> tags = [];
    if (json['tags'] is String) {
      tags = List<String>.from(jsonDecode(json['tags']));
    } else if (json['tags'] is List) {
      tags = List<String>.from(json['tags']);
    }

    Map<String, dynamic> compositionRules = {};
    if (json['composition_rules'] is String) {
      compositionRules = Map<String, dynamic>.from(jsonDecode(json['composition_rules']));
    } else if (json['composition_rules'] is Map) {
      compositionRules = Map<String, dynamic>.from(json['composition_rules']);
    }

    Map<String, dynamic> cameraParams = {};
    if (json['camera_params'] is String) {
      cameraParams = Map<String, dynamic>.from(jsonDecode(json['camera_params']));
    } else if (json['camera_params'] is Map) {
      cameraParams = Map<String, dynamic>.from(json['camera_params']);
    }

    return Template(
      id: json['id'] ?? '',
      name: json['name'] ?? '未命名模板',
      category: json['category'] ?? 'other',
      thumbnailAsset: json['thumbnail_url'] ?? '',
      tags: tags,
      compositionRules: compositionRules,
      cameraParams: cameraParams,
      usageCount: json['usage_count'] ?? 0,
      createdAt: json['created_at'] != null 
          ? DateTime.tryParse(json['created_at']) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  List<Template> _getDefaultPlaceholderTemplates() {
    AppLogger.logDebug('生成默认占位模板', tag: 'Template');

    return [
      Template(
        id: 'placeholder_portrait',
        name: '📷 人像摄影',
        category: 'portrait',
        thumbnailAsset: '',
        tags: ['人像', '肖像'],
        compositionRules: {'subject_position': 'center'},
        cameraParams: {'focal_length': '50mm'},
        usageCount: 0,
        createdAt: DateTime(2026, 1, 1),
        isPlaceholder: true,
      ),
      Template(
        id: 'placeholder_landscape',
        name: '🏔️ 风景摄影',
        category: 'landscape',
        thumbnailAsset: '',
        tags: ['风景', '自然'],
        compositionRules: {'horizon': 'lower_third'},
        cameraParams: {'focal_length': '24mm'},
        usageCount: 0,
        createdAt: DateTime(2026, 1, 1),
        isPlaceholder: true,
      ),
      Template(
        id: 'placeholder_food',
        name: '🍽️ 美食摄影',
        category: 'food',
        thumbnailAsset: '',
        tags: ['美食', '食物'],
        compositionRules: {'angle': '45_degree'},
        cameraParams: {'focal_length': '50mm'},
        usageCount: 0,
        createdAt: DateTime(2026, 1, 1),
        isPlaceholder: true,
      ),
      Template(
        id: 'placeholder_pet',
        name: '🐾 宠物摄影',
        category: 'pet',
        thumbnailAsset: '',
        tags: ['宠物', '动物'],
        compositionRules: {'focus': 'eyes'},
        cameraParams: {'focal_length': '85mm'},
        usageCount: 0,
        createdAt: DateTime(2026, 1, 1),
        isPlaceholder: true,
      ),
      Template(
        id: 'placeholder_street',
        name: '🚶 街拍摄影',
        category: 'street',
        thumbnailAsset: '',
        tags: ['街拍', '纪实'],
        compositionRules: {'composition': 'leading_lines'},
        cameraParams: {'focal_length': '35mm'},
        usageCount: 0,
        createdAt: DateTime(2026, 1, 1),
        isPlaceholder: true,
      ),
      Template(
        id: 'placeholder_custom',
        name: '✨ 自定义上传',
        category: 'custom',
        thumbnailAsset: '',
        tags: ['自定义', '个人'],
        compositionRules: {},
        cameraParams: {},
        usageCount: 0,
        createdAt: DateTime(2026, 1, 1),
        isPlaceholder: true,
        isCustomUpload: true,
      ),
    ];
  }
}
