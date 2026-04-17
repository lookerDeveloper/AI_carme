class AnalysisResult {
  final double aestheticScore;
  final List<String> suggestions;
  final List<CompositionIssue> issues;
  final CameraAdjustments cameraAdjustments;
  final List<String> poseAdjustments;
  final RecommendedParams recommendedParams;
  final String sceneType;
  final DateTime analyzedAt;

  const AnalysisResult({
    required this.aestheticScore,
    required this.suggestions,
    required this.issues,
    required this.cameraAdjustments,
    required this.poseAdjustments,
    required this.recommendedParams,
    required this.sceneType,
    required this.analyzedAt,
  });
}

class CompositionIssue {
  final String description;
  final String severity;
  final String category;

  const CompositionIssue({
    required this.description,
    required this.severity,
    required this.category,
  });
}

class CameraAdjustments {
  final String moveDirection;
  final String moveAmount;
  final String tiltAdjustment;
  final String zoomAdjustment;

  const CameraAdjustments({
    this.moveDirection = 'none',
    this.moveAmount = 'none',
    this.tiltAdjustment = 'level',
    this.zoomAdjustment = 'none',
  });
}

class RecommendedParams {
  final String focalLength;
  final String aperture;
  final String exposureCompensation;
  final int iso;

  const RecommendedParams({
    this.focalLength = '50mm',
    this.aperture = 'f/2.8',
    this.exposureCompensation = '0',
    this.iso = 100,
  });
}
