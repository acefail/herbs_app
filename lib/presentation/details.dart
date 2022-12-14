import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_application_1/tflite/mbv2_classifier.dart';
import 'package:logger/logger.dart';
import 'dart:io';
//mport 'package:tflite/tflite.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tflite_flutter_helper/tflite_flutter_helper.dart';
import 'upload.dart';
import 'package:image/image.dart' as img;

class Details extends StatefulWidget {
  final item;
  const Details({Key? key, this.item}) : super(key: key);
  @override
  _DetailsState createState() => _DetailsState();
}

class _DetailsState extends State<Details> {
  bool _loading = true;
  File _image = File('');
  List _output = [];
  String res = "";
  final picker = ImagePicker(); //allows us to pick image from gallery or camera

  final ImagePicker imgpicker = ImagePicker();

  late MBV2_Classifier _classifier;

  var logger = Logger();

  //File? _image;

  Image? _imageWidget;

  img.Image? fox;

  Category? category;

  @override
  void initState() {
    //initS is the first function that is executed by default when this class is called
    super.initState();
    // loadModel().then((value) {
    //   setState(() {});
    // });
    _classifier = MBV2_ClassifierQuant();
  }

  @override
  void dispose() {
    //dis function disposes and clears our memory
    super.dispose();
    //Tflite.close();
  }

  // classifyImage(File image) async {
  //   //this function runs the model on the image
  //   var output = await Tflite.runModelOnImage(
  //     path: image.path,
  //     numResults: 36, //the amout of categories our neural network can predict
  //     threshold: 0.5,
  //     imageMean: 127.5,
  //     imageStd: 127.5,
  //   );
  //   print("output: $output");
  //   setState(() {
  //     _loading = false;
  //     _output = [output];
  //     res = _output[0][0]['confidence'] > 0.8
  //         ? 'Đây là: ${_output[0][0]['label']}\nĐộ chính xác: ${(_output[0][0]['confidence'] * 100).toStringAsFixed(2)}'
  //         : 'Chưa thể kết luận được';
  //   });
  //   showModalBottomSheet<void>(
  //     context: context,
  //     shape: const RoundedRectangleBorder(
  //       borderRadius: BorderRadius.all(Radius.circular(20.0)),
  //     ),
  //     builder: (BuildContext context) {
  //       return SizedBox(
  //         height: 800,
  //         child: Column(
  //           children: <Widget>[
  //             //button icon close in left top corner
  //             Row(
  //               mainAxisAlignment: MainAxisAlignment.end,
  //               children: <Widget>[
  //                 IconButton(
  //                   icon: const Icon(Icons.close),
  //                   onPressed: () {
  //                     Navigator.pop(context);
  //                   },
  //                 ),
  //               ],
  //             ),
  //             Container(
  //               height: 200,
  //               width: 200,
  //               decoration: BoxDecoration(
  //                 border: Border.all(color: Colors.blueAccent),
  //                 borderRadius: const BorderRadius.all(Radius.circular(
  //                         20.0) //                 <--- border radius here
  //                     ),
  //                 boxShadow: [
  //                   BoxShadow(
  //                     color: Colors.grey.withOpacity(0.5),
  //                     spreadRadius: 5,
  //                     blurRadius: 7,
  //                     offset: const Offset(0, 3), // changes position of shadow
  //                   ),
  //                 ],
  //               ),
  //               child: ClipRRect(
  //                 borderRadius: const BorderRadius.all(Radius.circular(20.0)),
  //                 child: Image.file(image, fit: BoxFit.fill),
  //               ),
  //             ),
  //             Container(
  //               margin: const EdgeInsets.only(top: 20),
  //               child: Text(
  //                 res,
  //                 style: const TextStyle(
  //                     fontSize: 10, fontWeight: FontWeight.bold),
  //               ),
  //             ),
  //             TextButton(
  //               onPressed: () {
  //                 Navigator.pop(context);
  //               },
  //               child: const Text('Xem chi tiết'),
  //             )
  //           ],
  //         ),
  //       );
  //     },
  //   );
  // }

  // loadModel() async {
  //   //this function loads our model
  //   await Tflite.loadModel(
  //       model: 'assets/model.tflite', labels: 'assets/labels.txt');
  // }

  // pickImage() async {
  //   //this function to grab the image from camera
  //   var image = await picker.pickImage(source: ImageSource.camera);
  //   if (image == null) return null;

  //   setState(() {
  //     _image = File(image.path);
  //   });
  //   classifyImage(_image);
  // }

  // pickGalleryImage() async {
  //   //this function to grab the image from gallery
  //   var image = await picker.pickImage(source: ImageSource.gallery);
  //   if (image == null) {
  //     //print('null');
  //     return null;
  //   } else {
  //     //print('not null');
  //     setState(() {
  //       _image = File(image.path);
  //     });
  //     classifyImage(_image);
  //   }
  // }

  Future getImage() async {
    final pickedFile = await imgpicker.pickImage(source: ImageSource.gallery);

    setState(() {
      _image = File(pickedFile!.path);
      _imageWidget = Image.file(_image);

      _predict();
    });
  }

  void _predict() async {
    img.Image imageInput = img.decodeImage(_image.readAsBytesSync())!;
    //String tempBase64string = base64.encode(_image.readAsBytesSync());
    var pred = _classifier.predict(imageInput);

    setState(() {
      _loading = false;
      category = pred;
      res = category!.score > 0.8
          ? 'Đây là: ${category!.label}\nĐộ chính xác: ${(category!.score * 100).toStringAsFixed(2)}'
          : 'Chưa thể kết luận được';
      //base64string = tempBase64string;
    });
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(20.0)),
      ),
      builder: (BuildContext context) {
        return SizedBox(
          height: 800,
          child: Column(
            children: <Widget>[
              //button icon close in left top corner
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
              Container(
                height: 200,
                width: 200,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.blueAccent),
                  borderRadius: const BorderRadius.all(Radius.circular(
                          20.0) //                 <--- border radius here
                      ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.5),
                      spreadRadius: 5,
                      blurRadius: 7,
                      offset: const Offset(0, 3), // changes position of shadow
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.all(Radius.circular(20.0)),
                  child: Image.file(_image, fit: BoxFit.fill),
                ),
              ),
              Container(
                margin: const EdgeInsets.only(top: 20),
                child: Text(
                  res,
                  style: const TextStyle(
                      fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('Xem chi tiết'),
              )
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    //print(widget.item[0]['flag'].runtimeType);
    return Scaffold(
        extendBodyBehindAppBar: true,
        backgroundColor: const Color(0xFFFBFDFF),
        appBar: AppBar(
          backgroundColor: const Color.fromRGBO(219, 215, 215, 0.0),
          elevation: 0,
        ),
        body: //Container(
            //child:
            SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Image.memory(base64Decode(
                      widget.item['img64'].replaceAll(RegExp(r'\s+'), ''))),
                  Positioned(
                    top: width - 30,
                    left: width - 80,
                    child: ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        shape: const CircleBorder(),
                        backgroundColor: const Color(0xFFFF6262),
                        padding: const EdgeInsets.all(13),
                        elevation: 15,
                      ),
                      child: const Icon(Icons.favorite, size: 35),
                    ),
                  ),
                ],
              ),
              Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 0, horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Expanded(
                          flex: 13,
                          child: Container(
                              margin: const EdgeInsets.fromLTRB(0, 50, 0, 15),
                              child: Text(
                                widget.item['name'],
                                style: const TextStyle(
                                  fontSize: 29,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF36455A),
                                ),
                              )),
                        ),
                        widget.item['flag'] == '0'
                            ? Expanded(
                                flex: 7,
                                child: Container(
                                  margin:
                                      const EdgeInsets.fromLTRB(0, 50, 0, 15),
                                  child: ElevatedButton(
                                    onPressed: () {
                                      Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                              builder: (context) => Upload(
                                                  name: widget.item[0]
                                                      ['name'])));
                                    },
                                    style: ElevatedButton.styleFrom(
                                      primary: const Color(0xFF2DDA93),
                                      shadowColor: const Color(0xFF2DDA93),
                                      elevation: 10,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(30),
                                      ),
                                    ),
                                    child: const SizedBox(
                                      width: 80,
                                      height: 45,
                                      child: Center(
                                        child: Text(
                                          'Đóng góp hình ảnh',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              )
                            : Container()
                      ]),
                      widget.item['flag'] == '0'
                          ? const Text(
                              'Hiện tại ứng dụng chưa có đủ dữ liệu hình ảnh để tiến hành nhận diện loài cây này',
                              style: TextStyle(
                                color: Color(0xFFFF6262),
                                fontSize: 16,
                              ))
                          : Container(),
                      Container(
                        margin: const EdgeInsets.fromLTRB(0, 15, 0, 0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Expanded(
                                flex: 3,
                                child: Text(
                                  'Tên khoa học',
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF495566)),
                                )),
                            Expanded(
                                flex: 6,
                                child: Text(
                                  widget.item['science_name'],
                                  style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF495566)),
                                ))
                          ],
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.fromLTRB(0, 15, 0, 0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Expanded(
                                flex: 3,
                                child: Text(
                                  'Thuộc họ',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Color(0xFF6A6F7D),
                                  ),
                                )),
                            Expanded(
                                flex: 6,
                                child: Text(widget.item['family'],
                                    style: const TextStyle(
                                      fontSize: 16,
                                      color: Color(0xFF6A6F7D),
                                    )))
                          ],
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.fromLTRB(0, 15, 0, 0),
                        child: const Text(
                          'Mô tả',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF495566)),
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.fromLTRB(0, 10, 0, 0),
                        child: Text(widget.item['description'],
                            style: const TextStyle(
                              fontSize: 16,
                              color: Color(0xFF6A6F7D),
                            )),
                      ),
                      Container(
                        margin: const EdgeInsets.fromLTRB(0, 15, 0, 0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Expanded(
                                flex: 3,
                                child: Text(
                                  'Bộ phận dùng',
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF495566)),
                                )),
                            Expanded(
                                flex: 6,
                                child: Text(widget.item['parts_used'],
                                    style: const TextStyle(
                                      fontSize: 16,
                                      color: Color(0xFF6A6F7D),
                                    )))
                          ],
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.fromLTRB(0, 15, 0, 0),
                        child: const Text(
                          'Công năng, chủ trị',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF495566)),
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.fromLTRB(0, 10, 0, 0),
                        child: Text(widget.item['functions'],
                            style: const TextStyle(
                              fontSize: 16,
                              color: Color(0xFF6A6F7D),
                            )),
                      ),
                      Container(
                        margin: const EdgeInsets.fromLTRB(0, 15, 0, 0),
                        child: const Text(
                          'Liều lượng và cách dùng',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF495566)),
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.fromLTRB(0, 10, 0, 0),
                        child: Text(widget.item['usage'],
                            style: const TextStyle(
                              fontSize: 16,
                              color: Color(0xFF6A6F7D),
                            )),
                      ),
                    ],
                  ))
            ],
          ),
        ));
    //);
  }
}
