import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:image/image.dart' as imageLib;
import 'recognition.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:tflite_flutter_helper/tflite_flutter_helper.dart';
import 'package:collection/collection.dart';

import 'stats.dart';

/// Classifier
class Classifier {
  /// Instance of Interpreter
  late Interpreter _interpreter;

  /// Labels file loaded as list
  late List<String> _labels;

  static const String MODEL_FILE_NAME = "best-fp16.tflite";
  static const String LABEL_FILE_NAME = "best-fp16.txt";

  /// Input size of image (height = width = 640)
  static const int INPUT_SIZE = 640;

  /// Result score threshold
  //static const double THRESHOLD = 0.5;

  /// Non-maximum suppression threshold
  static double mNmsThresh = 0.45;

  static const int clsNum = 2;
  static const double objConfTh = 0.25;
  static const double clsConfTh = 0.25;

  /// [ImageProcessor] used to pre-process the image
  late ImageProcessor imageProcessor;

  /// Padding the image to transform into square
  late int padSize;

  /// Shapes of output tensors
  late List<List<int>> _outputShapes;

  /// Types of output tensors
  late List<TfLiteType> _outputTypes;

  /// Number of results to show
  static const int NUM_RESULTS = 1001;

  Classifier({
    Interpreter? interpreter,
    List<String>? labels,
  }) {
    loadModel(interpreter: interpreter);
    loadLabels(labels: labels);
  }

  /// Loads interpreter from asset
  void loadModel({Interpreter? interpreter}) async {
    try {
      print("interpreter loading");
      _interpreter = interpreter ??
          await Interpreter.fromAsset(
            MODEL_FILE_NAME,
            options: InterpreterOptions()..threads = 4,
          );

      var outputTensors = _interpreter.getOutputTensors();
      print(outputTensors[0].data.buffer);
      _outputShapes = [];
      _outputTypes = [];
      for (var tensor in outputTensors) {
        _outputShapes.add(tensor.shape);
        _outputTypes.add(tensor.type);
      }
      print(_outputShapes[0]);
      print(_outputTypes);
    } catch (e) {
      print("Error while creating interpreter: $e");
    }
  }

  /// Loads labels from assets
  void loadLabels({List<String>? labels}) async {
    try {
      _labels = labels ?? await FileUtil.loadLabels("assets/$LABEL_FILE_NAME");
      print("labels ready");
      print(_labels);
    } catch (e) {
      print("Error while loading labels: $e");
    }
  }

  /// Pre-process the image
  TensorImage getProcessedImage(TensorImage inputImage) {
    padSize = max(inputImage.height, inputImage.width);
    print(padSize);
    imageProcessor = ImageProcessorBuilder()
        .add(ResizeWithCropOrPadOp(padSize, padSize))
        .add(ResizeOp(INPUT_SIZE, INPUT_SIZE, ResizeMethod.BILINEAR))
        //.add(NormalizeOp(0, 255))
        .build();
    inputImage = imageProcessor.process(inputImage);
    return inputImage;
  }

  // non-maximum suppression
  List<Recognition> nms(
      List<Recognition> list) // Turned from Java's ArrayList to Dart's List.
  {
    List<Recognition> nmsList = [];

    for (int k = 0; k < _labels.length; k++) {
      // 1.find max confidence per class
      PriorityQueue<Recognition> pq =
          HeapPriorityQueue<Recognition>((a, b) => b.score.compareTo(a.score));
      for (int i = 0; i < list.length; ++i) {
        if (list[i].label == _labels[k]) {
          // Changed from comparing #th class to class to string to string
          pq.add(list[i]);
        }
      }

      // 2.do non maximum suppression
      while (pq.length > 0) {
        // insert detection with max confidence
        List<Recognition> detections = pq.toList(); //In Java: pq.toArray(a)
        Recognition max = detections[0];
        nmsList.add(max);
        pq.clear();
        for (int j = 1; j < detections.length; j++) {
          Recognition detection = detections[j];
          Rect? b = detection.location;
          if (boxIou(max.location!, b!) < mNmsThresh) {
            pq.add(detection);
          }
        }
      }
    }

    return nmsList;
  }

  double boxIou(Rect a, Rect b) {
    return boxIntersection(a, b) / boxUnion(a, b);
  }

  double boxIntersection(Rect a, Rect b) {
    double w = overlap((a.left + a.right) / 2, a.right - a.left,
        (b.left + b.right) / 2, b.right - b.left);
    double h = overlap((a.top + a.bottom) / 2, a.bottom - a.top,
        (b.top + b.bottom) / 2, b.bottom - b.top);
    if ((w < 0) || (h < 0)) {
      return 0;
    }
    double area = (w * h);
    return area;
  }

  double boxUnion(Rect a, Rect b) {
    double i = boxIntersection(a, b);
    double u = ((((a.right - a.left) * (a.bottom - a.top)) +
            ((b.right - b.left) * (b.bottom - b.top))) -
        i);
    return u;
  }

  double overlap(double x1, double w1, double x2, double w2) {
    double l1 = (x1 - (w1 / 2));
    double l2 = (x2 - (w2 / 2));
    double left = ((l1 > l2) ? l1 : l2);
    double r1 = (x1 + (w1 / 2));
    double r2 = (x2 + (w2 / 2));
    double right = ((r1 < r2) ? r1 : r2);
    return right - left;
  }

  /// Runs object detection on the input image
  Map<String, dynamic>? predict(imageLib.Image image) {
    var predictStartTime = DateTime.now().millisecondsSinceEpoch;

    // if (_interpreter == null) {
    //   print("Interpreter not initialized");
    //   return null;
    // }

    // var preProcessStart = DateTime.now().millisecondsSinceEpoch;

    // // Initliazing TensorImage as the needed model input type
    // // of TfLiteType.float32. Then, creating TensorImage from image
    // TensorImage inputImage = TensorImage(TfLiteType.float32);
    // inputImage.loadImage(image);
    // TensorImage original = TensorImage(TfLiteType.float32);
    // original.loadImage(image);
    // // Do not use static methods, fromImage(Image) or fromFile(File),
    // // of TensorImage unless the desired input TfLiteDataType is Uint8.
    // // Create TensorImage from image

    // // Create TensorImage from image
    // //TensorImage inputImage = TensorImage.fromImage(image);

    // // Pre-process TensorImage
    // inputImage = getProcessedImage(inputImage);

    // var preProcessElapsedTime =
    //     DateTime.now().millisecondsSinceEpoch - preProcessStart;

    // // TensorBuffers for output tensors
    // TensorBuffer outputLocations = TensorBufferFloat(_outputShapes[0]);
    // // TensorBuffer outputClasses = TensorBufferFloat(_outputShapes[1]);
    // // TensorBuffer outputScores = TensorBufferFloat(_outputShapes[2]);
    // // TensorBuffer numLocations = TensorBufferFloat(_outputShapes[3]);

    // List<List<List<double>>> outputClassScores = List.generate(
    //     _outputShapes[1][0],
    //     (_) => List.generate(
    //         _outputShapes[1][1], (_) => List.filled(_outputShapes[1][2], 0.0),
    //         growable: false),
    //     growable: false);

    // // Inputs object for runForMultipleInputs
    // // Use [TensorImage.buffer] or [TensorBuffer.buffer] to pass by reference
    // List<Object> inputs = [inputImage.buffer];

    // // Outputs map
    // Map<int, Object> outputs = {
    //   0: outputLocations.buffer,
    //   1: outputClassScores,
    // };

    // var inferenceTimeStart = DateTime.now().millisecondsSinceEpoch;

    // print(inputs[0].runtimeType);
    // print(inputs[0].toString());

    // // run inference
    // _interpreter.runForMultipleInputs(inputs, outputs);

    // var inferenceTimeElapsed =
    //     DateTime.now().millisecondsSinceEpoch - inferenceTimeStart;

    // // Maximum number of results to show
    // //int resultsCount = min(NUM_RESULTS, numLocations.getIntValue(0));

    // // Using labelOffset = 1 as ??? at index 0
    // //int labelOffset = 1;

    // // Using bounding box utils for easy conversion of tensorbuffer to List<Rect>
    // List<Rect> locations = BoundingBoxUtils.convert(
    //   tensor: outputLocations,
    //   valueIndex: [1, 0, 3, 2],
    //   boundingBoxAxis: 2,
    //   boundingBoxType: BoundingBoxType.BOUNDARIES,
    //   coordinateType: CoordinateType.RATIO,
    //   height: INPUT_SIZE,
    //   width: INPUT_SIZE,
    // );

    // List<Recognition> recognitions = [];

    // var gridWidth = _outputShapes[0][1];
    // //print("gridWidth = $gridWidth");

    // for (int i = 0; i < gridWidth; i++) {
    //   // Since we are given a list of scores for each class for
    //   // each detected Object, we are interested in finding the class
    //   // with the highest output score

    //   var maxClassScore = 0.00;
    //   var labelIndex = -1;

    //   for (int c = 0; c < _labels.length; c++) {
    //     // output[0][i][c] is the confidence score of c class
    //     if (outputClassScores[0][i][c] > maxClassScore) {
    //       labelIndex = c;
    //       maxClassScore = outputClassScores[0][i][c];
    //     }
    //   }
    //   // Prediction score
    //   var score = maxClassScore;

    //   var label;
    //   if (labelIndex != -1) {
    //     // Label string
    //     label = _labels.elementAt(labelIndex);
    //   } else {
    //     label = null;
    //   }
    //   // Makes sure the confidence is above the
    //   // minimum threshold score for each object.
    //   if (score > THRESHOLD) {
    //     // inverse of rect
    //     // [locations] corresponds to the image size 300 X 300
    //     // inverseTransformRect transforms it our [inputImage]

    //     Rect rectAti = Rect.fromLTRB(
    //         max(0, locations[i].left),
    //         max(0, locations[i].top),
    //         min(INPUT_SIZE + 0.0, locations[i].right),
    //         min(INPUT_SIZE + 0.0, locations[i].bottom));

    //     // Gets the coordinates based on the original image if anything was done to it.
    //     Rect transformedRect = imageProcessor.inverseTransformRect(
    //         rectAti, image.height, image.width);

    //     recognitions.add(
    //       Recognition(i, label, score, transformedRect),
    //     );
    //   }
    // } // End of for loop and added all recognitions
    // List<Recognition> recognitionsNMS = nms(recognitions);
    // var predictElapsedTime =
    //     DateTime.now().millisecondsSinceEpoch - predictStartTime;

    // return {
    //   "recognitions": recognitionsNMS,
    //   "stats": Stats(
    //     totalPredictTime: predictElapsedTime,
    //     inferenceTime: inferenceTimeElapsed,
    //     preProcessingTime: preProcessElapsedTime,
    //     totalElapsedTime:
    //         predictElapsedTime + inferenceTimeElapsed + preProcessElapsedTime,
    //   )
    // };
    if (_interpreter == null) {
      return null;
    }
    var preProcessStart = DateTime.now().millisecondsSinceEpoch;

    var inputImage = TensorImage.fromImage(image);
    inputImage = getProcessedImage(inputImage);
    var preProcessElapsedTime =
        DateTime.now().millisecondsSinceEpoch - preProcessStart;

    ///  normalize from zero to one
    List<double> normalizedInputImage = [];
    for (var pixel in inputImage.tensorBuffer.getDoubleList()) {
      normalizedInputImage.add(pixel / 255.0);
    }
    var normalizedTensorBuffer = TensorBuffer.createDynamic(TfLiteType.float32);
    normalizedTensorBuffer
        .loadList(normalizedInputImage, shape: [INPUT_SIZE, INPUT_SIZE, 3]);

    final inputs = [normalizedTensorBuffer.buffer];

    /// tensor for results of inference
    final outputLocations = TensorBufferFloat(_outputShapes[0]);
    final outputs = {
      0: outputLocations.buffer,
    };

    var inferenceTimeStart = DateTime.now().millisecondsSinceEpoch;

    _interpreter.runForMultipleInputs(inputs, outputs);

    var inferenceTimeElapsed =
        DateTime.now().millisecondsSinceEpoch - inferenceTimeStart;

    /// make recognition
    final recognitions = <Recognition>[];
    List<double> results = outputLocations.getDoubleList();
    //print(results);
    for (var i = 0; i < results.length; i += (5 + clsNum)) {
      // check obj conf
      if (results[i + 4] < objConfTh) continue;
      //print(results[i + 4]);
      //print(i);

      /// check cls conf
      // double maxClsConf = results[i + 5];
      double score = results[i + 4];
      double maxClsConf = results.sublist(i + 4, i + 5 + clsNum).reduce(max);
      //print(maxClsConf);
      //print(i);
      if (maxClsConf < clsConfTh) continue;

      /// add detects
      // int cls = 0;
      int cls =
          results.sublist(i + 5, i + 5 + clsNum).indexOf(maxClsConf) % clsNum;
      //print(cls);
      Rect outputRect = Rect.fromCenter(
        center: Offset(
          results[i] * INPUT_SIZE,
          results[i + 1] * INPUT_SIZE,
        ),
        width: results[i + 2] * INPUT_SIZE,
        height: results[i + 3] * INPUT_SIZE,
      );

      Rect transformRect = imageProcessor.inverseTransformRect(
          outputRect, image.height, image.width);

      recognitions.add(Recognition(i, _labels[cls], score, transformRect));
    }
    var predictElapsedTime =
        DateTime.now().millisecondsSinceEpoch - predictStartTime;
    List<Recognition> recognitionsNMS = nms(recognitions);
    return {
      "recognitions": recognitionsNMS,
      "stats": Stats(
        totalPredictTime: predictElapsedTime,
        inferenceTime: inferenceTimeElapsed,
        preProcessingTime: preProcessElapsedTime,
        totalElapsedTime:
            predictElapsedTime + inferenceTimeElapsed + preProcessElapsedTime,
      )
    };
  }

  // for (int i = 0; i < resultsCount; i++) {
  //   // Prediction score
  //   var score = outputScores.getDoubleValue(i);

  //   // Label string
  //   var labelIndex = outputClasses.getIntValue(i) + labelOffset;
  //   var label = _labels.elementAt(labelIndex);

  //   if (score > THRESHOLD) {
  //     // inverse of rect
  //     // [locations] corresponds to the image size 300 X 300
  //     // inverseTransformRect transforms it our [inputImage]
  //     Rect transformedRect = imageProcessor.inverseTransformRect(
  //         locations[i], image.height, image.width);

  //     recognitions.add(
  //       Recognition(i, label, score, transformedRect),
  //     );
  //   }
  // }

  // var predictElapsedTime =
  //     DateTime.now().millisecondsSinceEpoch - predictStartTime;

  // return {
  //   "recognitions": recognitions,
  //   "stats": Stats(
  //     totalPredictTime: predictElapsedTime,
  //     inferenceTime: inferenceTimeElapsed,
  //     preProcessingTime: preProcessElapsedTime,
  //     totalElapsedTime:
  //         predictElapsedTime + inferenceTimeElapsed + preProcessElapsedTime,
  //   )
  // };
  // }

  /// Gets the interpreter instance
  Interpreter get interpreter => _interpreter;

  /// Gets the loaded labels
  List<String> get labels => _labels;
}
