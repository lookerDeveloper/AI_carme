class ComparisonResult {
  final double similarityScore;
  final CompositionGap compositionGap;
  final List<String> steps;
  final String currentAdjustment;
  final DateTime comparedAt;

  const ComparisonResult({
    required this.similarityScore,
    required this.compositionGap,
    required this.steps,
    required this.currentAdjustment,
    required this.comparedAt,
  });
}

class CompositionGap {
  final String subjectPositionDiff;
  final String angleDiff;
  final String distanceDiff;

  const CompositionGap({
    this.subjectPositionDiff = '基本一致',
    this.angleDiff = '基本一致',
    this.distanceDiff = '基本一致',
  });
}
