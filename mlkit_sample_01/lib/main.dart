import 'dart:io' as io;

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:image/image.dart';

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
      title: "Face Finder",
      theme: ThemeData(
        primaryColor: Colors.blueGrey,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const FaceFinder(),
    );
  }
}

class FaceFinder extends StatefulWidget {
  const FaceFinder({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _FaceFinderState();
}

class _FaceFinderState extends State<FaceFinder> {
  io.File? _imageFile;
  Size? _imageSize;
  List<Face>? _faceResults;
  final ImagePicker _picker = ImagePicker();
  final FaceDetector _faceDetector = GoogleMlKit.vision.faceDetector();

  Future<void> _setFaceDetectResult(ImageSource imageSource) async {
    final XFile? imgXFile = await _picker.pickImage(source: imageSource);
    if (imgXFile == null) return;
    final io.File imgFile = io.File(imgXFile.path);

    final image = decodeImage(io.File(imgFile.path).readAsBytesSync());
    if (image == null) return;
    final imgSz = Size(image.width.toDouble(), image.height.toDouble());

    final InputImage inpImg = InputImage.fromFile(imgFile);
    final List<Face> faces = await _faceDetector.processImage(inpImg);

    setState(() {
      _imageFile = imgFile;
      _imageSize = imgSz;
      _faceResults = faces;
    });
  }

  Widget _buildFaceDetectResult() {
    final imgFile = _imageFile;
    final imgSz = _imageSize;
    final faces = _faceResults;
    final boxDec = imgFile != null
        ? BoxDecoration(
            image: DecorationImage(
            image: FileImage(imgFile),
            fit: BoxFit.contain,
          ))
        : const BoxDecoration();
    final result = imgFile != null && faces != null && imgSz != null
        ? CustomPaint(
            painter: FaceBorderDrawer(imgSz, faces),
          )
        : const Center(
            child: Text(
              "Detecting...",
              style: TextStyle(color: Colors.blueGrey, fontSize: 32.0),
            ),
          );

    return Container(
      constraints: const BoxConstraints.expand(),
      decoration: boxDec,
      child: result,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Face Finder Sample"),
      ),
      body: _imageFile == null
          ? const Center(child: Text("No image selected."))
          : _buildFaceDetectResult(),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            onPressed: () => _setFaceDetectResult(ImageSource.gallery),
            tooltip: "Select Image.",
            child: const Icon(Icons.add_photo_alternate),
          ),
          FloatingActionButton(
            onPressed: () => _setFaceDetectResult(ImageSource.camera),
            tooltip: "Take a Photo.",
            child: const Icon(Icons.add_a_photo),
          )
        ],
      ),
    );
  }
}

class FaceBorderDrawer extends CustomPainter {
  final Size orgImageSize;
  final List<Face> faces;

  FaceBorderDrawer(this.orgImageSize, this.faces);

  @override
  void paint(Canvas canvas, Size size) {
    final hasVSpace =
        size.height >= (size.width / orgImageSize.width * orgImageSize.height);
    final scale = hasVSpace
        ? size.width / orgImageSize.width
        : size.height / orgImageSize.height;
    final space = hasVSpace
        ? (size.height - orgImageSize.height * scale) / 2.0
        : (size.width - orgImageSize.width * scale) / 2.0;
    final Paint paint = Paint()
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..color = Colors.red;

    for (Face face in faces) {
      final bbox = face.boundingBox;
      canvas.drawRect(
        Rect.fromLTRB(
          bbox.left * scale + (hasVSpace ? 0 : space),
          bbox.top * scale + (hasVSpace ? space : 0),
          bbox.right * scale + (hasVSpace ? 0 : space),
          bbox.bottom * scale + (hasVSpace ? space : 0),
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
