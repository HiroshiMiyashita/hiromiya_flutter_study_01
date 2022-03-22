import 'dart:convert';
import 'dart:io';

import 'package:uuid/uuid.dart';
import 'package:path/path.dart';
import 'package:image_picker/image_picker.dart';

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

final langConfThreshold = 0.7;

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
      title: "Translator",
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const Home(TranslateLanguage.ENGLISH, TranslateLanguage.JAPANESE),
    );
  }
}

class Home extends StatefulWidget {
  final String srcLang;
  final String destLang;
  const Home(this.srcLang, this.destLang, {Key? key}) : super(key: key);

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  bool _initialized = false;
  String _msg = "";
  String _srcLang = "";
  String _destLang = "";
  File? _imgFile;
  RecognisedText? _textRecRes;
  List<String?>? _tranTexts;

  final TextDetectorV2 _textDetector = GoogleMlKit.vision.textDetectorV2();
  final tranLangModelMgr = GoogleMlKit.nlp.translateLanguageModelManager();
  final LanguageIdentifier _langIdentfier =
      GoogleMlKit.nlp.languageIdentifier();
  OnDeviceTranslator? _translator;
  final ImagePicker _picker = ImagePicker();
  final uuid = const Uuid();

  OnDeviceTranslator? get tranlator => _translator;

  @override
  void initState() {
    super.initState();
    _srcLang = widget.srcLang;
    _destLang = widget.destLang;
    _translator = GoogleMlKit.nlp.onDeviceTranslator(
        sourceLanguage: _srcLang, targetLanguage: _destLang);

    Future<bool>(() async {
      await tranLangModelMgr.downloadModel(widget.srcLang);
      await tranLangModelMgr.downloadModel(widget.destLang);
      return (await tranLangModelMgr.isModelDownloaded(widget.srcLang)) &&
          (await tranLangModelMgr.isModelDownloaded(widget.destLang));
    }).then((res) {
      _initialized = res;
      if (!res) {
        setState(() {
          _msg = "Fail to download language model";
        });
      }
    });
  }

  @override
  void dispose() {
    _textDetector.close();
    _langIdentfier.close();
    _translator?.close();
    super.dispose();
  }

  Future<void> _translate(XFile? imgXFile) async {
    if (imgXFile == null) {
      setState(() => _msg = "No Image Picked.");
      return;
    }
    final imgFile = File(imgXFile.path);

    setState(() {
      _msg = "Processing...";
      _imgFile = imgFile;
    });

    final inpImg = InputImage.fromFile(imgFile);
    final textRecRes = await _textDetector.processImage(inpImg);

    final tran = tranlator;
    if (tran == null) {
      setState(() {
        _msg = "No translator setted.";
      });
      return;
    }
    final tranTexts = textRecRes.blocks.isNotEmpty
        ? await Future.wait(
            textRecRes.blocks.map(
              (block) async {
                final possibleLangs = (await _langIdentfier
                    .identifyPossibleLanguages(block.text));
                final isSrcLang = possibleLangs.any((e) =>
                    e.language == widget.srcLang &&
                    e.confidence > langConfThreshold);
                return isSrcLang
                    ? (await tran.translateText(block.text))
                    : null;
              },
            ),
          )
        : <String>[];

    setState(() {
      _msg = "";
      _textRecRes = textRecRes;
      _tranTexts = tranTexts;
    });

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
    await FirebaseFirestore.instance.collection("translated_results").add({
      "date": FieldValue.serverTimestamp(),
      "image_url": imgDLUrl,
      "src_lang_setting": _srcLang,
      "dest_lang_setting": _destLang,
      "blocks": textRecRes.blocks.map((block) {
        final rect = block.rect;
        print(block.recognizedLanguages);
        return {
          "recognized_languages": block.recognizedLanguages,
          "src_text": block.text,
          "position": {
            "top": rect.top,
            "left": rect.left,
            "bottom": rect.bottom,
            "right": rect.right
          }
        };
      }).toList(),
      "translated_texts": tranTexts
    });
  }

  @override
  Widget build(BuildContext context) {
    final imgFile = _imgFile;
    final textRecRes = _textRecRes;
    final tranTexts = _tranTexts ?? [];

    return Scaffold(
      appBar: AppBar(
        title: Text("Translator $_srcLang -> $_destLang"),
      ),
      body: !_initialized
          ? Center(child: Text(_msg))
          : Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Expanded(
                  flex: 1,
                  child: imgFile != null
                      ? InteractiveViewer(
                          child: Image.file(imgFile),
                          scaleEnabled: true,
                          panEnabled: true,
                        )
                      : const Center(
                          child: Text(
                            "No Image Selected.",
                          ),
                        ),
                ),
                Expanded(
                  flex: 1,
                  child: textRecRes != null && tranTexts.isNotEmpty
                      ? ListView.separated(
                          itemBuilder: (ctx, i) {
                            final block = textRecRes.blocks[i];
                            final tranText = tranTexts[i];
                            return TranslateResultTile(
                                block, tranText, "Block $i");
                          },
                          separatorBuilder: (ctx, i) => const Divider(),
                          itemCount: tranTexts.length,
                        )
                      : const Center(
                          child: Text("No Dtected texts."),
                        ),
                ),
                Text(_msg,
                    style: const TextStyle(
                      color: Colors.lightBlue,
                      fontSize: 32.0,
                    )),
              ],
            ),
      floatingActionButton: !_initialized
          ? const SizedBox.shrink()
          : Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: <Widget>[
                FloatingActionButton(
                  onPressed: () async {
                    try {
                      await _translate(
                          await _picker.pickImage(source: ImageSource.gallery));
                    } catch (e) {
                      setState(
                          () => _msg = "Error on processing image.(error=$e)");
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
                      await _translate(await _picker.pickImage(
                          source: ImageSource.camera, imageQuality: 100));
                    } catch (e) {
                      setState(
                          () => _msg = "Error on processing image.(error=$e)");
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

class TranslateResultTile extends StatelessWidget {
  final TextBlock block;
  final String? tranText;
  final String title;
  const TranslateResultTile(this.block, this.tranText, this.title, {Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.headline6,
          ),
          const Padding(padding: EdgeInsets.only(bottom: 10)),
          Text(
            "Detected Text",
            style: Theme.of(context).textTheme.caption,
          ),
          Card(child: Text(block.text.replaceAll('\n', ' '))),
          const Padding(padding: EdgeInsets.only(bottom: 10)),
          Text(
            "Translated Result",
            style: Theme.of(context).textTheme.caption,
          ),
          Card(child: Text(tranText?.replaceAll('\n', ' ') ?? "")),
          Image.asset("assets/images/color-regular.png")
        ],
      ),
    );
  }
}
