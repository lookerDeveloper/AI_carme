import 'dart:io';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:camerawesome/camerawesome_plugin.dart';
import 'package:path_provider/path_provider.dart';
import 'providers/camera_provider.dart' as app_camera;
import 'widgets/grid_overlay.dart';
import 'widgets/ai_log_panel.dart';
import '../domain/entities/camera_enums.dart' as app_enums;
import '../../analysis/presentation/providers/analysis_provider.dart';
import '../../analysis/presentation/widgets/feedback_panel.dart';
import '../../analysis/presentation/widgets/score_display.dart';
import '../../reference/presentation/providers/reference_provider.dart';
import '../../../core/utils/app_logger.dart';
import '../../../core/api/api_service.dart';
import '../../../core/utils/image_utils.dart';

class CameraScreen extends ConsumerStatefulWidget {
  const CameraScreen({super.key});

  @override
  ConsumerState<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends ConsumerState<CameraScreen> {
  PhotoCameraState? _photoState;
  bool _isAnalyzing = false;
  bool _showAiLogPanel = false;

  @override
  void initState() {
    super.initState();
    AppLogger.logInfo('相机页面初始化', tag: 'Camera');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(app_camera.cameraProvider.notifier).initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    final cameraState = ref.watch(app_camera.cameraProvider);
    final analysisState = ref.watch(analysisProvider);
    final referenceState = ref.watch(referenceProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          _buildCameraPreview(),
          _buildGridOverlay(cameraState),
          if (referenceState.selectedTemplate != null)
            Positioned(
              top: MediaQuery.of(context).padding.top + 80,
              right: 16,
              child: Container(
                width: 80,
                height: 100,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.white10,
                  border: Border.all(color: Colors.white30),
                ),
                clipBehavior: Clip.antiAlias,
                child: Image.network(
                  referenceState.selectedTemplate!.displayImageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (c, e, s) => const Center(
                    child: Icon(Icons.broken_image, color: Colors.white24, size: 20),
                  ),
                ),
              ),
            ),
          if (analysisState.currentResult != null)
            FeedbackPanel(
              result: analysisState.currentResult!,
              comparisonResult: analysisState.currentComparison,
            ),
          _buildTopBar(cameraState),
          _buildScoreDisplay(analysisState),
          if (!_isAnalyzing) _buildAIAnalysisButton(),
          if (_isAnalyzing) _buildAnalyzingOverlay(),
          AiLogPanel(
            isExpanded: _showAiLogPanel,
            onToggle: () => setState(() => _showAiLogPanel = !_showAiLogPanel),
            onClose: () => setState(() => _showAiLogPanel = false),
          ),
        ],
      ),
    );
  }

  Widget _buildCameraPreview() {
    AppLogger.logDebug('构建相机预览层', tag: 'Camera');
    
    return Positioned.fill(
      child: CameraAwesomeBuilder.awesome(
        saveConfig: SaveConfig.photo(
          pathBuilder: (sensors) async {
            final dir = await getTemporaryDirectory();
            final filePath = '${dir.path}/ai_analysis_${DateTime.now().millisecondsSinceEpoch}.jpg';
            return SingleCaptureRequest(filePath, sensors.first);
          },
        ),
        previewFit: CameraPreviewFit.cover,
        onMediaCaptureEvent: (event) {
          if (event.status == MediaCaptureStatus.success && event.isPicture) {
            event.captureRequest.when(
              single: (single) {
                AppLogger.logInfo('拍照成功: ${single.file?.path}', tag: 'Camera');
              },
              multiple: (multiple) {},
            );
          }
        },
        topActionsBuilder: (cameraState) {
          cameraState.when(
            onPhotoMode: (photoState) {
              if (_photoState != photoState) {
                _photoState = photoState;
                AppLogger.logInfo('PhotoCameraState 已初始化', tag: 'Camera');
              }
            },
            onVideoMode: (_) {},
            onVideoRecordingMode: (_) {},
            onPreparingCamera: (_) {},
          );
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildGridOverlay(app_camera.CameraState cameraState) {
    if (cameraState.gridType == app_enums.GridType.none) return const SizedBox.shrink();
    
    return Positioned.fill(
      child: IgnorePointer(
        child: GridOverlay(gridType: cameraState.gridType),
      ),
    );
  }

  Widget _buildAIAnalysisButton() {
    return Positioned(
      bottom: MediaQuery.of(context).padding.bottom + 100,
      right: 20,
      child: GestureDetector(
        onTap: () => _startAIAnalysis(),
        onLongPress: () => _showAIDetailOptions(),
        child: Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [Color(0xFF1A73E8), Color(0xFF4285F4)],
            ),
            boxShadow: [
              BoxShadow(
                color: Color(0xFF1A73E8).withValues(alpha: 0.4),
                blurRadius: 12,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.auto_awesome, color: Colors.white, size: 22),
              Text('AI分析', style: TextStyle(color: Colors.white, fontSize: 9)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnalyzingOverlay() {
    return Positioned.fill(
      child: Container(
        color: Colors.black38,
        child: Center(
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 32, vertical: 24),
            decoration: BoxDecoration(
              color: Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 40,
                  height: 40,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4285F4)),
                  ),
                ),
                SizedBox(height: 16),
                Text('AI正在分析...', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500)),
                SizedBox(height: 8),
                Text('正在拍照并上传分析', style: TextStyle(color: Colors.white54, fontSize: 13)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _startAIAnalysis() async {
    if (_isAnalyzing) return;
    
    AppLogger.logInfo('开始AI美学分析', tag: 'AI');
    AppLogger.logInfo('PhotoCameraState: ${_photoState != null ? "已初始化" : "未初始化"}', tag: 'AI');
    
    setState(() => _isAnalyzing = true);
    ref.read(analysisProvider.notifier).clearResults();

    try {
      if (_photoState == null) {
        throw Exception('相机未就绪，请稍后重试');
      }

      AppLogger.logInfo('调用相机拍照...', tag: 'AI');
      final captureRequest = await _photoState!.takePhoto();
      
      String? photoPath;
      captureRequest.when(
        single: (single) => photoPath = single.file?.path,
        multiple: (multiple) => photoPath = multiple.fileBySensor.values.first?.path,
      );

      if (photoPath == null) {
        throw Exception('拍照失败：无法获取文件路径');
      }

      AppLogger.logInfo('拍照成功: $photoPath', tag: 'AI');

      final file = File(photoPath!);
      if (!await file.exists()) {
        throw Exception('照片文件不存在');
      }

      final imageBytes = await file.readAsBytes();
      AppLogger.logInfo('读取图片成功，大小: ${imageBytes.length} bytes，开始并行处理...', tag: 'AI');

      final referenceState = ref.read(referenceProvider);
      final selectedTemplate = referenceState.selectedTemplate;

      final parallelTasks = <Future>[
        ImageUtils.compressImage(imageBytes),
        if (selectedTemplate != null && selectedTemplate.hasValidImage)
          _preloadReferenceImage(selectedTemplate)
        else
          Future.value(null),
      ];

      final parallelResults = await Future.wait(parallelTasks);
      final compressedImage = parallelResults[0] as Uint8List;
      final referenceImageData = parallelResults.length > 1 ? parallelResults[1] as Uint8List? : null;

      AppLogger.logInfo('图片预处理完成，开始AI分析...', tag: 'AI');

      final analysisPrompt = selectedTemplate?.analysisPrompt;
      final comparisonPrompt = selectedTemplate?.comparisonPrompt;

      if (referenceImageData != null && comparisonPrompt != null) {
        await ref.read(analysisProvider.notifier).analyzeWithReference(
          currentImageData: compressedImage,
          referenceImageData: referenceImageData,
          analysisPrompt: analysisPrompt,
          comparisonPrompt: comparisonPrompt,
        );
      } else {
        await ref.read(analysisProvider.notifier).analyzeFromImage(
          compressedImage,
          analysisPrompt: analysisPrompt,
        );
      }

      final result = ref.read(analysisProvider).currentResult;
      AppLogger.logInfo('AI分析完成，评分: ${result?.aestheticScore}', tag: 'AI');

      try {
        await file.delete();
      } catch (_) {}

      if (mounted && result != null) {
        _showAnalysisResultDialog(result.aestheticScore, result.suggestions, result.sceneType);
      }

    } catch (e) {
      AppLogger.logError('AI分析失败: $e', tag: 'AI');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('分析失败: $e'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isAnalyzing = false);
      }
    }
  }

  Future<Uint8List?> _preloadReferenceImage(template) async {
    try {
      AppLogger.logInfo('预加载参考图: ${template.displayImageUrl}', tag: 'AI');
      final response = await Dio().get(
        template.displayImageUrl,
        options: Options(responseType: ResponseType.bytes),
      );
      final referenceBytes = response.data as Uint8List;
      AppLogger.logInfo('参考图加载成功，大小: ${referenceBytes.length} bytes', tag: 'AI');
      return await ImageUtils.compressImage(referenceBytes);
    } catch (e) {
      AppLogger.logError('参考图预加载失败: $e', tag: 'AI');
      return null;
    }
  }

  void _showAnalysisResultDialog(double score, List<String> suggestions, String sceneType) {
    final scoreColor = score >= 80 ? Colors.green : score >= 60 ? Colors.orange : Colors.red;
    final sceneName = {
      'portrait': '人像', 'landscape': '风景', 'food': '美食',
      'pet': '宠物', 'architecture': '建筑', 'street': '街拍',
      'still_life': '静物', 'unknown': '综合',
    }[sceneType] ?? '综合';

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      isScrollControlled: true,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Container(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            SizedBox(height: 20),
            Row(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [scoreColor.withValues(alpha: 0.3), scoreColor.withValues(alpha: 0.1)],
                    ),
                    border: Border.all(color: scoreColor, width: 2),
                  ),
                  child: Center(
                    child: Text(
                      score.toStringAsFixed(0),
                      style: TextStyle(
                        color: scoreColor,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('美学评分', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
                      SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Color(0xFF1A73E8).withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(sceneName, style: TextStyle(color: Color(0xFF4285F4), fontSize: 12)),
                          ),
                          SizedBox(width: 8),
                          Text(
                            score >= 80 ? '优秀' : score >= 60 ? '良好' : score >= 40 ? '一般' : '待提升',
                            style: TextStyle(color: scoreColor, fontSize: 14, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (suggestions.isNotEmpty) ...[
              SizedBox(height: 24),
              Text('💡 改进建议', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
              SizedBox(height: 12),
              ...suggestions.asMap().entries.map((entry) => Padding(
                padding: EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: Color(0xFF1A73E8).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Center(
                        child: Text('${entry.key + 1}', style: TextStyle(color: Color(0xFF4285F4), fontSize: 12, fontWeight: FontWeight.w600)),
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Container(
                        padding: EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.white10),
                        ),
                        child: Text(entry.value, style: TextStyle(color: Colors.white70, fontSize: 14, height: 1.4)),
                      ),
                    ),
                  ],
                ),
              )),
            ],
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white70,
                      side: BorderSide(color: Colors.white24),
                      padding: EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text('关闭', style: TextStyle(fontSize: 16)),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _startAIAnalysis();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF1A73E8),
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text('重新分析', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                  ),
                ),
              ],
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom),
          ],
        ),
      ),
    );
  }

  void _showAIDetailOptions() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(context).viewInsets.bottom + 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('🤖 AI智能分析选项', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
            SizedBox(height: 16),
            _buildAIOptionItem(Icons.auto_awesome, '美学评分', '综合评估照片的美学价值', () {
              Navigator.pop(context);
              _startAIAnalysis();
            }),
            Divider(color: Colors.white10),
            _buildAIOptionItem(Icons.grid_on, '构图检测', '分析三分法、黄金分割等', () {
              Navigator.pop(context);
              _startAIAnalysis();
            }),
            Divider(color: Colors.white10),
            _buildAIOptionItem(Icons.person, '姿态识别', '检测人物姿态是否标准', () {
              Navigator.pop(context);
              _startAIAnalysis();
            }),
            Divider(color: Colors.white10),
            _buildAIOptionItem(Icons.compare_arrows, '参考对比', '与选中模板进行对比', () {
              Navigator.pop(context);
              _startAIAnalysis();
            }),
            SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildAIOptionItem(IconData icon, String title, String desc, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Color(0xFF1A73E8).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: Color(0xFF1A73E8), size: 22),
            ),
            SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white)),
                  SizedBox(height: 4),
                  Text(desc, style: TextStyle(fontSize: 12, color: Colors.white54)),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.white30),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(app_camera.CameraState cameraState) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        bottom: false,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.black.withValues(alpha: 0.7), Colors.transparent],
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '智眸AI相机',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
              ),
              Row(
                children: [
                  _buildTopBarButton(Icons.flash_auto, () {
                    AppLogger.logInfo('切换闪光灯模式', tag: 'Camera');
                    final modes = app_enums.FlashMode.values;
                    final currentIndex = modes.indexOf(cameraState.flashMode);
                    final nextMode = modes[(currentIndex + 1) % modes.length];
                    ref.read(app_camera.cameraProvider.notifier).setFlashMode(nextMode);
                  }),
                  const SizedBox(width: 12),
                  _buildTopBarButton(
                    cameraState.gridType != app_enums.GridType.none ? Icons.grid_on : Icons.grid_off,
                    () {
                      AppLogger.logInfo('切换网格模式', tag: 'Camera');
                      final types = app_enums.GridType.values;
                      final currentIndex = types.indexOf(cameraState.gridType);
                      final nextType = types[(currentIndex + 1) % types.length];
                      ref.read(app_camera.cameraProvider.notifier).setGridType(nextType);
                    },
                  ),
                  const SizedBox(width: 12),
                  _buildTopBarButton(Icons.info_outline, () {
                    showModalBottomSheet(
                      context: context,
                      backgroundColor: const Color(0xFF1A1A1A),
                      builder: (_) => _buildInfoSheet(),
                    );
                  }),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBarButton(IconData icon, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black38,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
      ),
    );
  }

  Widget _buildScoreDisplay(AnalysisState analysisState) {
    if (analysisState.currentResult == null) return const SizedBox.shrink();
    return Positioned(
      top: MediaQuery.of(context).padding.top + 50,
      right: 16,
      child: ScoreDisplay(
        score: analysisState.currentResult!.aestheticScore,
        previousScore: analysisState.previousScore,
      ),
    );
  }

  Widget _buildInfoSheet() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('智眸AI相机 v1.0', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 12),
          Text('基于AI的智能摄影助手', style: TextStyle(fontSize: 14, color: Colors.white70)),
          const SizedBox(height: 4),
          Text('支持实时构图分析、姿态检测、美学评分', style: TextStyle(fontSize: 12, color: Colors.white54)),
          const SizedBox(height: 20),
          Text('API地址: ${ApiService.baseUrl}', style: TextStyle(fontSize: 11, color: Colors.blue[200], fontFamily: 'monospace')),
        ],
      ),
    );
  }
}
