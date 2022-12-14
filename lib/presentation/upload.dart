import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/dbhandler/data_source/remote/firestoreRef.dart';
import 'package:flutter_application_1/tflite/mbv2_classifier.dart';
import 'package:image_picker/image_picker.dart';
import 'package:logger/logger.dart';
//import 'package:tflite/tflite.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter_helper/tflite_flutter_helper.dart';

class Upload extends StatefulWidget {
  final name;
  const Upload({Key? key, this.name = ""}) : super(key: key);
  @override
  State<Upload> createState() => _UploadState();
}

class _UploadState extends State<Upload> {
  String imagepath = "";
  String base64string = "";
  bool _loading = true;
  File _image = File('');
  List _output = [];
  String name = "";
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
    // loadModel1().then((value) {
    //   setState(() {});
    // });

    _classifier = MBV2_ClassifierQuant();
  }

  // classifyImage1(File image) async {
  //   //this function runs the model on the image
  //   var output = await Tflite.runModelOnImage(
  //     path: image.path,
  //     numResults: 10, //the amout of categories our neural network can predict
  //     threshold: 0.5,
  //     imageMean: 127.5,
  //     imageStd: 127.5,
  //   );
  //   setState(() {
  //     _loading = false;
  //     _output = [output];
  //     name = _output[0][0]['index'];
  //   });
  // }

  // loadModel1() async {
  //   //this function loads our model
  //   await Tflite.loadModel(
  //       model: 'assets/model.tflite', labels: 'assets/uploadlabels.txt');
  // }

  // openImage() async {
  //   try {
  //     var pickedFile = await imgpicker.pickImage(source: ImageSource.gallery);
  //     //you can use ImageCourse.camera for Camera capture
  //     if (pickedFile != null) {
  //       imagepath = pickedFile.path;
  //       File imagefile = File(imagepath); //convert Path to File
  //       Uint8List imagebytes = await imagefile.readAsBytes(); //convert to bytes
  //       String tempBase64string =
  //           base64.encode(imagebytes); //convert bytes to base64 string
  //       setState(() {
  //         base64string = tempBase64string;
  //       });
  //       classifyImage1(imagefile);
  //     } else {
  //       print("No image is selected.");
  //     }
  //   } catch (e) {
  //     print("error while picking file.");
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
    String tempBase64string = base64.encode(_image.readAsBytesSync());
    var pred = _classifier.predict(imageInput);

    setState(() {
      category = pred;
      base64string = tempBase64string;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          //linear color gradient
          backgroundColor: const Color(0xFF29D890),
          title: const Text(
            '????ng g??p c??y thu???c',
            style: TextStyle(
                color: Colors.white, fontSize: 20, letterSpacing: 0.8),
          ),
        ),
        body: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.all(20),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            SizedBox(
                width: 300,
                height: 450,
                child: imagepath != ""
                    ? Image.file(File(imagepath))
                    : Image.asset('assets/images/altimage.png')),

            //open button ----------------
            Container(
              margin: const EdgeInsets.fromLTRB(0, 0, 0, 20),
              child: ElevatedButton(
                onPressed: () {
                  //openImage();
                  getImage();
                },
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 15, horizontal: 0),
                  child: Text("Ch???n ???nh",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
            ),
            ElevatedButton(
                onPressed: category == null
                    ? () {
                        ScaffoldMessenger.of(context)
                            .showSnackBar(const SnackBar(
                          content: Text("Kh??ng t??m th???y th???c v???t trong ???nh"),
                          backgroundColor: Colors.deepOrange,
                        ));
                      }
                    : () {
                        FirestoreSourceImpl.insert(widget.name, base64string);
                        //MongoDatabase.insert(widget.name, base64string);
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text("???? ????ng g??p th??nh c??ng")));
                        setState(() {
                          imagepath = "";
                          base64string = "";
                          name = "";
                        });
                      },
                style: ElevatedButton.styleFrom(
                    backgroundColor: category == null
                        ? Colors.grey
                        : const Color(0xFF29D890),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30))),
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 15, horizontal: 0),
                  child: Text("????ng g??p",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                )),
          ]),
        ));
  }
}
