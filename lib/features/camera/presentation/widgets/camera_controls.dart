import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/camera_provider.dart';
import '../../domain/entities/camera_enums.dart' as app;

class CameraControls extends ConsumerWidget {
  const CameraControls({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cameraState = ref.watch(cameraProvider);
    final notifier = ref.read(cameraProvider.notifier);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildTopControls(context, cameraState, notifier),
          const SizedBox(height: 16),
          _buildBottomControls(context, cameraState, notifier),
        ],
      ),
    );
  }

  Widget _buildTopControls(
    BuildContext context,
    CameraState cameraState,
    CameraNotifier notifier,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _FlashButton(
          flashMode: cameraState.flashMode,
          onToggle: () {
            final modes = app.FlashMode.values;
            final currentIndex = modes.indexOf(cameraState.flashMode);
            final nextMode = modes[(currentIndex + 1) % modes.length];
            notifier.setFlashMode(nextMode);
          },
        ),
        _GridButton(
          gridType: cameraState.gridType,
          onToggle: () {
            final types = app.GridType.values;
            final currentIndex = types.indexOf(cameraState.gridType);
            final nextType = types[(currentIndex + 1) % types.length];
            notifier.setGridType(nextType);
          },
        ),
      ],
    );
  }

  Widget _buildBottomControls(
    BuildContext context,
    CameraState cameraState,
    CameraNotifier notifier,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _ControlButton(
          icon: Icons.flip_camera_ios,
          label: '翻转',
          onTap: () => notifier.switchCamera(),
        ),
        _ShutterButton(
          isCapturing: cameraState.viewState == CameraViewState.capturing,
          onTap: () => notifier.takePicture(),
        ),
        _ZoomControl(
          zoom: cameraState.zoom,
          onZoomChanged: (zoom) => notifier.setZoom(zoom),
        ),
      ],
    );
  }
}

class _FlashButton extends StatelessWidget {
  final app.FlashMode flashMode;
  final VoidCallback onToggle;

  const _FlashButton({required this.flashMode, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onToggle,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.black38,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          _flashIcon,
          color: Colors.white,
          size: 20,
        ),
      ),
    );
  }

  IconData get _flashIcon {
    switch (flashMode) {
      case app.FlashMode.auto:
        return Icons.flash_auto;
      case app.FlashMode.on:
        return Icons.flash_on;
      case app.FlashMode.off:
        return Icons.flash_off;
      case app.FlashMode.always:
        return Icons.highlight;
    }
  }
}

class _GridButton extends StatelessWidget {
  final app.GridType gridType;
  final VoidCallback onToggle;

  const _GridButton({required this.gridType, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onToggle,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: gridType != app.GridType.none
              ? const Color(0xFF1A73E8).withValues(alpha: 0.6)
              : Colors.black38,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(
          Icons.grid_on,
          color: Colors.white,
          size: 20,
        ),
      ),
    );
  }
}

class _ShutterButton extends StatelessWidget {
  final bool isCapturing;
  final VoidCallback onTap;

  const _ShutterButton({
    required this.isCapturing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isCapturing ? null : onTap,
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 4),
        ),
        child: Container(
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isCapturing ? Colors.grey : Colors.white,
          ),
        ),
      ),
    );
  }
}

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ControlButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.black38,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 10),
          ),
        ],
      ),
    );
  }
}

class _ZoomControl extends StatelessWidget {
  final double zoom;
  final ValueChanged<double> onZoomChanged;

  const _ZoomControl({
    required this.zoom,
    required this.onZoomChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.black38,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '${zoom.toStringAsFixed(1)}x',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          '变焦',
          style: TextStyle(color: Colors.white70, fontSize: 10),
        ),
      ],
    );
  }
}
