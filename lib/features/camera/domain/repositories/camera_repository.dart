import '../../domain/entities/camera_enums.dart';

abstract class CameraRepository {
  Future<void> initialize();
  Future<void> dispose();
  Stream get frameStream;
  Future<String> takePicture();
  Future<void> switchCamera();
  Future<void> setZoom(double zoom);
  Future<void> setFocusPoint(double x, double y);
  Future<void> setExposureOffset(double offset);
  Future<void> setFlashMode(FlashMode mode);
  CameraPosition get currentPosition;
  double get currentZoom;
}
