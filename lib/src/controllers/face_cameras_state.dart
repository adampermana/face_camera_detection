// Hapus import 'dart:html';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../models/detection_image.dart';
import '../resolution/enum_resolution.dart'; // Jika diperlukan

part 'face_cameras_state.freezed.dart';

@Freezed(
  toJson: false,
  fromJson: false,
)
class FaceCamerasState with _$FaceCamerasState {
  const factory FaceCamerasState({
    required CameraController? cameraController,
    required DetectedFace? detectedFace,
    required List<CameraLens> availableCameraLens,
    required List<CameraFlashMode> availableFlashMode,
    required int currentCameraLens,
    required int currentFlashMode,
    required bool isInitialized,
    required bool alreadyCheckingImage,
    required bool? isRunning,
    required double? zoomScale,

    // required List<CameraFlashMode> availableFlashMode,
  }) = _FaceCamerasState;

  factory FaceCamerasState.uninitialized() => const FaceCamerasState(
        cameraController: null,
        detectedFace: null,
        availableCameraLens: [],
        availableFlashMode: [],
        currentCameraLens: 0,
        currentFlashMode: 0,
        isInitialized: false,
        isRunning: false,
        alreadyCheckingImage: false,
        zoomScale: null,
      );
}
