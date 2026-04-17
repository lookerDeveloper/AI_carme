import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers/gallery_provider.dart';
import '../domain/entities/photo_record.dart';
import '../../analysis/domain/entities/analysis_result.dart';

class GalleryScreen extends ConsumerWidget {
  const GalleryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(galleryProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        title: const Text('拍摄记录'),
        backgroundColor: const Color(0xFF1A1A1A),
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.records.isEmpty
              ? _buildEmptyState()
              : _buildPhotoGrid(context, state),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.photo_library_outlined, size: 64, color: Colors.white24),
          const SizedBox(height: 16),
          const Text('还没有拍摄记录', style: TextStyle(color: Colors.white38, fontSize: 16)),
          const SizedBox(height: 8),
          const Text('开始拍摄，AI将记录你的进步', style: TextStyle(color: Colors.white24, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildPhotoGrid(BuildContext context, GalleryState state) {
    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 4,
        crossAxisSpacing: 4,
      ),
      itemCount: state.records.length,
      itemBuilder: (context, index) {
        final record = state.records[index];
        return GestureDetector(
          onTap: () => _showPhotoDetail(context, record),
          child: Container(
            color: const Color(0xFF2A2A2A),
            child: Stack(
              fit: StackFit.expand,
              children: [
                const Center(child: Icon(Icons.image, color: Colors.white12, size: 32)),
                if (record.analysisResult is AnalysisResult)
                  Positioned(
                    top: 4,
                    right: 4,
                    child: _buildScoreBadge(record.analysisResult as AnalysisResult),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildScoreBadge(AnalysisResult result) {
    final score = result.aestheticScore;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '${score.round()}',
        style: TextStyle(
          color: _getScoreColor(score),
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Color _getScoreColor(double score) {
    if (score >= 85) return const Color(0xFF4CAF50);
    if (score >= 70) return const Color(0xFF8BC34A);
    if (score >= 50) return const Color(0xFFFFC107);
    return const Color(0xFFF44336);
  }

  void _showPhotoDetail(BuildContext context, PhotoRecord record) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) {
          return SingleChildScrollView(
            controller: scrollController,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Center(
                    child: Text('拍摄详情', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
                  ),
                  const SizedBox(height: 24),
                  Text('拍摄时间: ${record.captureTime.toString()}', style: const TextStyle(color: Colors.white54, fontSize: 14)),
                  const SizedBox(height: 8),
                  const Text('详细分析报告将在后续版本中提供', style: TextStyle(color: Colors.white38, fontSize: 14)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
