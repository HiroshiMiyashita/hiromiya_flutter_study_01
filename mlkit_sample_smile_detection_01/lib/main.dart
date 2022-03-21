import 'dart:io';

import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:path/path.dart';
import 'package:image_picker/image_picker.dart';

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "SMILE SNS",
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const MainForm(),
    );
  }
}

class MainForm extends StatefulWidget {
  const MainForm({Key? key}) : super(key: key);

  @override
  _MainFormState createState() => _MainFormState();
}

class _MainFormState extends State<MainForm> {
  String _name = "";
  String _msg = "";
  final FaceDetector _faceDetector = GoogleMlKit.vision.faceDetector(
      const FaceDetectorOptions(
          enableClassification: true,
          enableLandmarks: true,
          mode: FaceDetectorMode.accurate));
  final ImagePicker _picker = ImagePicker();
  final uuid = const Uuid();

  @override
  void dispose() {
    _faceDetector.close();
    super.dispose();
  }

  Future<void> _detectFace(ImageSource imgSrc) async {
    setState(() => _msg = "Processing...");

    final imgXFile = await _picker.pickImage(source: imgSrc);
    if (imgXFile == null) {
      setState(() => _msg = "No Image Picked.");
      return;
    }
    final imgFile = File(imgXFile.path);

    final inpImg = InputImage.fromFile(imgFile);
    final faces = await _faceDetector.processImage(inpImg);
    if (faces.isEmpty) {
      setState(() => _msg = "No Face Detected.");
      return;
    }

    final imgRef = FirebaseStorage.instance
        .ref()
        .child("/images/${uuid.v1()}_${basename(imgFile.path)}");
    final taskState =
        (await imgRef.putFile(imgFile).whenComplete(() => null)).state;
    if (taskState != TaskState.success) {
      setState(() => _msg = "Failed to upload the image file.");
      return;
    }

    final imgDLUrl = await imgRef.getDownloadURL();
    final largestFace = faces.reduce((e1, e2) =>
        e1.boundingBox.width * e1.boundingBox.height >
                e2.boundingBox.width * e2.boundingBox.height
            ? e1
            : e2);
    await FirebaseFirestore.instance.collection("smiles").add({
      "name": _name,
      "smile_prob": largestFace.smilingProbability,
      "image_url": imgDLUrl,
      "date": FieldValue.serverTimestamp()
    });

    setState(() => _msg = "");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("SMILE SNS"),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: <Widget>[
          const Padding(padding: EdgeInsets.all(30.0)),
          Text(_msg,
              style: const TextStyle(
                color: Colors.lightBlue,
                fontSize: 32.0,
              )),
          TextFormField(
            decoration: const InputDecoration(
              icon: Icon(Icons.person),
              hintText: "Please input your name.",
              labelText: "YOUR NAME",
            ),
            onChanged: (text) {
              setState(() {
                _name = text;
              });
            },
          )
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: <Widget>[
          FloatingActionButton(
            onPressed: () async {
              try {
                await _detectFace(ImageSource.gallery);
                Navigator.of(context).push(
                    MaterialPageRoute(builder: (ctx) => const TimelinePage()));
              } catch (e) {
                setState(() => _msg = "Error on processing image.(error=$e)");
              }
            },
            tooltip: "Select Image",
            heroTag: "gallery",
            child: const Icon(Icons.add_photo_alternate),
          ),
          const Padding(padding: EdgeInsets.all(10.0)),
          FloatingActionButton(
            onPressed: () async {
              try {
                await _detectFace(ImageSource.camera);
                Navigator.of(context).push(
                    MaterialPageRoute(builder: (ctx) => const TimelinePage()));
              } catch (e) {
                setState(() => _msg = "Error on processing image.(error=$e)");
              }
            },
            tooltip: "Take Photo",
            heroTag: "camera",
            child: const Icon(Icons.add_a_photo),
          ),
        ],
      ),
    );
  }
}

class TimelinePage extends StatelessWidget {
  const TimelinePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("SMILE SNS"),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("smiles")
            .orderBy("date", descending: true)
            .limit(10)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.data == null) {
            return const LinearProgressIndicator();
          }
          final docs = snapshot.data?.docs ?? [];

          return ListView.builder(
            padding: const EdgeInsets.all(18),
            itemCount: docs.length,
            itemBuilder: (context, i) => _buildListItem(context, docs[i]),
          );
        },
      ),
    );
  }

  Widget _buildListItem(BuildContext context, QueryDocumentSnapshot snap) {
    Map<String, dynamic> _data = snap.data() as Map<String, dynamic>;
    DateTime _datetime = _data["date"].toDate();
    var _formatter = DateFormat("MM/dd HH:mm");
    String postDate = _formatter.format(_datetime);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 9.0),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: ListTile(
          leading: Text(postDate),
          title: Text(_data["name"]),
          subtitle: Text("は" +
              (_data["smile_prob"] * 100.0).toStringAsFixed(1) +
              "%の笑顔です。"),
          trailing: Text(
            _getIcon(_data["smile_prob"]),
            style: const TextStyle(
              fontSize: 24,
            ),
          ),
          onTap: () {
            Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ImagePage(_data["image_url"]),
                ));
          },
        ),
      ),
    );
  }

  String _getIcon(double smileProb) {
    String icon = "";
    if (smileProb < 0.2) {
      icon = "😧";
    } else if (smileProb < 0.4) {
      icon = "😌";
    } else if (smileProb < 0.6) {
      icon = "😀";
    } else if (smileProb < 0.8) {
      icon = "😄";
    } else {
      icon = "😆";
    }
    return icon;
  }
}

class ImagePage extends StatelessWidget {
  final String imgUrl;

  const ImagePage(this.imgUrl, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("SMILE SNS"),
      ),
      body: Center(
        child: Image.network(imgUrl),
      ),
    );
  }
}
