import 'dart:typed_data';
import '../../domain/entities/analysis_result.dart';
import '../../domain/entities/comparison_result.dart';
import '../../../../core/ai/ai_model.dart';

abstract class AIRepository {
  Future<AnalysisResult> analyzeFrame(Uint8List imageData, {
    Uint8List? referenceImageData,
    Map<String, dynamic>? cameraParams,
    Map<String, dynamic>? poseData,
    String? analysisPrompt,
    String? comparisonPrompt,
  });

  Future<ComparisonResult> compareWithReference({
    required Uint8List currentImageData,
    required Uint8List referenceImageData,
    String? comparisonPrompt,
  });

  void switchModel(AIModel model);
  AIModel get currentModel;
}
