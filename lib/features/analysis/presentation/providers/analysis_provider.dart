import 'dart:async';
import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import '../../domain/entities/analysis_result.dart';
import '../../domain/entities/comparison_result.dart';
import '../../domain/entities/pose_data.dart';
import '../../domain/repositories/ai_repository.dart';
import '../../data/repositories/ai_repository_impl.dart';
import '../../../../core/ai/ai_service.dart';
import '../../../../core/ai/ai_model.dart';
import '../../../../core/utils/constants.dart';

final aiRepositoryProvider = Provider<AIRepository>((ref) {
  return AIRepositoryImpl(GLM4VService(apiKey: '03bfdfdf155849928b40cecc07479972.ZWLOwhSh8apHHYj4'));
});

final poseDetectorProvider = Provider<PoseDetector>((ref) {
  return PoseDetector(
    options: PoseDetectorOptions(
      model: PoseDetectionModel.accurate,
      mode: PoseDetectionMode.stream,
    ),
  );
});

class AnalysisState {
  final AnalysisResult? currentResult;
  final ComparisonResult? currentComparison;
  final double previousScore;
  final bool isAnalyzing;
  final PoseData? currentPose;
  final String? errorMessage;
  final DateTime? lastAnalysisTime;

  const AnalysisState({
    this.currentResult,
    this.currentComparison,
    this.previousScore = 0,
    this.isAnalyzing = false,
    this.currentPose,
    this.errorMessage,
    this.lastAnalysisTime,
  });

  AnalysisState copyWith({
    AnalysisResult? currentResult,
    ComparisonResult? currentComparison,
    double? previousScore,
    bool? isAnalyzing,
    PoseData? currentPose,
    String? errorMessage,
    DateTime? lastAnalysisTime,
  }) {
    return AnalysisState(
      currentResult: currentResult ?? this.currentResult,
      currentComparison: currentComparison ?? this.currentComparison,
      previousScore: previousScore ?? this.previousScore,
      isAnalyzing: isAnalyzing ?? this.isAnalyzing,
      currentPose: currentPose ?? this.currentPose,
      errorMessage: errorMessage ?? this.errorMessage,
      lastAnalysisTime: lastAnalysisTime ?? this.lastAnalysisTime,
    );
  }

  bool get canAnalyze {
    if (isAnalyzing) return false;
    if (lastAnalysisTime == null) return true;
    final elapsed = DateTime.now().difference(lastAnalysisTime!);
    return elapsed >= AppConstants.analysisInterval;
  }
}

class AnalysisNotifier extends StateNotifier<AnalysisState> {
  final AIRepository _aiRepository;
  final PoseDetector _poseDetector;
  StreamSubscription? _frameSubscription;

  AnalysisNotifier(this._aiRepository, this._poseDetector)
      : super(const AnalysisState());

  void startAnalysis(Stream<Uint8List> frameStream) {
    _frameSubscription?.cancel();
    _frameSubscription = frameStream.listen((frameData) {
      if (state.canAnalyze) {
        _analyzeFrame(frameData);
      }
    });
  }

  Future<void> _analyzeFrame(Uint8List imageData) async {
    if (state.isAnalyzing) return;

    state = state.copyWith(isAnalyzing: true);

    try {
      final result = await _aiRepository.analyzeFrame(imageData);
      state = state.copyWith(
        currentResult: result,
        previousScore: state.currentResult?.aestheticScore ?? 0,
        isAnalyzing: false,
        lastAnalysisTime: DateTime.now(),
      );
    } catch (e) {
      state = state.copyWith(
        isAnalyzing: false,
        errorMessage: e.toString(),
        lastAnalysisTime: DateTime.now(),
      );
    }
  }

  Future<void> analyzeWithReference({
    required Uint8List currentImageData,
    required Uint8List referenceImageData,
    String? analysisPrompt,
    String? comparisonPrompt,
  }) async {
    if (state.isAnalyzing) return;

    state = state.copyWith(isAnalyzing: true);

    try {
      final analysisFuture = _aiRepository.analyzeFrame(
        currentImageData,
        referenceImageData: referenceImageData,
        analysisPrompt: analysisPrompt,
      );

      final comparisonFuture = _aiRepository.compareWithReference(
        currentImageData: currentImageData,
        referenceImageData: referenceImageData,
        comparisonPrompt: comparisonPrompt,
      );

      final results = await Future.wait([
        analysisFuture,
        comparisonFuture,
      ]);

      state = state.copyWith(
        currentResult: results[0] as AnalysisResult,
        currentComparison: results[1] as ComparisonResult,
        previousScore: state.currentResult?.aestheticScore ?? 0,
        isAnalyzing: false,
        lastAnalysisTime: DateTime.now(),
      );
    } catch (e) {
      state = state.copyWith(
        isAnalyzing: false,
        errorMessage: e.toString(),
      );
    }
  }

  Future<PoseData?> detectPose(InputImage inputImage) async {
    try {
      final poses = await _poseDetector.processImage(inputImage);
      if (poses.isEmpty) return null;

      final pose = poses.first;
      final landmarks = pose.landmarks.values.map((landmark) {
        return PoseLandmarkData(
          type: landmark.type.index,
          x: landmark.x,
          y: landmark.y,
          z: landmark.z,
          likelihood: landmark.likelihood,
        );
      }).toList();

      final poseData = PoseData(
        landmarks: landmarks,
        timestamp: DateTime.now(),
      );

      state = state.copyWith(currentPose: poseData);
      return poseData;
    } catch (e) {
      return null;
    }
  }

  void switchModel(AIModel model) {
    _aiRepository.switchModel(model);
  }

  void onPhotoCaptured(String filePath) {}

  void clearResults() {
    state = const AnalysisState();
  }

  Future<void> analyzeFromImage(Uint8List imageData, {String? analysisPrompt}) async {
    if (state.isAnalyzing) return;

    state = state.copyWith(isAnalyzing: true);

    try {
      final result = await _aiRepository.analyzeFrame(imageData, analysisPrompt: analysisPrompt);
      state = state.copyWith(
        currentResult: result,
        previousScore: state.currentResult?.aestheticScore ?? 0,
        isAnalyzing: false,
        lastAnalysisTime: DateTime.now(),
      );
    } catch (e) {
      state = state.copyWith(
        isAnalyzing: false,
        errorMessage: e.toString(),
        lastAnalysisTime: DateTime.now(),
      );
    }
  }

  @override
  void dispose() {
    _frameSubscription?.cancel();
    _poseDetector.close();
    super.dispose();
  }
}

final analysisProvider =
    StateNotifierProvider<AnalysisNotifier, AnalysisState>((ref) {
  final aiRepository = ref.watch(aiRepositoryProvider);
  final poseDetector = ref.watch(poseDetectorProvider);
  return AnalysisNotifier(aiRepository, poseDetector);
});
