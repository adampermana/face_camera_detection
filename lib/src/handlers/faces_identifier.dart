import 'dart:io';

import 'package:camera/camera.dart';
import 'package:face_camera_detector/face_camera_detector.dart';
import 'package:face_camera_detector/src/models/detection_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

class FacesIdentifier {
  static Future<DetectedFace?> scanImage({
    required CameraImage cameraImage,
    required CameraController? cameraController,
    // required FaceCameraDetector? faceCameraDetector,
    required FaceDetectorMode faceCameraDetector,
  }) async {
    final orientation = {
      DeviceOrientation.portraitUp: 0,
      DeviceOrientation.landscapeLeft: 90,
      DeviceOrientation.portraitDown: 180,
      DeviceOrientation.landscapeRight: 270,
    };

    DetectedFace? result;
    final face = await _detectFace(
        visionImage: _inputImageFromCameraImage(
            cameraImage, cameraController, orientation),
        performanceMode: faceCameraDetector);
  }

  static InputImage? _inputImageFromCameraImage(
      CameraImage cameraImage,
      CameraController? cameraController,
      Map<DeviceOrientation, int> orientations) {
    final camera = cameraController!.description;
    final sensorOrientation = camera.sensorOrientation;
    InputImageRotation? rotation;

    if (Platform.isIOS) {
      rotation = InputImageRotationValue.fromRawValue(sensorOrientation);
    } else if (Platform.isAndroid) {
      var rotationCompensation =
          orientations[cameraController.value.deviceOrientation];
      if (rotationCompensation == null) {
        return null;
      }
      if (camera.lensDirection == CameraLensDirection.front) {
        rotationCompensation = (sensorOrientation + rotationCompensation) % 360;
      } else {
        rotationCompensation =
            (sensorOrientation - rotationCompensation + 360) % 360;
      }
      rotation = InputImageRotationValue.fromRawValue(rotationCompensation);
    }
    if (rotation == null) {
      return null;
    }

    final format = InputImageFormatValue.fromRawValue(cameraImage.format.raw);

    if (format == null ||
        (Platform.isIOS && format != InputImageFormat.bgra8888)) {
      return null;
    }

    if (cameraImage.planes.isEmpty) {
      return null;
    }
    return InputImage.fromBytes(
      bytes: Uint8List.fromList(
        cameraImage.planes.fold(
            <int>[],
            (List<int> previousValue, element) =>
                previousValue..addAll(element.bytes)),
      ),
      metadata: InputImageMetadata(
        size: Size(cameraImage.width.toDouble(), cameraImage.height.toDouble()),
        rotation: rotation, // used only in Android
        format: format, // used only in iOS
        bytesPerRow: cameraImage.planes.first.bytesPerRow, // used only in iOS
      ),
    );
  }

  static Future<DetectedFace?> _detectFace(
      {required InputImage? visionImage,
      required FaceDetectorMode performanceMode}) async {
    if (visionImage == null) return null;
    final options = FaceDetectorOptions(
        enableLandmarks: true,
        enableTracking: true,
        performanceMode: performanceMode);
    final faceDetector = FaceDetector(options: options);
    try {
      final List<Face> faces = await faceDetector.processImage(visionImage);
      final faceDetect = _extractFace(faces);
      return faceDetect;
    } catch (error) {
      debugPrint(error.toString());
      return null;
    }
  }

  static _extractFace(List<Face> faces) {
    //List<Rect> rect = [];
    bool wellPositioned = faces.isNotEmpty;
    Face? detectedFace;

    for (Face face in faces) {
      // rect.add(face.boundingBox);
      detectedFace = face;

      // Head is rotated to the right rotY degrees
      if (face.headEulerAngleY! > 2 || face.headEulerAngleY! < -2) {
        wellPositioned = false;
      }

      // Head is tilted sideways rotZ degrees
      if (face.headEulerAngleZ! > 2 || face.headEulerAngleZ! < -2) {
        wellPositioned = false;
      }

      // If landmark detection was enabled with FaceDetectorOptions (mouth, ears,
      // eyes, cheeks, and nose available):
      final FaceLandmark? leftEar = face.landmarks[FaceLandmarkType.leftEar];
      final FaceLandmark? rightEar = face.landmarks[FaceLandmarkType.rightEar];
      final FaceLandmark? bottomMouth =
          face.landmarks[FaceLandmarkType.bottomMouth];
      final FaceLandmark? rightMouth =
          face.landmarks[FaceLandmarkType.rightMouth];
      final FaceLandmark? leftMouth =
          face.landmarks[FaceLandmarkType.leftMouth];
      final FaceLandmark? noseBase = face.landmarks[FaceLandmarkType.noseBase];
      if (leftEar == null ||
          rightEar == null ||
          bottomMouth == null ||
          rightMouth == null ||
          leftMouth == null ||
          noseBase == null) {
        wellPositioned = false;
      }

      if (face.leftEyeOpenProbability != null) {
        if (face.leftEyeOpenProbability! < 0.5) {
          wellPositioned = false;
        }
      }

      if (face.rightEyeOpenProbability != null) {
        if (face.rightEyeOpenProbability! < 0.5) {
          wellPositioned = false;
        }
      }
    }

    return DetectedFace(wellPositioned: wellPositioned, face: detectedFace);
  }
}
