class AppSettings {
  final String aiModel;
  final bool voiceEnabled;
  final bool showGrid;
  final String gridType;
  final bool showScore;
  final bool showArOverlay;
  final int dailyAnalysisCount;
  final String lastResetDate;
  final bool isProUser;
  final bool enableAiLog;

  const AppSettings({
    this.aiModel = 'glm-4v',
    this.voiceEnabled = true,
    this.showGrid = true,
    this.gridType = 'ruleOfThirds',
    this.showScore = true,
    this.showArOverlay = true,
    this.dailyAnalysisCount = 0,
    this.lastResetDate = '',
    this.isProUser = false,
    this.enableAiLog = false,
  });

  AppSettings copyWith({
    String? aiModel,
    bool? voiceEnabled,
    bool? showGrid,
    String? gridType,
    bool? showScore,
    bool? showArOverlay,
    int? dailyAnalysisCount,
    String? lastResetDate,
    bool? isProUser,
    bool? enableAiLog,
  }) {
    return AppSettings(
      aiModel: aiModel ?? this.aiModel,
      voiceEnabled: voiceEnabled ?? this.voiceEnabled,
      showGrid: showGrid ?? this.showGrid,
      gridType: gridType ?? this.gridType,
      showScore: showScore ?? this.showScore,
      showArOverlay: showArOverlay ?? this.showArOverlay,
      dailyAnalysisCount: dailyAnalysisCount ?? this.dailyAnalysisCount,
      lastResetDate: lastResetDate ?? this.lastResetDate,
      isProUser: isProUser ?? this.isProUser,
      enableAiLog: enableAiLog ?? this.enableAiLog,
    );
  }

  Map<String, dynamic> toJson() => {
        'aiModel': aiModel,
        'voiceEnabled': voiceEnabled,
        'showGrid': showGrid,
        'gridType': gridType,
        'showScore': showScore,
        'showArOverlay': showArOverlay,
        'dailyAnalysisCount': dailyAnalysisCount,
        'lastResetDate': lastResetDate,
        'isProUser': isProUser,
        'enableAiLog': enableAiLog,
      };

  factory AppSettings.fromJson(Map<String, dynamic> json) => AppSettings(
        aiModel: json['aiModel'] as String? ?? 'glm-4v',
        voiceEnabled: json['voiceEnabled'] as bool? ?? true,
        showGrid: json['showGrid'] as bool? ?? true,
        gridType: json['gridType'] as String? ?? 'ruleOfThirds',
        showScore: json['showScore'] as bool? ?? true,
        showArOverlay: json['showArOverlay'] as bool? ?? true,
        dailyAnalysisCount: json['dailyAnalysisCount'] as int? ?? 0,
        lastResetDate: json['lastResetDate'] as String? ?? '',
        isProUser: json['isProUser'] as bool? ?? false,
        enableAiLog: json['enableAiLog'] as bool? ?? false,
      );
}
