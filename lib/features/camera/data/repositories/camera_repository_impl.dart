import '../../domain/entities/camera_enums.dart';
import '../../domain/repositories/camera_repository.dart';
import '../services/camerawesome_service.dart';

class CameraRepositoryImpl implements CameraRepository {
  final CameraService _cameraService;

  CameraRepositoryImpl(this._cameraService);

  @override
  Future<void> initialize() => _cameraService.initialize();

  @override
  Future<void> dispose() => _cameraService.dispose();

  @override
  Stream get frameStream => _cameraService.frameStream;

  @override
  Future<String> takePicture() => _cameraService.takePicture();

  @override
  Future<void> switchCamera() => _cameraService.switchCamera();

  @override
  Future<void> setZoom(double zoom) => _cameraService.setZoom(zoom);

  @override
  Future<void> setFocusPoint(double x, double y) =>
      _cameraService.setFocusPoint(x, y);

  @override
  Future<void> setExposureOffset(double offset) =>
      _cameraService.setExposureOffset(offset);

  @override
  Future<void> setFlashMode(FlashMode mode) =>
      _cameraService.setFlashMode(mode);

  @override
  CameraPosition get currentPosition => _cameraService.currentPosition;

  @override
  double get currentZoom => _cameraService.currentZoom;
}
