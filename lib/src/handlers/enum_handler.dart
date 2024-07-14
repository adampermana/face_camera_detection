import 'package:camera/camera.dart';
import 'package:face_camera_detector/src/resolution/enum_resolution.dart';
import 'package:flutter/services.dart';

class EnumHandler {
  static ResolutionPreset imageResolutionToResolutionPreset(
      ImageResolution imageResolution) {
    switch (imageResolution) {
      case ImageResolution.low:
        return ResolutionPreset.low;
      case ImageResolution.medium:
        return ResolutionPreset.medium;
      case ImageResolution.height:
        return ResolutionPreset.high;
      case ImageResolution.veryHigh:
        return ResolutionPreset.veryHigh;
      case ImageResolution.ultraHigh:
        return ResolutionPreset.ultraHigh;
      case ImageResolution.superUltraHigh:
        return ResolutionPreset.ultraHigh;
      case ImageResolution.max:
        return ResolutionPreset.max;
    }
  }

  static CameraLensDirection? camerasLensToCameraLensDirection(
      CameraLens? cameraLens) {
    switch (cameraLens) {
      case CameraLens.back:
        return CameraLensDirection.back;
      case CameraLens.front:
        return CameraLensDirection.front;
      case CameraLens.external:
        return CameraLensDirection.external;
      default:
        return null;
    }
  }

  static CameraLens? camerasLensDirectionToCameraLens(
      CameraLensDirection? cameraLens) {
    switch (cameraLens) {
      case CameraLensDirection.back:
        return CameraLens.back;
      case CameraLensDirection.front:
        return CameraLens.front;
      case CameraLensDirection.external:
        return CameraLens.external;
      default:
        return null;
    }
  }

  static FlashMode flashMode(CameraFlashMode cameraFlashMode) {
    switch (cameraFlashMode) {
      case CameraFlashMode.off:
        return FlashMode.off;
      case CameraFlashMode.always:
        return FlashMode.always;
      case CameraFlashMode.auto:
        return FlashMode.auto;
      case CameraFlashMode.on:
        return FlashMode.auto;
    }
  }

  static DeviceOrientation? deviceOrientation(
      CameraOrientation cameraOrientation) {
    switch (cameraOrientation) {
      case CameraOrientation.portraitUp:
        return DeviceOrientation.portraitUp;
      case CameraOrientation.portraitDown:
        return DeviceOrientation.portraitDown;
      case CameraOrientation.landscapeLeft:
        return DeviceOrientation.landscapeLeft;
      case CameraOrientation.landscapeRight:
        return DeviceOrientation.landscapeRight;
      default:
        return null;
    }
  }
}
