import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers/settings_provider.dart';
import '../../../../core/ai/ai_model.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(settingsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        title: const Text('设置'),
        backgroundColor: const Color(0xFF1A1A1A),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionTitle('AI模型'),
          _buildAIModelSelector(context, ref, state),
          const SizedBox(height: 24),
          _buildSectionTitle('拍摄辅助'),
          _buildSwitchTile(
            icon: Icons.record_voice_over,
            title: '语音播报',
            subtitle: '语音播报调整指令',
            value: state.settings.voiceEnabled,
            onChanged: (v) => ref.read(settingsProvider.notifier).setVoiceEnabled(v),
          ),
          _buildSwitchTile(
            icon: Icons.grid_on,
            title: '网格辅助线',
            subtitle: '显示构图辅助网格',
            value: state.settings.showGrid,
            onChanged: (v) => ref.read(settingsProvider.notifier).setShowGrid(v),
          ),
          _buildSwitchTile(
            icon: Icons.score,
            title: '美学评分',
            subtitle: '实时显示美学评分',
            value: state.settings.showScore,
            onChanged: (v) => ref.read(settingsProvider.notifier).setShowScore(v),
          ),
          _buildSwitchTile(
            icon: Icons.view_in_ar,
            title: 'AR辅助线',
            subtitle: '显示方向箭头和辅助线',
            value: state.settings.showArOverlay,
            onChanged: (v) => ref.read(settingsProvider.notifier).setShowArOverlay(v),
          ),
          const SizedBox(height: 24),
          _buildSectionTitle('使用情况'),
          _buildUsageCard(ref, state),
          const SizedBox(height: 24),
          _buildSectionTitle('关于'),
          _buildAboutCard(),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(title, style: const TextStyle(color: Colors.white54, fontSize: 13, fontWeight: FontWeight.w600)),
    );
  }

  Widget _buildAIModelSelector(BuildContext context, WidgetRef ref, SettingsState state) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: AIModel.values.map((model) {
          final isSelected = state.settings.aiModel == model.value;
          return ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: Icon(_getModelIcon(model), color: isSelected ? const Color(0xFF1A73E8) : Colors.white38, size: 20),
            title: Text(model.label, style: TextStyle(color: isSelected ? Colors.white : Colors.white54, fontSize: 14)),
            trailing: isSelected ? const Icon(Icons.check_circle, color: Color(0xFF1A73E8), size: 20) : null,
            onTap: () => ref.read(settingsProvider.notifier).setAIModel(model),
          );
        }).toList(),
      ),
    );
  }

  IconData _getModelIcon(AIModel model) {
    switch (model) {
      case AIModel.glm4v: return Icons.smart_toy;
      case AIModel.gpt4v: return Icons.psychology;
      case AIModel.claudeVision: return Icons.visibility;
      case AIModel.geminiVision: return Icons.auto_awesome;
    }
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: SwitchListTile(
        dense: true,
        contentPadding: EdgeInsets.zero,
        secondary: Icon(icon, color: Colors.white54, size: 20),
        title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 14)),
        subtitle: Text(subtitle, style: const TextStyle(color: Colors.white38, fontSize: 12)),
        value: value,
        activeThumbColor: const Color(0xFF1A73E8),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildUsageCard(WidgetRef ref, SettingsState state) {
    final remaining = ref.read(settingsProvider.notifier).remainingAnalysisToday;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('今日剩余AI分析次数', style: TextStyle(color: Colors.white, fontSize: 14)),
              Text(
                remaining < 0 ? '无限' : '$remaining次',
                style: TextStyle(
                  color: remaining > 0 ? const Color(0xFF4CAF50) : const Color(0xFFF44336),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: remaining < 0 ? 1.0 : remaining / 5,
              backgroundColor: const Color(0xFF2A2A2A),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF1A73E8)),
            ),
          ),
          const SizedBox(height: 8),
          const Text('升级专业版可获得无限次分析', style: TextStyle(color: Colors.white38, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildAboutCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('应用版本', style: TextStyle(color: Colors.white54, fontSize: 14)),
              Text('1.0.0', style: TextStyle(color: Colors.white38, fontSize: 14)),
            ],
          ),
          SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('产品名称', style: TextStyle(color: Colors.white54, fontSize: 14)),
              Text('智眸AI相机', style: TextStyle(color: Colors.white38, fontSize: 14)),
            ],
          ),
        ],
      ),
    );
  }
}
