import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/camera_enums.dart';
import '../../domain/entities/camera_frame.dart';

abstract class CameraService {
  Future<void> initialize();
  Future<void> dispose();
  Stream<CameraFrame> get frameStream;
  Future<String> takePicture();
  Future<void> switchCamera();
  Future<void> setZoom(double zoom);
  Future<void> setFocusPoint(double x, double y);
  Future<void> setExposureOffset(double offset);
  Future<void> setFlashMode(FlashMode mode);
  CameraPosition get currentPosition;
  double get currentZoom;
}

class CamerawesomeServiceImpl implements CameraService {
  final _frameController = StreamController<CameraFrame>.broadcast();
  final _uuid = const Uuid();

  CameraPosition _currentPosition = CameraPosition.back;
  double _currentZoom = 1.0;
  double _currentExposureOffset = 0.0;
  bool _isInitialized = false;

  @override
  Stream<CameraFrame> get frameStream => _frameController.stream;

  @override
  CameraPosition get currentPosition => _currentPosition;

  @override
  double get currentZoom => _currentZoom;

  @override
  Future<void> initialize() async {
    if (_isInitialized) return;
    _isInitialized = true;
  }

  @override
  Future<void> dispose() async {
    await _frameController.close();
    _isInitialized = false;
  }

  @override
  Future<String> takePicture() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final picturesDir = Directory('${directory.path}/Pictures/AICam');
      if (!await picturesDir.exists()) {
        await picturesDir.create(recursive: true);
      }

      final fileName = '${_uuid.v4()}.jpg';
      final filePath = '${picturesDir.path}/$fileName';

      return filePath;
    } catch (e) {
      throw Exception('拍照失败: $e');
    }
  }

  @override
  Future<void> switchCamera() async {
    _currentPosition = _currentPosition == CameraPosition.back
        ? CameraPosition.front
        : CameraPosition.back;
  }

  @override
  Future<void> setZoom(double zoom) async {
    _currentZoom = zoom.clamp(1.0, 10.0);
  }

  @override
  Future<void> setFocusPoint(double x, double y) async {
  }

  @override
  Future<void> setExposureOffset(double offset) async {
    _currentExposureOffset = offset.clamp(-3.0, 3.0);
  }

  @override
  Future<void> setFlashMode(FlashMode mode) async {
  }

  void onFrameReceived(Uint8List imageData, int width, int height) {
    if (_frameController.isClosed) return;
    _frameController.add(CameraFrame(
      imageData: imageData,
      width: width,
      height: height,
      timestamp: DateTime.now(),
      metadata: CameraMetadata(
        zoomLevel: _currentZoom,
        isFrontCamera: _currentPosition == CameraPosition.front,
      ),
    ));
  }
}
