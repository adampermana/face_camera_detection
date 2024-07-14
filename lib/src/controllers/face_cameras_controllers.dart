import 'dart:io';
import 'package:camera/camera.dart';
import 'package:face_camera_detector/face_camera_detector.dart';
import 'package:face_camera_detector/src/controllers/face_cameras_state.dart';
import 'package:face_camera_detector/src/handlers/enum_handler.dart';
import 'package:face_camera_detector/src/log/logger.dart';
import 'package:face_camera_detector/src/resolution/enum_resolution.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

import '../handlers/faces_identifier.dart';

class FaceCamerasControllers extends ValueNotifier<FaceCamerasState> {
  /// The desired resolution for the camera.
  final ImageResolution imageResolution;

  /// Use this to set initial camera lens direction.
  final CameraLens? defaultCameraLens;

  /// Use this to set initial flash mode.
  final CameraFlashMode defaultFlashMode;

  /// Set false to disable capture sound.
  final bool enableAudio;

  /// Set true to capture image on face detected.
  final bool autoCapture;

  /// Use this to lock camera orientation.
  final CameraOrientation? orientation;

  /// Use this to set your preferred performance mode.
  final FaceDetectorMode faceCameraDetector;

  /// Callback invoked when camera captures image.
  final void Function(File? image) onCapture;

  /// Callback invoked when camera detects face.
  final void Function(Face? face)? onFaceDetected;

  FaceCamerasControllers(
      this.imageResolution,
      this.defaultCameraLens,
      this.defaultFlashMode,
      this.enableAudio,
      this.autoCapture,
      this.orientation,
      this.faceCameraDetector,
      this.onCapture,
      this.onFaceDetected)
      : super(FaceCamerasState.uninitialized());

  /// Gets all available camera lens and set current len
  Future<void> _getAllAvailableCameraLens() async {
    int currentCameraLens = 0;
    final List<CameraLens> availableCameraLens = [];
    for (CameraDescription a in FaceCameraDetector.cameras) {
      final lensa =
          EnumHandler.camerasLensDirectionToCameraLens(a.lensDirection);
      if (lensa != null && !availableCameraLens.contains(lensa)) {
        availableCameraLens.add(lensa);
      }
    }
    if (defaultCameraLens != null) {
      try {
        currentCameraLens = availableCameraLens.indexOf(defaultCameraLens!);
      } catch (e) {
        logError(e.toString());
      }
    }

    value = value.copyWith(
        availableCameraLens: availableCameraLens,
        currentCameraLens: currentCameraLens);
  }

  Future<void> _initCamera() async {
    final cameras = FaceCameraDetector.cameras
        .where((cameras) =>
            cameras.lensDirection ==
            EnumHandler.camerasLensToCameraLensDirection(
                value.availableCameraLens[value.currentCameraLens]))
        .toList();

    if (cameras.isNotEmpty) {
      final camerasController = CameraController(cameras.first,
          EnumHandler.imageResolutionToResolutionPreset(imageResolution),
          enableAudio: enableAudio,
          imageFormatGroup: Platform.isAndroid
              ? ImageFormatGroup.nv21
              : ImageFormatGroup.bgra8888);

      await camerasController.initialize().whenComplete(() => value = value
          .copyWith(isInitialized: true, cameraController: camerasController));

      await _changeFlashMode(
          value.availableFlashMode.indexOf(defaultFlashMode));

      await camerasController
          .lockCaptureOrientation(EnumHandler.deviceOrientation(orientation!));
    }
  }

  Future<void> _changeFlashMode([int? index]) async {
    final newIndex = index ??
        (value.currentFlashMode + 1) % value.availableCameraLens.length;
    await value.cameraController!
        .setFlashMode(EnumHandler.flashMode(value.availableFlashMode[newIndex]))
        .then((_) => value = value.copyWith(currentFlashMode: newIndex));
  }

  Future<void> _changeCameraLens() async {
    value = value.copyWith(
        currentCameraLens:
            (value.currentCameraLens + 1) % value.availableCameraLens.length);
    _initCamera();
  }

  Future<XFile?> takePicture() async {
    final CameraController? cameraController = value.cameraController;

    if (cameraController == null || !cameraController.value.isInitialized) {
      logError('A capture is already pending');
      print('A capture is already pending');
      return null;
    }

    try {
      XFile file = await cameraController.takePicture();
      return file;
    } on CameraException catch (e) {
      __showCameraException(e);
    }
  }

  void __showCameraException(CameraException cameraException) {
    logError(cameraException.code, cameraException.description);
  }

  Future<void> startImageStream() async {
    final CameraController? cameraController = value.cameraController;
    if (cameraController == null || !cameraController.value.isInitialized) {
      return;
    }
    if (!cameraController.value.isStreamingImages) {
      await cameraController.startImageStream(_processImage);
    }
  }

  Future<void> stopImageStram() async {
    final CameraController? cameraController = value.cameraController;
    if (cameraController == null || !cameraController.value.isInitialized) {
      return;
    }
    if (cameraController.value.isStreamingImages) {
      await cameraController.stopImageStream();
    }
  }

  void _processImage(CameraImage cameraImage) async {
    final CameraController? cameraController = value.cameraController;
    if (!value.alreadyCheckingImage) {
      value = value.copyWith(alreadyCheckingImage: true);
      try {
        await FacesIdentifier.scanImage(
                cameraImage: cameraImage,
                cameraController: cameraController,
                faceCameraDetector: faceCameraDetector)
            .then((result) async {
          value = value.copyWith(detectedFace: result);

          if (result != null) {
            try {
              if (result.wellPositioned) {
                onFaceDetected?.call(result.face);
                if (autoCapture) {
                  onTakePictureButtonPressed();
                }
              }
            } catch (e) {
              logError(e.toString());
            }
          }
        });
        value = value.copyWith(alreadyCheckingImage: false);
      } catch (ex, stack) {
        value = value.copyWith(alreadyCheckingImage: false);
        logError('$ex, $stack');
      }
    }
  }

  void onTakePictureButtonPressed() async {
    final CameraController? cameraController = value.cameraController;
    try {
      cameraController!.stopImageStream().whenComplete(() async {
        await Future.delayed(const Duration(milliseconds: 500));
        takePicture().then((XFile? file) {
          if (file != null) {
            onCapture.call(File(file.path));
          }
        });
      });
    } catch (e) {
      logError(e.toString());
    }
  }

  Future<void> initialize() async {
    _getAllAvailableCameraLens();
    _initCamera();
  }

  bool get enableControls {
    final CameraController? cameraController = value.cameraController;
    return cameraController != null && cameraController.value.isInitialized;
  }

  @override
  Future<void> dispose() async {
    final CameraController? cameraController = value.cameraController;

    if (cameraController != null && cameraController.value.isInitialized) {
      cameraController.dispose();
    }
    super.dispose();
  }
}
