import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/dbhandler/data_source/remote/firestoreRef.dart';
import 'package:flutter_application_1/presentation/widgets/camera_view_singleton.dart';
//import 'package:flutter_application_1/dbhandler/data_source/remote/mongo.dart';
//import 'package:flutter_application_1/presentation/widgets/bounding_box.dart';
//import 'package:flutter_application_1/presentation/widgets/camera_view_singleton.dart';
import 'package:flutter_application_1/tflite/recognition.dart';
import 'package:flutter_application_1/tflite/stats.dart';
//import 'package:percent_indicator/percent_indicator.dart';
import '../details.dart';
import 'package:image/image.dart' as img;

class Home extends StatefulWidget {
  //final name;
  //final percent;

  List<Recognition> results;
  late Stats? stats;
  File? path = null;

  Home({super.key, required this.results, this.stats, this.path});
  //Home({Key? key}) : super(key: key);
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  double _currentThres = 0.25;
  @override
  void initState() {
    //initS is the first function that is executed by default when this class is called
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: FirestoreSourceImpl.getDataByLabels(widget.results),
        //future: MongoDatabase.getDataByName(widget.name),
        builder: (BuildContext context, AsyncSnapshot snapshot) {
          List data = snapshot.data ?? [];
          //print(data);

          if (data.isEmpty) {
            data = [
              {
                "name": "Hãy chọn 1 ảnh",
                "img64":
                    "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"
              }
            ];
          }

          List<Widget> stackChildren = [];

          Size size = MediaQuery.of(context).size;

          return Scaffold(
              appBar: AppBar(
                //linear color gradient
                backgroundColor: const Color(0xFF29D890),
                title: const Text(
                  'Nhận diện cây thuốc nam',
                  style: TextStyle(
                      color: Colors.white, fontSize: 20, letterSpacing: 0.8),
                ),
              ),
              body: SingleChildScrollView(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 50, bottom: 80),
                    child: //Container(
                        // width: MediaQuery.of(context).size.width,
                        //child:
                        Column(children: <Widget>[
                      // Padding(
                      //   padding: EdgeInsets.only(top:16.0),
                      // ),
                      Text(
                        widget.path == null ? data[0]['name'] : 'Kết quả',
                        style: const TextStyle(fontSize: 20),
                      ),
                      const Padding(
                        padding: EdgeInsets.only(top: 16.0),
                      ),
                      // Stack(
                      //   children: [
                      //     Positioned(
                      //       left: 0.0,
                      //       top: 0.0,
                      //       width: size.width,
                      //       child: widget.path == null
                      //           ? Image.memory(base64Decode(data[0]['img64']
                      //               .replaceAll(RegExp(r'\s+'), '')))
                      //           : Image.memory(
                      //               base64Decode(
                      //                   base64Encode(widget.path!.readAsBytesSync())
                      //                       .replaceAll(RegExp(r'\s+'), '')),
                      //             ),
                      //     ),
                      //   ],
                      // ),
                      Stack(
                        children: [
                          Positioned(
                            child: Container(
                              width: size.width,
                              // decoration: BoxDecoration(
                              //   image: DecorationImage(
                              //     image: widget.path == null
                              //         ? Image.memory(base64Decode(data[0]['img64']
                              //                 .replaceAll(RegExp(r'\s+'), '')))
                              //             .image
                              //         : Image.memory(
                              //             base64Decode(
                              //                 base64Encode(widget.path!.readAsBytesSync())
                              //                     .replaceAll(RegExp(r'\s+'), '')),
                              //           ).image,
                              //     fit: BoxFit.contain,
                              //   ),
                              // ),
                              child: widget.path == null
                                  ? Image.memory(base64Decode(data[0]['img64']
                                      .replaceAll(RegExp(r'\s+'), '')))
                                  : Image.memory(
                                      base64Decode(base64Encode(
                                              widget.path!.readAsBytesSync())
                                          .replaceAll(RegExp(r'\s+'), '')),
                                    ),
                              // child: buildBoxes(
                              //     widget.results,
                              //     CameraViewSingleton.actualPreviewSize,
                              //     CameraViewSingleton.ratio),
                            ),
                          ),
                          ...buildBoxes(widget.results
                              .where(
                                  (element) => element.score >= _currentThres)
                              .toList()),
                        ],
                      ),
                      // const Padding(
                      //   padding: EdgeInsets.only(top: 16.0),
                      // ),
                      // //add button to see details
                      // const Padding(
                      //   padding: EdgeInsets.only(top: 16.0),
                      // ),
                      // Slider(
                      //   value: _currentThres,
                      //   max: 1,
                      //   min: 0.25,
                      //   divisions: 75,
                      //   label: _currentThres.toString(),
                      //   onChanged: (double value) {
                      //     setState(() {
                      //       _currentThres = value;
                      //     });
                      //   },
                      // ),
                      //],
                      //),
                      // CircularPercentIndicator(
                      //   radius: 110.0,
                      //   lineWidth: 10.0,
                      //   animation: true,
                      //   percent: widget.percent,
                      //   center: CircleAvatar(
                      //     backgroundImage: Image.memory(base64Decode(
                      //             data[0]['img64'].replaceAll(RegExp(r'\s+'), '')))
                      //         .image,
                      //     radius: 100.0,
                      //   ),
                      //   progressColor: Colors.green,
                      // ),
                      const Padding(
                        padding: EdgeInsets.only(top: 16.0),
                      ),
                      //add button to see details
                      const Padding(
                        padding: EdgeInsets.only(top: 16.0),
                      ),
                      Column(
                        children: data[0]['name'] == "Hãy chọn 1 ảnh"
                            ? []
                            : data
                                .map((e) => Row(
                                      children: [
                                        const Padding(
                                          padding: EdgeInsets.symmetric(
                                              horizontal: 16.0),
                                        ),
                                        Text(
                                          e['name'],
                                          style: const TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold),
                                        ),
                                        const Padding(
                                          padding: EdgeInsets.symmetric(
                                              horizontal: 16.0),
                                        ),
                                        ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  const Color(0xFF29D890)),
                                          onPressed: data[0]['name'] ==
                                                  "Hãy chọn 1 ảnh"
                                              ? () {}
                                              : () {
                                                  Navigator.push(
                                                      context,
                                                      MaterialPageRoute(
                                                          builder: (context) =>
                                                              Details(
                                                                  item: e)));
                                                },
                                          child: const Text(
                                            'Xem chi tiết',
                                            style: TextStyle(
                                                fontSize: 20,
                                                color: Colors.white),
                                          ),
                                        ),
                                      ],
                                    ))
                                .toList(),
                      ),
                    ]),
                    //),
                  ),
                ),
              ));
        }); //end return
  }

  // Widget boundingBoxes(List<Recognition> results) {
  //   CameraViewSingleton.inputImageSize = Size(_imageWidth, _imageHeight);
  //   Size screenSize = MediaQuery.of(context).size;
  //   CameraViewSingleton.screenSize = screenSize;
  //   CameraViewSingleton.ratio = screenSize.width / _imageHeight!;
  //   if (results == null) {
  //     return Container();
  //   }
  //   return Stack(
  //     children: results
  //         .map((e) => BoxWidget(
  //               result: e,
  //             ))
  //         .toList(),
  //   );
  // }
  List<Widget> buildBoxes(
    List<Recognition> recognitions,
  ) {
    if (recognitions.isEmpty) {
      return const [SizedBox()];
    }
    return recognitions.map((result) {
      return BoundingBox(
        result: result,
        actualPreviewSize: CameraViewSingleton.actualPreviewSize,
        ratio: CameraViewSingleton.ratio,
      );
    }).toList();
  }
}

class BoundingBox extends StatelessWidget {
  const BoundingBox({
    Key? key,
    required this.result,
    required this.actualPreviewSize,
    required this.ratio,
  }) : super(key: key);
  final Recognition result;
  final Size actualPreviewSize;
  final double ratio;
  @override
  Widget build(BuildContext context) {
    final renderLocation = result.getRenderLocation(
      actualPreviewSize,
      ratio,
    );
    return Positioned(
      left: renderLocation.left,
      top: renderLocation.top,
      width: renderLocation.width,
      height: renderLocation.height,
      child: Container(
        width: renderLocation.width,
        height: renderLocation.height,
        decoration: BoxDecoration(
          border: Border.all(
            color: Colors.cyan,
            width: 1,
          ),
          borderRadius: const BorderRadius.all(
            Radius.circular(2),
          ),
        ),
        child: buildBoxLabel(result, context),
      ),
    );
  }

  Align buildBoxLabel(Recognition result, BuildContext context) {
    return Align(
      alignment: Alignment.topLeft,
      child: FittedBox(
        child: ColoredBox(
          color: Colors.blue,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                result.label,
              ),
              Text(
                ' ${result.score.toStringAsFixed(2)}',
              ),
            ],
          ),
        ),
      ),
    );
  }

  //static const BOTTOM_SHEET_RADIUS = Radius.circular(24.0);
  //static const BORDER_RADIUS_BOTTOM_SHEET = BorderRadius.only(
  //topLeft: BOTTOM_SHEET_RADIUS, topRight: BOTTOM_SHEET_RADIUS);
} //end build


