import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter_application_1/presentation/widgets/camera_view_singleton.dart';
import 'package:tflite_flutter_helper/tflite_flutter_helper.dart';

/// Represents the recognition output from the model

class Recognition {
  /// Index of the result
  final int _id;

  /// Label of the result
  final String _label;

  /// Confidence [0.0, 1.0]
  final double _score;

  /// Location of bounding box rect
  ///
  /// The rectangle corresponds to the raw input image
  /// passed for inference
  final Rect? _location;

  Recognition(this._id, this._label, this._score, [this._location]);

  int get id => _id;

  String get label => _label;

  double get score => _score;

  Rect? get location => _location;

  /// Returns bounding box rectangle corresponding to the
  /// displayed image on screen
  ///
  /// This is the actual location where rectangle is rendered on
  /// the screen
  // Rect get renderLocation {
  //   // ratioX = screenWidth / imageInputWidth
  //   // ratioY = ratioX if image fits screenWidth with aspectRatio = constant

  //   double? ratioX = CameraViewSingleton.ratio;
  //   double? ratioY = ratioX;

  //   double transLeft = max(0.1, location!.left * ratioX!);
  //   double transTop = max(0.1, location!.top * ratioY!);
  //   double transWidth = min(
  //       location!.width * ratioX, CameraViewSingleton.actualPreviewSize!.width);
  //   double transHeight = min(location!.height * ratioY,
  //       CameraViewSingleton.actualPreviewSize.height);

  //   Rect transformedRect =
  //       Rect.fromLTWH(transLeft, transTop, transWidth, transHeight);
  //   return transformedRect;
  // }

  Rect getRenderLocation(Size actualPreviewSize, double pixelRatio) {
    final ratioX = pixelRatio;
    // final ratioY = actualPreviewSize.height / actualPreviewSize.width * ratioX;
    final ratioY = ratioX;
    final gain = min(
        CameraViewSingleton.inputImageSize.width / actualPreviewSize.width,
        CameraViewSingleton.inputImageSize.height / actualPreviewSize.height);
    //final pad = (CameraViewSingleton.inputImageSize.width - actualPreviewSize.width * gain) / 2, (CameraViewSingleton.inputImageSize.height - actualPreviewSize.height * gain) / 2
    final transLeft = max(0.1, location!.left * ratioX);
    final transTop = max(0.1, location!.top * ratioY);
    final transWidth = location!.width / gain;

    final transHeight = location!.height / gain;

    final transformedRect =
        Rect.fromLTWH(transLeft, transTop, transWidth, transHeight);
    // final transformedRect = Rect.fromLTWH(
    //     location!.left, location!.top, location!.width, location!.height);
    return transformedRect;
  }

  @override
  String toString() {
    return 'Recognition(id: $id, label: $label, score: ${(score * 100).toStringAsPrecision(3)}, location: $location)';
  }
}
