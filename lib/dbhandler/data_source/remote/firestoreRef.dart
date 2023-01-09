import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_application_1/tflite/recognition.dart';

abstract class FirestoreSource {
  //Future<Map<String, dynamic>> getCyclepedia();
}

class FirestoreSourceImpl extends FirestoreSource {
  static FirebaseFirestore db = FirebaseFirestore.instance;
  static CollectionReference ref = db.collection('cyclepedia');
  static CollectionReference img_ref = db.collection('uploaded_imgs');

  //@override
  static Future<List<dynamic>> getCyclepedia() async {
    QuerySnapshot snapshot = await ref.get();
    return snapshot.docs.map((doc) => doc.data()).toList();

    //return Map<String, dynamic>.from(snapshot.value as Map);
  }

  static Future<List<dynamic>> getDataByName(String x) async {
    QuerySnapshot snapshot = await ref.where("name", isEqualTo: x).get();
    return snapshot.docs.map((doc) => doc.data()).toList();
  }

  static Future<List<dynamic>> getDataByLabels(List<Recognition> recogs) async {
    var data = [];
    var names = recogs.map((e) => e.label).toList();
    names = names.toSet().toList();
    for (var name in names) {
      //print(name);
      QuerySnapshot snapshot = await ref.where("name", isEqualTo: name).get();
      data.addAll(snapshot.docs.map((doc) => doc.data()).toList());
    }
    //print(data);
    return data;
  }

  static Future<void> insert(String _name, String _image_base64) async {
    final detail = {'name': _name, 'image64': _image_base64};
    await img_ref.doc().set(detail);
    print("Insert Successfull!!!");
  }
}
