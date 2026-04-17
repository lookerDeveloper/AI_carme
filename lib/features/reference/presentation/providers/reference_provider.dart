import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/template.dart';
import '../../domain/repositories/template_repository.dart';
import '../../data/repositories/template_repository_impl.dart';
import '../../data/datasources/remote_template_data.dart';
import '../../../../core/utils/app_logger.dart';

final templateRepositoryProvider = Provider<TemplateRepository>((ref) {
  AppLogger.logDebug('初始化模板仓库', tag: 'Reference');
  return TemplateRepositoryImpl(RemoteTemplateDataSource());
});

class ReferenceState {
  final Template? selectedTemplate;
  final List<Template> templates;
  final String? selectedCategory;
  final bool isLoading;
  final String? customReferencePath;
  final String? errorMessage;

  const ReferenceState({
    this.selectedTemplate,
    this.templates = const [],
    this.selectedCategory,
    this.isLoading = false,
    this.customReferencePath,
    this.errorMessage,
  });

  ReferenceState copyWith({
    Template? selectedTemplate,
    List<Template>? templates,
    String? selectedCategory,
    bool? isLoading,
    String? customReferencePath,
    String? errorMessage,
    bool clearSelection = false,
    bool clearError = false,
  }) {
    return ReferenceState(
      selectedTemplate: clearSelection ? null : (selectedTemplate ?? this.selectedTemplate),
      templates: templates ?? this.templates,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      isLoading: isLoading ?? this.isLoading,
      customReferencePath: customReferencePath ?? this.customReferencePath,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class ReferenceNotifier extends StateNotifier<ReferenceState> {
  final TemplateRepository _repository;

  ReferenceNotifier(this._repository) : super(const ReferenceState()) {
    _loadTemplates();
  }

  Future<void> _loadTemplates() async {
    try {
      state = state.copyWith(isLoading: true, clearError: true);
      AppLogger.logInfo('开始加载参考模板', tag: 'Reference');
      
      final templates = await _repository.getTemplates(
        category: state.selectedCategory,
      );
      
      state = state.copyWith(
        templates: templates, 
        isLoading: false
      );
      
      AppLogger.logInfo('模板加载完成，共 ${templates.length} 个', tag: 'Reference');
    } catch (e) {
      AppLogger.logError('加载模板失败: $e', tag: 'Reference');
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> selectCategory(String? category) async {
    try {
      state = state.copyWith(selectedCategory: category, isLoading: true);
      AppLogger.logInfo('切换分类: ${category ?? "全部"}', tag: 'Reference');
      
      final templates = await _repository.getTemplates(category: category);
      state = state.copyWith(templates: templates, isLoading: false);
    } catch (e) {
      AppLogger.logError('分类切换失败: $e', tag: 'Reference');
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  void selectTemplate(Template template) {
    state = state.copyWith(selectedTemplate: template);
    AppLogger.logInfo('选择模板: ${template.name}', tag: 'Reference');
  }

  void clearSelection() {
    state = state.copyWith(clearSelection: true);
    AppLogger.logInfo('清除模板选择', tag: 'Reference');
  }

  void setCustomReference(String path) {
    state = state.copyWith(customReferencePath: path);
    AppLogger.logInfo('设置自定义参考图', tag: 'Reference');
  }

  Future<List<Template>> searchTemplates(String query) async {
    try {
      return await _repository.searchTemplates(query);
    } catch (e) {
      AppLogger.logError('搜索失败: $e', tag: 'Reference');
      return [];
    }
  }
  
  Future<void> refresh() async {
    await _loadTemplates();
  }
}

final referenceProvider =
    StateNotifierProvider<ReferenceNotifier, ReferenceState>((ref) {
  final repository = ref.watch(templateRepositoryProvider);
  return ReferenceNotifier(repository);
});
