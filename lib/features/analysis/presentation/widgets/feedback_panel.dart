import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../domain/entities/analysis_result.dart';
import '../../domain/entities/comparison_result.dart';

class FeedbackPanel extends StatelessWidget {
  final AnalysisResult result;
  final ComparisonResult? comparisonResult;

  const FeedbackPanel({
    super.key,
    required this.result,
    this.comparisonResult,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 16,
      right: 16,
      bottom: 120,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.black54,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDirectionFeedback(),
            const SizedBox(height: 8),
            _buildPoseFeedback(),
            if (comparisonResult != null) ...[
              const SizedBox(height: 8),
              _buildComparisonFeedback(),
            ],
            if (result.suggestions.isNotEmpty) ...[
              const SizedBox(height: 8),
              ...result.suggestions.take(2).map(
                (suggestion) => Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Row(
                    children: [
                      Icon(Icons.lightbulb_outline, size: 14, color: AppColors.warning),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          suggestion,
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDirectionFeedback() {
    final adjustments = result.cameraAdjustments;
    if (adjustments.moveDirection == 'none' &&
        adjustments.tiltAdjustment == 'level' &&
        adjustments.zoomAdjustment == 'none') {
      return const SizedBox.shrink();
    }

    List<String> directions = [];
    if (adjustments.moveDirection != 'none') {
      final moveText = _getMoveText(adjustments.moveDirection);
      final amountText = _getAmountText(adjustments.moveAmount);
      directions.add('$moveText$amountText');
    }
    if (adjustments.tiltAdjustment != 'level') {
      directions.add(_getTiltText(adjustments.tiltAdjustment));
    }
    if (adjustments.zoomAdjustment != 'none') {
      directions.add(adjustments.zoomAdjustment == 'zoom_in' ? '靠近一点' : '拉远一点');
    }

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _getDirectionIcon(adjustments.moveDirection),
                size: 14,
                color: AppColors.primaryLight,
              ),
              const SizedBox(width: 4),
              Text(
                directions.join(' · '),
                style: const TextStyle(
                  color: AppColors.primaryLight,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _getMoveText(String direction) {
    switch (direction) {
      case 'left': return '手机向左移动';
      case 'right': return '手机向右移动';
      case 'up': return '手机向上移动';
      case 'down': return '手机向下移动';
      case 'forward': return '靠近主体';
      case 'backward': return '远离主体';
      default: return '';
    }
  }

  String _getAmountText(String amount) {
    switch (amount) {
      case 'small': return '一点';
      case 'medium': return '';
      case 'large': return '较多';
      default: return '';
    }
  }

  String _getTiltText(String tilt) {
    switch (tilt) {
      case 'tilt_up': return '抬高机位';
      case 'tilt_down': return '降低机位';
      default: return '';
    }
  }

  IconData _getDirectionIcon(String direction) {
    switch (direction) {
      case 'left': return Icons.arrow_back;
      case 'right': return Icons.arrow_forward;
      case 'up': return Icons.arrow_upward;
      case 'down': return Icons.arrow_downward;
      default: return Icons.adjust;
    }
  }

  Widget _buildPoseFeedback() {
    if (result.poseAdjustments.isEmpty) return const SizedBox.shrink();

    return Row(
      children: [
        const Icon(Icons.person_outline, size: 14, color: Color(0xFFFF9800)),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            result.poseAdjustments.first,
            style: const TextStyle(color: Color(0xFFFFB74D), fontSize: 13),
          ),
        ),
      ],
    );
  }

  Widget _buildComparisonFeedback() {
    if (comparisonResult == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.compare_arrows, size: 14, color: Color(0xFF9C27B0)),
            const SizedBox(width: 6),
            Text(
              '相似度: ${comparisonResult!.similarityScore.toStringAsFixed(0)}%',
              style: TextStyle(
                color: comparisonResult!.similarityScore >= 80
                    ? AppColors.success
                    : comparisonResult!.similarityScore >= 50
                        ? AppColors.warning
                        : AppColors.error,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        if (comparisonResult!.currentAdjustment.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              comparisonResult!.currentAdjustment,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
          ),
      ],
    );
  }
}
