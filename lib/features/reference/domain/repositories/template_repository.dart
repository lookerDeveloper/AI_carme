import '../../domain/entities/template.dart';

abstract class TemplateRepository {
  Future<List<Template>> getTemplates({String? category});
  Future<Template?> getTemplateById(String id);
  Future<List<Template>> searchTemplates(String query);
  Future<void> incrementUsageCount(String id);
}
