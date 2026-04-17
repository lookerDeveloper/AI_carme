import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';

class ScoreDisplay extends StatelessWidget {
  final double score;
  final double? previousScore;

  const ScoreDisplay({
    super.key,
    required this.score,
    this.previousScore,
  });

  @override
  Widget build(BuildContext context) {
    final displayScore = score.round();
    final scoreColor = AppColors.scoreColor(score);
    final diff = previousScore != null && previousScore! > 0
        ? (score - previousScore!)
        : null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$displayScore',
            style: TextStyle(
              color: scoreColor,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 4),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '美学得分',
                style: TextStyle(color: Colors.white70, fontSize: 9),
              ),
              if (diff != null && diff.abs() > 1)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      diff > 0 ? Icons.arrow_upward : Icons.arrow_downward,
                      size: 10,
                      color: diff > 0 ? AppColors.success : AppColors.error,
                    ),
                    Text(
                      '${diff > 0 ? '+' : ''}${diff.toStringAsFixed(0)}',
                      style: TextStyle(
                        color: diff > 0 ? AppColors.success : AppColors.error,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }
}
