import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/presentation/widgets/camera_view_singleton.dart';
import 'package:flutter_application_1/tflite/classifier.dart';
//import 'package:flutter_application_1/tflite/mbv2_classifier.dart';
import 'package:logger/logger.dart';
//import 'package:tflite/tflite.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tflite_flutter_helper/tflite_flutter_helper.dart' as tfl_helper;
// import 'listitem.dart';
import 'widgets/favourite.dart';
import 'widgets/home.dart';
import 'widgets/listitem.dart';

import 'package:image/image.dart' as img;

class Navbar extends StatefulWidget {
  @override
  _NavbarState createState() => _NavbarState();
}

class _NavbarState extends State<Navbar> {
  final List<Widget> _children = [
    ListItem(),
    Home(results: const []),
    Favorite(),
  ];
  void OpenPage(int index) {
    setState(() {
      selectedIndex = index;
    });
  }

  int selectedIndex = 1;
  double percent = 0.00;
  String name = "";
  bool _loading = true;
  File _image = File('');

  final picker = ImagePicker(); //allows us to pick image from gallery or camera

  final ImagePicker imgpicker = ImagePicker();

  late Classifier _classifier;

  var logger = Logger();

  //File? _image;

  Image? _imageWidget;

  img.Image? fox;

  tfl_helper.Category? category;

  //final picker = ImagePicker(); //allows us to pick image from gallery or camera

  @override
  void initState() {
    //initS is the first function that is executed by default when this class is called
    super.initState();
    // loadModel().then((value) {
    //   setState(() {});
    // });
    _classifier = Classifier();
  }

  @override
  void dispose() {
    //dis function disposes and clears our memory
    super.dispose();
    //Tflite.close();
  }

  // classifyImage(File image) async {
  //   //this function runs the model on the image
  //   print(image.path);
  //   var output = await Tflite.runModelOnImage(
  //     path: image.path,
  //     numResults: 10, //the amout of categories our neural network can predict
  //     threshold: 0.5,
  //     imageMean: 127.5,
  //     imageStd: 127.5,
  //   );
  //   print(output);
  //   setState(() {
  //     _loading = false;
  //     _output = [output];
  //     name = _output[0][0]['label'];
  //     percent = _output[0][0]['confidence'];
  //     print(_output);
  //     _children[1] = Home(name: name, percent: percent);
  //   });
  // }

  // loadModel() async {
  //   //this function loads our model
  //   await Tflite.loadModel(
  //       model: 'assets/model.tflite', labels: 'assets/labels.txt');
  // }

  pickImage() async {
    //this function to grab the image from camera
    var image = await picker.pickImage(source: ImageSource.camera);
    if (image == null) return null;

    setState(() {
      _image = File(image.path);
      _imageWidget = Image.file(_image);

      _predict();
    });
    //classifyImage(_image);
  }

  // pickGalleryImage() async {
  //   //this function to grab the image from gallery
  //   var image = await picker.pickImage(source: ImageSource.gallery);
  //   if (image == null) {
  //     return null;
  //   } else {
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
    if (Platform.isAndroid) {
      //imageInput = img.copyRotate(imageInput, 90);
    }
    Map<String, dynamic>? results = _classifier.predict(imageInput);

    setState(() {
      //base64string = tempBase64string;
      _loading = false;
      //print(results);

      CameraViewSingleton.inputImageSize =
          Size(imageInput.width.toDouble(), imageInput.height.toDouble());
      Size screenSize = MediaQuery.of(context).size;
      CameraViewSingleton.screenSize = screenSize;
      CameraViewSingleton.ratio =
          screenSize.width / imageInput.width.toDouble();
      //print(imageSize);
      _children[1] = Home(path: _image, results: results!['recognitions']);
    });
  }

  bool pressCategory = false;
  bool pressFavourite = false;
  bool firstpress = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _children[selectedIndex],
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        child: Container(
          height: 60,
          //pading left right 20
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              InkWell(
                child: //Container(
                    //child:
                    Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.folder,
                      size: 40,
                      color: pressCategory
                          ? const Color(0xFF2DDA93)
                          : const Color.fromRGBO(38, 38, 38, 0.4),
                    ),
                    Text('Danh m???c',
                        style: TextStyle(
                          fontWeight: FontWeight.w400,
                          color: pressCategory
                              ? const Color(0xFF2DDA93)
                              : const Color.fromRGBO(38, 38, 38, 0.4),
                        ))
                  ],
                ),
                //),
                onTap: () {
                  setState(() {
                    firstpress = true;
                  });
                  OpenPage(0);
                  if (!pressCategory & !pressFavourite) {
                    setState(() {
                      pressCategory = !pressCategory;
                    });
                  } else if (!pressCategory & pressFavourite) {
                    pressCategory = !pressCategory;
                    pressFavourite = !pressFavourite;
                  }
                },
              ),
              InkWell(
                child: //Container(
                    //child:
                    Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.favorite,
                      size: 40,
                      color: pressFavourite
                          ? const Color(0xFF2DDA93)
                          : const Color.fromRGBO(38, 38, 38, 0.4),
                    ),
                    Text('B??? s??u t???p',
                        style: TextStyle(
                          fontWeight: FontWeight.w400,
                          color: pressFavourite
                              ? const Color(0xFF2DDA93)
                              : const Color.fromRGBO(38, 38, 38, 0.4),
                        ))
                  ],
                ),
                //),
                onTap: () {
                  setState(() {
                    firstpress = true;
                  });
                  OpenPage(2);
                  if (!pressCategory & !pressFavourite) {
                    setState(() {
                      pressFavourite = !pressFavourite;
                    });
                  } else if (pressCategory & !pressFavourite) {
                    pressCategory = !pressCategory;
                    pressFavourite = !pressFavourite;
                  }
                },
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
          onPressed: () {
            if (firstpress) {
              setState(() {
                firstpress = false;
                pressCategory = false;
                pressFavourite = false;
              });
              OpenPage(1);
            } else {
              //reset all image
              showModalBottomSheet<void>(
                  context: context,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(
                        top: Radius.circular(10.0),
                        bottom: Radius.circular(10.0)),
                  ),
                  builder: (BuildContext context) {
                    return SizedBox(
                        height: 180,
                        child: Column(
                          children: <Widget>[
                            InkWell(
                                onTap: () {
                                  pickImage();
                                  Navigator.pop(context);
                                },
                                child: const FractionallySizedBox(
                                  widthFactor: 1.0,
                                  child: SizedBox(
                                      height: 60,
                                      child: Center(
                                          child: Text('Ch???p ???nh',
                                              style: TextStyle(
                                                  fontSize: 20,
                                                  color: Color(0xFF007AFF))))),
                                )),
                            const Divider(
                              height: 0,
                            ),
                            InkWell(
                                onTap: () {
                                  //pickGalleryImage and show image in modal bottom sheet
                                  getImage();
                                  Navigator.pop(context);
                                  //show image in modal bottom sheet
                                },
                                child: const FractionallySizedBox(
                                  widthFactor: 1.0,
                                  child: SizedBox(
                                      height: 60,
                                      child: Center(
                                          child: Text('???nh t??? th?? vi???n',
                                              style: TextStyle(
                                                  fontSize: 20,
                                                  color: Color(0xFF007AFF))))),
                                )),
                            const Divider(
                              height: 0,
                            ),
                            InkWell(
                                onTap: () {
                                  Navigator.pop(context);
                                },
                                child: const FractionallySizedBox(
                                  widthFactor: 1.0,
                                  child: SizedBox(
                                      height: 60,
                                      child: Center(
                                          child: Text(
                                        'Cancel',
                                        style: TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFFEF5757)),
                                      ))),
                                ))
                          ],
                        )

                        // child: Container()
                        );
                  });
            }
          },
          child: const Icon(Icons.camera_alt)),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}
