import 'dart:typed_data';
import '../../domain/entities/analysis_result.dart';
import '../../domain/entities/comparison_result.dart';
import '../../domain/repositories/ai_repository.dart';
import '../../../../core/ai/ai_service.dart';
import '../../../../core/ai/ai_model.dart';

class AIRepositoryImpl implements AIRepository {
  final AIService _aiService;

  AIRepositoryImpl(this._aiService);

  @override
  bool get enableAiLog => _aiService.enableAiLog;

  @override
  set enableAiLog(bool value) => _aiService.enableAiLog = value;

  @override
  Future<AnalysisResult> analyzeFrame(Uint8List imageData, {
    Uint8List? referenceImageData,
    Map<String, dynamic>? cameraParams,
    Map<String, dynamic>? poseData,
    String? analysisPrompt,
    String? comparisonPrompt,
  }) {
    return _aiService.analyzeFrame(
      imageData,
      referenceImageData: referenceImageData,
      cameraParams: cameraParams,
      poseData: poseData,
      analysisPrompt: analysisPrompt,
      comparisonPrompt: comparisonPrompt,
    );
  }

  @override
  Future<ComparisonResult> compareWithReference({
    required Uint8List currentImageData,
    required Uint8List referenceImageData,
    String? comparisonPrompt,
  }) {
    return _aiService.compareWithReference(
      currentImageData: currentImageData,
      referenceImageData: referenceImageData,
      comparisonPrompt: comparisonPrompt,
    );
  }

  @override
  void switchModel(AIModel model) => _aiService.switchModel(model);

  @override
  AIModel get currentModel => _aiService.currentModel;
}
