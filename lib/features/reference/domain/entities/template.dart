class Template {
  final String id;
  final String name;
  final String category;
  final String thumbnailAsset;
  final List<String> tags;
  final Map<String, dynamic> compositionRules;
  final Map<String, dynamic> cameraParams;
  final String? analysisPrompt;
  final String? comparisonPrompt;
  final int usageCount;
  final DateTime createdAt;
  final bool isPlaceholder;
  final bool isCustomUpload;

  const Template({
    required this.id,
    required this.name,
    required this.category,
    required this.thumbnailAsset,
    required this.tags,
    required this.compositionRules,
    required this.cameraParams,
    this.analysisPrompt,
    this.comparisonPrompt,
    required this.usageCount,
    required this.createdAt,
    this.isPlaceholder = false,
    this.isCustomUpload = false,
  });

  Template copyWith({
    String? id,
    String? name,
    String? category,
    String? thumbnailAsset,
    List<String>? tags,
    Map<String, dynamic>? compositionRules,
    Map<String, dynamic>? cameraParams,
    String? analysisPrompt,
    String? comparisonPrompt,
    int? usageCount,
    DateTime? createdAt,
    bool? isPlaceholder,
    bool? isCustomUpload,
  }) {
    return Template(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      thumbnailAsset: thumbnailAsset ?? this.thumbnailAsset,
      tags: tags ?? this.tags,
      compositionRules: compositionRules ?? this.compositionRules,
      cameraParams: cameraParams ?? this.cameraParams,
      analysisPrompt: analysisPrompt ?? this.analysisPrompt,
      comparisonPrompt: comparisonPrompt ?? this.comparisonPrompt,
      usageCount: usageCount ?? this.usageCount,
      createdAt: createdAt ?? this.createdAt,
      isPlaceholder: isPlaceholder ?? this.isPlaceholder,
      isCustomUpload: isCustomUpload ?? this.isCustomUpload,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'category': category,
        'thumbnailAsset': thumbnailAsset,
        'tags': tags,
        'compositionRules': compositionRules,
        'cameraParams': cameraParams,
        'analysis_prompt': analysisPrompt,
        'comparison_prompt': comparisonPrompt,
        'usageCount': usageCount,
        'createdAt': createdAt.toIso8601String(),
        'isPlaceholder': isPlaceholder,
        'isCustomUpload': isCustomUpload,
      };

  factory Template.fromJson(Map<String, dynamic> json) => Template(
        id: json['id'] as String,
        name: json['name'] as String,
        category: json['category'] as String,
        thumbnailAsset: json['thumbnail_url'] as String? ?? json['thumbnailAsset'] as String,
        tags: (json['tags'] as List?)?.map((e) => e as String).toList() ?? [],
        compositionRules: Map<String, dynamic>.from(json['composition_rules'] as Map? ?? json['compositionRules'] as Map? ?? {}),
        cameraParams: Map<String, dynamic>.from(json['camera_params'] as Map? ?? json['cameraParams'] as Map? ?? {}),
        analysisPrompt: json['analysis_prompt'] as String?,
        comparisonPrompt: json['comparison_prompt'] as String?,
        usageCount: json['usage_count'] as int? ?? 0,
        createdAt: DateTime.parse(json['created_at'] as String),
        isPlaceholder: json['isPlaceholder'] ?? false,
        isCustomUpload: json['isCustomUpload'] ?? false,
      );

  bool get hasValidImage => 
      thumbnailAsset.isNotEmpty && !thumbnailAsset.startsWith('assets/') && !isPlaceholder;

  String get displayImageUrl => 
      (hasValidImage && thumbnailAsset.startsWith('/'))
          ? 'http://10.56.193.133:3000$thumbnailAsset'
          : thumbnailAsset;
}

enum TemplateCategory {
  portrait('人像', 'portrait'),
  landscape('风景', 'landscape'),
  food('美食', 'food'),
  pet('宠物', 'pet'),
  street('街拍', 'street'),
  stillLife('静物', 'still_life'),
  custom('自定义', 'custom');

  final String label;
  final String value;

  const TemplateCategory(this.label, this.value);
}
