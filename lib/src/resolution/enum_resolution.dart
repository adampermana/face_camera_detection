enum ImageResulotion {
  low,
  medium,
  height,
  veryHigh,
  ultraHigh,
  superUltraHigh,
  max,
}

enum CameraLens {
  front,
  back,
  external,
}

enum CameraFlashMode {
  off,
  auto,
  on,
  always,
}

enum CameraOrientation {
  portraitUp,
  landscapeLeft,
  portraitDown,
  landscapeRight,
}

enum IndicatorShape {
  defaultShape,
  square,
  circle,
  triangle,
  triangleInverted,

  /// Uses an asset image as face indicator
  image,

  /// Hide face indicator
  none
}
