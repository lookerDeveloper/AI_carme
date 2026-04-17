class CameraFrame {
  final List<int> imageData;
  final int width;
  final int height;
  final DateTime timestamp;
  final CameraMetadata? metadata;

  const CameraFrame({
    required this.imageData,
    required this.width,
    required this.height,
    required this.timestamp,
    this.metadata,
  });
}

class CameraMetadata {
  final double? zoomLevel;
  final double? exposureOffset;
  final String? flashMode;
  final String? focusMode;
  final bool? isFrontCamera;

  const CameraMetadata({
    this.zoomLevel,
    this.exposureOffset,
    this.flashMode,
    this.focusMode,
    this.isFrontCamera,
  });
}
