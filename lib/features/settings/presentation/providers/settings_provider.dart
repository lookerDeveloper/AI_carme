import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../../domain/entities/app_settings.dart';
import '../../../../core/ai/ai_model.dart';

class SettingsState {
  final AppSettings settings;
  final bool isLoading;

  const SettingsState({
    this.settings = const AppSettings(),
    this.isLoading = false,
  });

  SettingsState copyWith({
    AppSettings? settings,
    bool? isLoading,
  }) {
    return SettingsState(
      settings: settings ?? this.settings,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class SettingsNotifier extends StateNotifier<SettingsState> {
  static const _boxName = 'app_settings';
  static const _settingsKey = 'settings';

  SettingsNotifier() : super(const SettingsState()) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    state = state.copyWith(isLoading: true);
    try {
      final box = await Hive.openBox(_boxName);
      final data = box.get(_settingsKey);
      if (data != null) {
        final settings = AppSettings.fromJson(
          Map<String, dynamic>.from(data),
        );
        state = state.copyWith(settings: settings, isLoading: false);
      } else {
        state = state.copyWith(isLoading: false);
      }
    } catch (e) {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> _saveSettings() async {
    try {
      final box = await Hive.openBox(_boxName);
      await box.put(_settingsKey, state.settings.toJson());
    } catch (e) {
      // ignore: storage save failure
    }
  }

  Future<void> setAIModel(AIModel model) async {
    state = state.copyWith(
      settings: state.settings.copyWith(aiModel: model.value),
    );
    await _saveSettings();
  }

  Future<void> setVoiceEnabled(bool enabled) async {
    state = state.copyWith(
      settings: state.settings.copyWith(voiceEnabled: enabled),
    );
    await _saveSettings();
  }

  Future<void> setShowGrid(bool show) async {
    state = state.copyWith(
      settings: state.settings.copyWith(showGrid: show),
    );
    await _saveSettings();
  }

  Future<void> setGridType(String type) async {
    state = state.copyWith(
      settings: state.settings.copyWith(gridType: type),
    );
    await _saveSettings();
  }

  Future<void> setShowScore(bool show) async {
    state = state.copyWith(
      settings: state.settings.copyWith(showScore: show),
    );
    await _saveSettings();
  }

  Future<void> setShowArOverlay(bool show) async {
    state = state.copyWith(
      settings: state.settings.copyWith(showArOverlay: show),
    );
    await _saveSettings();
  }

  Future<void> incrementAnalysisCount() async {
    final today = DateTime.now().toIso8601String().split('T').first;
    String lastReset = state.settings.lastResetDate;
    int count = state.settings.dailyAnalysisCount;

    if (lastReset != today) {
      count = 0;
      lastReset = today;
    }

    state = state.copyWith(
      settings: state.settings.copyWith(
        dailyAnalysisCount: count + 1,
        lastResetDate: lastReset,
      ),
    );
    await _saveSettings();
  }

  bool get canAnalyzeToday {
    final today = DateTime.now().toIso8601String().split('T').first;
    if (state.settings.lastResetDate != today) return true;
    if (state.settings.isProUser) return true;
    return state.settings.dailyAnalysisCount < 5;
  }

  int get remainingAnalysisToday {
    if (state.settings.isProUser) return -1;
    final today = DateTime.now().toIso8601String().split('T').first;
    if (state.settings.lastResetDate != today) return 5;
    return (5 - state.settings.dailyAnalysisCount).clamp(0, 5);
  }

  void setProUser(bool value) {
    state = state.copyWith(
      settings: state.settings.copyWith(isProUser: value),
    );
    _saveSettings();
  }

  void setEnableAiLog(bool value) {
    state = state.copyWith(
      settings: state.settings.copyWith(enableAiLog: value),
    );
    _saveSettings();
  }
}

final settingsProvider =
    StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  return SettingsNotifier();
});
