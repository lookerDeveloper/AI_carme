import '../../domain/entities/template.dart';
import '../../domain/repositories/template_repository.dart';
import '../datasources/remote_template_data.dart';
import '../../../../core/utils/app_logger.dart';

class TemplateRepositoryImpl implements TemplateRepository {
  final RemoteTemplateDataSource _remoteDataSource;

  TemplateRepositoryImpl(this._remoteDataSource);

  @override
  Future<List<Template>> getTemplates({String? category}) async {
    try {
      AppLogger.logInfo('获取模板列表 - 分类: ${category ?? "全部"}', tag: 'TemplateRepo');
      final templates = await _remoteDataSource.getTemplates(category: category);
      return templates;
    } catch (e) {
      AppLogger.logError('获取模板失败: $e', tag: 'TemplateRepo');
      rethrow;
    }
  }

  @override
  Future<Template?> getTemplateById(String id) async {
    try {
      final templates = await _remoteDataSource.getTemplates();
      try {
        return templates.firstWhere((t) => t.id == id);
      } catch (e) {
        return null;
      }
    } catch (e) {
      AppLogger.logError('获取单个模板失败: $id - $e', tag: 'TemplateRepo');
      return null;
    }
  }

  @override
  Future<List<Template>> searchTemplates(String query) async {
    try {
      AppLogger.logInfo('搜索模板: $query', tag: 'TemplateRepo');
      return await _remoteDataSource.searchTemplates(query);
    } catch (e) {
      AppLogger.logError('搜索模板失败: $e', tag: 'TemplateRepo');
      rethrow;
    }
  }

  @override
  Future<void> incrementUsageCount(String id) async {
    AppLogger.logDebug('增加模板使用次数: $id', tag: 'TemplateRepo');
  }
}
