class CameraParams {
  final double focalLength;
  final double aperture;
  final double shutterSpeed;
  final int iso;
  final double exposureBias;
  final String whiteBalance;
  final String focusMode;

  const CameraParams({
    this.focalLength = 26.0,
    this.aperture = 1.8,
    this.shutterSpeed = 0.008,
    this.iso = 100,
    this.exposureBias = 0.0,
    this.whiteBalance = 'auto',
    this.focusMode = 'auto',
  });

  String get shutterSpeedDisplay {
    if (shutterSpeed >= 1) return '${shutterSpeed.round()}s';
    if (shutterSpeed >= 0.001) return '1/${(1 / shutterSpeed).round()}s';
    return '1/${(1 / shutterSpeed).round()}s';
  }

  String get focalLengthDisplay => '${focalLength.round()}mm';
  String get apertureDisplay => 'f/${aperture.toStringAsFixed(1)}';
  String get isoDisplay => 'ISO$iso';
}
