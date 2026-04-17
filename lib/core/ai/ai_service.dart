import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'ai_model.dart';
import '../../features/analysis/domain/entities/analysis_result.dart';
import '../../features/analysis/domain/entities/comparison_result.dart';
import '../utils/image_utils.dart';
import '../utils/app_logger.dart';

abstract class AIService {
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
  
  bool get enableAiLog;
  set enableAiLog(bool value);
}

class GLM4VService implements AIService {
  final Dio _dio;
  AIModel _currentModel = AIModel.glm4v;
  final String apiKey;
  bool _enableAiLog = false;

  GLM4VService({
    required this.apiKey,
    Dio? dio,
    bool? enableAiLog,
  }) : _dio = dio ?? Dio() {
    if (enableAiLog != null) {
      _enableAiLog = enableAiLog;
    }
  }

  @override
  bool get enableAiLog => _enableAiLog;

  @override
  set enableAiLog(bool value) {
    _enableAiLog = value;
    AppLogger.logInfo('AI日志开关: ${value ? "已开启" : "已关闭"}', tag: 'AI');
  }

  @override
  AIModel get currentModel => _currentModel;

  @override
  void switchModel(AIModel model) {
    _currentModel = model;
  }

  @override
  Future<AnalysisResult> analyzeFrame(Uint8List imageData, {
    Uint8List? referenceImageData,
    Map<String, dynamic>? cameraParams,
    Map<String, dynamic>? poseData,
    String? analysisPrompt,
    String? comparisonPrompt,
  }) async {
    final compressedImage = await ImageUtils.compressImage(imageData);
    final base64Image = ImageUtils.imageToBase64(compressedImage);

    final prompt = analysisPrompt ?? _buildDefaultAnalysisPrompt(
      hasReference: referenceImageData != null,
      cameraParams: cameraParams,
      poseData: poseData,
    );

    final messages = <Map<String, dynamic>>[
      {
        'role': 'user',
        'content': [
          {'type': 'text', 'text': prompt},
          {
            'type': 'image_url',
            'image_url': {'url': 'data:image/jpeg;base64,$base64Image'},
          },
          if (referenceImageData != null) ...[
            {
              'type': 'image_url',
              'image_url': {
                'url':
                    'data:image/jpeg;base64,${ImageUtils.imageToBase64(await ImageUtils.compressImage(referenceImageData))}',
              },
            },
          ],
        ],
      },
    ];

    try {
      final startTime = DateTime.now();
      
      if (_enableAiLog) {
        AppLogger.logInfo('========== [AI请求开始] ==========', tag: 'AI');
        AppLogger.logInfo('接口: glm-4v-flash 分析帧', tag: 'AI');
        AppLogger.logInfo('模型: glm-4v-flash', tag: 'AI');
        AppLogger.logInfo('原始图片大小: ${imageData.length} bytes', tag: 'AI');
        AppLogger.logInfo('压缩后大小: ${compressedImage.length} bytes (${(compressedImage.length / imageData.length * 100).toStringAsFixed(1)}%)', tag: 'AI');
        AppLogger.logInfo('参考图: ${referenceImageData != null ? "有" : "无"}', tag: 'AI');
        AppLogger.logInfo('Prompt来源: ${analysisPrompt != null ? "自定义/分类Prompt" : "默认通用Prompt"}', tag: 'AI');
        AppLogger.logInfo('Prompt长度: ${prompt.length} 字符', tag: 'AI');
        AppLogger.logInfo('--- Prompt内容预览 ---\n${prompt.substring(0, prompt.length > 200 ? 200 : prompt.length)}...', tag: 'AI');
        if (referenceImageData != null) {
          final refCompressedSize = await ImageUtils.compressImage(referenceImageData);
          AppLogger.logInfo('参考图压缩后大小: ${refCompressedSize.length} bytes', tag: 'AI');
        }
      }

      final response = await _dio.post(
        'https://open.bigmodel.cn/api/paas/v4/chat/completions',
        options: Options(
          headers: {
            'Authorization': 'Bearer $apiKey',
            'Content-Type': 'application/json',
          },
        ),
        data: {
          'model': 'glm-4v-flash',
          'messages': messages,
          'max_tokens': 512,
          'temperature': 0.7,
        },
      );

      final content = response.data['choices'][0]['message']['content'];
      final duration = DateTime.now().difference(startTime).inMilliseconds;

      if (_enableAiLog) {
        AppLogger.logInfo('========== [AI响应返回] ==========', tag: 'AI');
        AppLogger.logInfo('耗时: ${duration}ms', tag: 'AI');
        AppLogger.logInfo('HTTP状态码: ${response.statusCode}', tag: 'AI');
        AppLogger.logInfo('原始响应长度: ${content.length} 字符', tag: 'AI');
        AppLogger.logInfo('--- 原始响应内容 ---\n$content', tag: 'AI');
        
        try {
          final parsedResult = _parseAnalysisResult(content);
          AppLogger.logInfo('--- 解析后结果 ---', tag: 'AI');
          AppLogger.logInfo('美学评分: ${parsedResult.aestheticScore}', tag: 'AI');
          AppLogger.logInfo('场景类型: ${parsedResult.sceneType}', tag: 'AI');
          AppLogger.logInfo('建议数量: ${parsedResult.suggestions.length}', tag: 'AI');
          if (parsedResult.suggestions.isNotEmpty) {
            AppLogger.logInfo('建议列表: ${parsedResult.suggestions.join(" | ")}', tag: 'AI');
          }
          AppLogger.logInfo('相机调整: 移动=${parsedResult.cameraAdjustments.moveDirection} 幅度=${parsedResult.cameraAdjustments.moveAmount}', tag: 'AI');
          AppLogger.logInfo('推荐参数: 焦距=${parsedResult.recommendedParams.focalLength} 光圈=${parsedResult.recommendedParams.aperture} ISO=${parsedResult.recommendedParams.iso}', tag: 'AI');
          AppLogger.logInfo('=====================================\n', tag: 'AI');
        } catch (e) {
          AppLogger.logError('解析结果日志记录失败: $e', tag: 'AI');
        }
      }

      return _parseAnalysisResult(content);
    } catch (e) {
      return AnalysisResult(
        aestheticScore: 50.0,
        suggestions: ['分析暂时不可用，请稍后重试'],
        issues: [],
        cameraAdjustments: const CameraAdjustments(),
        poseAdjustments: [],
        recommendedParams: const RecommendedParams(),
        sceneType: 'unknown',
        analyzedAt: DateTime.now(),
      );
    }
  }

  @override
  Future<ComparisonResult> compareWithReference({
    required Uint8List currentImageData,
    required Uint8List referenceImageData,
    String? comparisonPrompt,
  }) async {
    final compressedCurrent =
        await ImageUtils.compressImage(currentImageData);
    final compressedReference =
        await ImageUtils.compressImage(referenceImageData);

    final base64Current = ImageUtils.imageToBase64(compressedCurrent);
    final base64Reference = ImageUtils.imageToBase64(compressedReference);

    final prompt = comparisonPrompt ?? _buildDefaultComparisonPrompt();

    final messages = <Map<String, dynamic>>[
      {
        'role': 'user',
        'content': [
          {'type': 'text', 'text': prompt},
          {
            'type': 'image_url',
            'image_url': {'url': 'data:image/jpeg;base64,$base64Reference'},
          },
          {
            'type': 'image_url',
            'image_url': {'url': 'data:image/jpeg;base64,$base64Current'},
          },
        ],
      },
    ];

    try {
      final startTime = DateTime.now();

      if (_enableAiLog) {
        AppLogger.logInfo('========== [AI请求开始] ==========', tag: 'AI');
        AppLogger.logInfo('接口: glm-4v-flash 对比参考图', tag: 'AI');
        AppLogger.logInfo('模型: glm-4v-flash', tag: 'AI');
        AppLogger.logInfo('当前图片大小: ${currentImageData.length} bytes -> 压缩后 ${compressedCurrent.length} bytes', tag: 'AI');
        AppLogger.logInfo('参考图片大小: ${referenceImageData.length} bytes -> 压缩后 ${compressedReference.length} bytes', tag: 'AI');
        AppLogger.logInfo('Prompt来源: ${comparisonPrompt != null ? "自定义/分类Prompt" : "默认通用Prompt"}', tag: 'AI');
        AppLogger.logInfo('Prompt长度: ${prompt.length} 字符', tag: 'AI');
        AppLogger.logInfo('--- Prompt内容预览 ---\n${prompt.substring(0, prompt.length > 200 ? 200 : prompt.length)}...', tag: 'AI');
      }

      final response = await _dio.post(
        'https://open.bigmodel.cn/api/paas/v4/chat/completions',
        options: Options(
          headers: {
            'Authorization': 'Bearer $apiKey',
            'Content-Type': 'application/json',
          },
        ),
        data: {
          'model': 'glm-4v-flash',
          'messages': messages,
          'max_tokens': 512,
          'temperature': 0.7,
        },
      );

      final content = response.data['choices'][0]['message']['content'];
      final duration = DateTime.now().difference(startTime).inMilliseconds;

      if (_enableAiLog) {
        AppLogger.logInfo('========== [AI响应返回] ==========', tag: 'AI');
        AppLogger.logInfo('耗时: ${duration}ms', tag: 'AI');
        AppLogger.logInfo('HTTP状态码: ${response.statusCode}', tag: 'AI');
        AppLogger.logInfo('原始响应长度: ${content.length} 字符', tag: 'AI');
        AppLogger.logInfo('--- 原始响应内容 ---\n$content', tag: 'AI');

        try {
          final parsedResult = _parseComparisonResult(content);
          AppLogger.logInfo('--- 解析后结果 ---', tag: 'AI');
          AppLogger.logInfo('相似度评分: ${parsedResult.similarityScore}', tag: 'AI');
          AppLogger.logInfo('主体位置差异: ${parsedResult.compositionGap.subjectPositionDiff}', tag: 'AI');
          AppLogger.logInfo('角度差异: ${parsedResult.compositionGap.angleDiff}', tag: 'AI');
          AppLogger.logInfo('距离差异: ${parsedResult.compositionGap.distanceDiff}', tag: 'AI');
          AppLogger.logInfo('调整步骤数量: ${parsedResult.steps.length}', tag: 'AI');
          if (parsedResult.steps.isNotEmpty) {
            AppLogger.logInfo('调整步骤: ${parsedResult.steps.join(" | ")}', tag: 'AI');
          }
          AppLogger.logInfo('当前调整建议: ${parsedResult.currentAdjustment}', tag: 'AI');
          AppLogger.logInfo('=====================================\n', tag: 'AI');
        } catch (e) {
          AppLogger.logError('解析结果日志记录失败: $e', tag: 'AI');
        }
      }

      return _parseComparisonResult(content);
    } catch (e) {
      return ComparisonResult(
        similarityScore: 0,
        compositionGap: const CompositionGap(),
        steps: ['比对暂时不可用，请稍后重试'],
        currentAdjustment: '无法获取调整建议',
        comparedAt: DateTime.now(),
      );
    }
  }

  String _buildDefaultAnalysisPrompt({
    bool hasReference = false,
    Map<String, dynamic>? cameraParams,
    Map<String, dynamic>? poseData,
  }) {
    return '''你是一位专业摄影指导专家。请分析这张照片的构图质量，并给出具体、可操作的调整建议。

请从以下维度分析：
1. 主体是否突出
2. 构图是否平衡
3. 光线运用
4. 背景处理
5. 景深控制

${hasReference ? '同时请参考第二张参考图，分析当前画面与参考图的差异。' : ''}

请以JSON格式返回，包含以下字段：
{
  "aesthetic_score": 0-100的整数,
  "scene_type": "portrait/landscape/food/pet/architecture/street/still_life",
  "issues": ["问题1", "问题2"],
  "suggestions": ["建议1", "建议2"],
  "camera_adjustments": {
    "move_direction": "left/right/up/down/forward/backward/none",
    "move_amount": "small/medium/large",
    "tilt_adjustment": "tilt_up/tilt_down/level",
    "zoom_adjustment": "zoom_in/zoom_out/none"
  },
  "pose_adjustments": ["模特调整建议1"],
  "recommended_params": {
    "focal_length": "24mm/35mm/50mm/85mm",
    "aperture": "f/2.8/f/4/f/5.6/f/8",
    "exposure_compensation": "+0.3/0/-0.3",
    "iso": 100-800
  }
}

注意：只返回JSON，不要包含其他文字。''';
  }

  String _buildDefaultComparisonPrompt() {
    return '''你是一位专业摄影指导专家。用户希望拍摄出与参考图类似效果的照片。

第一张图是参考图，第二张图是当前画面。

请对比两张图，分析以下差异：
1. 构图差异（主体位置、视角、景别）
2. 光线差异
3. 色调差异
4. 拍摄角度差异

请给出具体调整建议，让用户逐步接近参考图效果。

以JSON格式返回：
{
  "similarity_score": 0-100的整数,
  "composition_gap": {
    "subject_position_diff": "左侧偏多/右侧偏多/基本一致",
    "angle_diff": "需要降低机位/需要抬高机位/基本一致",
    "distance_diff": "需要靠近/需要拉远/基本一致"
  },
  "steps": ["步骤1", "步骤2", "步骤3"],
  "current_adjustment": "当前最需要调整的是什么"
}

注意：只返回JSON，不要包含其他文字。''';
  }

  AnalysisResult _parseAnalysisResult(String content) {
    try {
      final jsonStr = _extractJson(content);
      final json = jsonDecode(jsonStr) as Map<String, dynamic>;

      return AnalysisResult(
        aestheticScore: (json['aesthetic_score'] as num?)?.toDouble() ?? 50.0,
        suggestions: (json['suggestions'] as List?)
                ?.map((e) => e.toString())
                .toList() ??
            [],
        issues: (json['issues'] as List?)
                ?.map((e) => CompositionIssue(
                      description: e.toString(),
                      severity: 'medium',
                      category: 'composition',
                    ))
                .toList() ??
            [],
        cameraAdjustments: CameraAdjustments(
          moveDirection: json['camera_adjustments']?['move_direction']
                  as String? ??
              'none',
          moveAmount: json['camera_adjustments']?['move_amount'] as String? ??
              'none',
          tiltAdjustment: json['camera_adjustments']?['tilt_adjustment']
                  as String? ??
              'level',
          zoomAdjustment: json['camera_adjustments']?['zoom_adjustment']
                  as String? ??
              'none',
        ),
        poseAdjustments: (json['pose_adjustments'] as List?)
                ?.map((e) => e.toString())
                .toList() ??
            [],
        recommendedParams: RecommendedParams(
          focalLength: json['recommended_params']?['focal_length'] as String? ??
              '50mm',
          aperture:
              json['recommended_params']?['aperture'] as String? ?? 'f/2.8',
          exposureCompensation:
              json['recommended_params']?['exposure_compensation'] as String? ??
                  '0',
          iso: json['recommended_params']?['iso'] as int? ?? 100,
        ),
        sceneType: json['scene_type'] as String? ?? 'unknown',
        analyzedAt: DateTime.now(),
      );
    } catch (e) {
      return AnalysisResult(
        aestheticScore: 50.0,
        suggestions: [content],
        issues: [],
        cameraAdjustments: const CameraAdjustments(),
        poseAdjustments: [],
        recommendedParams: const RecommendedParams(),
        sceneType: 'unknown',
        analyzedAt: DateTime.now(),
      );
    }
  }

  ComparisonResult _parseComparisonResult(String content) {
    try {
      final jsonStr = _extractJson(content);
      final json = jsonDecode(jsonStr) as Map<String, dynamic>;

      return ComparisonResult(
        similarityScore:
            (json['similarity_score'] as num?)?.toDouble() ?? 0,
        compositionGap: CompositionGap(
          subjectPositionDiff:
              json['composition_gap']?['subject_position_diff'] as String? ??
                  '基本一致',
          angleDiff: json['composition_gap']?['angle_diff'] as String? ??
              '基本一致',
          distanceDiff: json['composition_gap']?['distance_diff'] as String? ??
              '基本一致',
        ),
        steps: (json['steps'] as List?)
                ?.map((e) => e.toString())
                .toList() ??
            [],
        currentAdjustment:
            json['current_adjustment'] as String? ?? '无法获取调整建议',
        comparedAt: DateTime.now(),
      );
    } catch (e) {
      return ComparisonResult(
        similarityScore: 0,
        compositionGap: const CompositionGap(),
        steps: [content],
        currentAdjustment: '无法解析比对结果',
        comparedAt: DateTime.now(),
      );
    }
  }

  String _extractJson(String content) {
    final regex = RegExp(r'\{[\s\S]*\}');
    final match = regex.firstMatch(content);
    if (match != null) {
      return match.group(0)!;
    }
    return content;
  }
}
