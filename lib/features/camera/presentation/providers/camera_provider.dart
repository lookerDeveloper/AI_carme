import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/camera_enums.dart';
import '../../domain/entities/camera_frame.dart';
import '../../data/services/camerawesome_service.dart';

class CameraState {
  final CameraPosition position;
  final CameraViewState viewState;
  final FlashMode flashMode;
  final GridType gridType;
  final double zoom;
  final CameraPosition cameraPosition;

  const CameraState({
    this.position = CameraPosition.back,
    this.viewState = CameraViewState.ready,
    this.flashMode = FlashMode.auto,
    this.gridType = GridType.none,
    this.zoom = 1.0,
    this.cameraPosition = CameraPosition.back,
  });

  CameraState copyWith({
    CameraPosition? position,
    CameraViewState? viewState,
    FlashMode? flashMode,
    GridType? gridType,
    double? zoom,
    CameraPosition? cameraPosition,
  }) {
    return CameraState(
      position: position ?? this.position,
      viewState: viewState ?? this.viewState,
      flashMode: flashMode ?? this.flashMode,
      gridType: gridType ?? this.gridType,
      zoom: zoom ?? this.zoom,
      cameraPosition: cameraPosition ?? this.cameraPosition,
    );
  }
}

class CameraNotifier extends StateNotifier<CameraState> {
  final CameraService _cameraService;

  CameraNotifier(this._cameraService) : super(const CameraState());

  Future<void> initialize() async {
    await _cameraService.initialize();
  }

  Future<void> takePicture() async {
    state = state.copyWith(viewState: CameraViewState.capturing);
    try {
      await _cameraService.takePicture();
      state = state.copyWith(viewState: CameraViewState.ready);
    } catch (e) {
      state = state.copyWith(viewState: CameraViewState.error);
    }
  }

  Future<void> switchCamera() async {
    await _cameraService.switchCamera();
    final newPosition = state.cameraPosition == CameraPosition.back
        ? CameraPosition.front
        : CameraPosition.back;
    state = state.copyWith(cameraPosition: newPosition);
  }

  Future<void> setZoom(double zoom) async {
    await _cameraService.setZoom(zoom);
    state = state.copyWith(zoom: zoom);
  }

  Future<void> setFocusPoint(double x, double y) async {
    await _cameraService.setFocusPoint(x, y);
  }

  Future<void> setFlashMode(FlashMode mode) async {
    await _cameraService.setFlashMode(mode);
    state = state.copyWith(flashMode: mode);
  }

  Future<void> setGridType(GridType type) async {
    state = state.copyWith(gridType: type);
  }

  @override
  void dispose() {
    _cameraService.dispose();
    super.dispose();
  }
}

final cameraServiceProvider = Provider<CameraService>((ref) {
  return CamerawesomeServiceImpl();
});

final cameraProvider =
    StateNotifierProvider<CameraNotifier, CameraState>((ref) {
  final cameraService = ref.watch(cameraServiceProvider);
  return CameraNotifier(cameraService);
});
