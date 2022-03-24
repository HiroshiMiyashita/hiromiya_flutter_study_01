import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:uuid/uuid.dart';
// import 'package:path/path.dart';
import 'package:image_picker/image_picker.dart';

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_storage/firebase_storage.dart';

const langConfThreshold = 0.5;

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
  // File? _imgFile;
  ui.Image? _uiImage;
  RecognisedText? _textRecRes;
  List<String?>? _tranTexts;
  List<bool>? _selects;

  final TextDetectorV2 _textDetector = GoogleMlKit.vision.textDetectorV2();
  final tranLangModelMgr = GoogleMlKit.nlp.translateLanguageModelManager();
  final LanguageIdentifier _langIdentfier =
      GoogleMlKit.nlp.languageIdentifier();
  OnDeviceTranslator? _translator;
  final ImagePicker _picker = ImagePicker();
  final uuid = const Uuid();

  OnDeviceTranslator? get tranlator => _translator;

  Future<void> _initialize() async {
    try {
      setState(() => _msg = "Downloading $_srcLang model.");
      await tranLangModelMgr.downloadModel(widget.srcLang);
      setState(() => _msg = "Downloading $_destLang model.");
      await tranLangModelMgr.downloadModel(widget.destLang);
      setState(() => _msg = "Checking downloaded models.");
      final initialized =
          (await tranLangModelMgr.isModelDownloaded(_srcLang)) &&
              (await tranLangModelMgr.isModelDownloaded(_destLang));

      setState(() {
        _initialized = initialized;
        _msg = initialized ? "" : "Download Language models is failed.";
      });
    } catch (e) {
      setState(() => _msg = "Initialize failed.");
    }
  }

  @override
  void initState() {
    super.initState();
    _srcLang = widget.srcLang;
    _destLang = widget.destLang;
    _translator = GoogleMlKit.nlp.onDeviceTranslator(
        sourceLanguage: _srcLang, targetLanguage: _destLang);

    _initialize();
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
      // _imgFile = imgFile;
    });

    final inpImg = InputImage.fromFile(imgFile);
    final textRecRes = await _textDetector.processImage(inpImg);

    final tran = tranlator;
    if (tran == null) {
      setState(() => _msg = "No translator setted.");
      return;
    }
    final tranTexts = textRecRes.blocks.isNotEmpty
        ? await Future.wait(
            textRecRes.blocks.map(
              (block) async {
                try {
                  // final possibleLangs = (await _langIdentfier
                  //     .identifyPossibleLanguages(block.text));
                  // final isSrcLang = possibleLangs.any((e) =>
                  //     e.language == widget.srcLang &&
                  //     e.confidence > langConfThreshold);
                  // return isSrcLang
                  //     ? (await tran.translateText(block.text))
                  //     : null;
                  return await tran.translateText(block.text);
                } catch (e) {
                  return null;
                }
              },
            ),
          )
        : <String>[];

    final ui.Image? uiImage = await convToUIImage(imgFile);

    setState(() {
      _msg = "";
      _textRecRes = textRecRes;
      _tranTexts = tranTexts;
      _selects = List.generate(_tranTexts?.length ?? 0, (i) => false);
      _uiImage = uiImage;
    });

    // final imgRef = FirebaseStorage.instance
    //     .ref()
    //     .child("/images/${uuid.v1()}_${basename(imgFile.path)}");
    // final taskState =
    //     (await imgRef.putFile(imgFile).whenComplete(() => null)).state;
    // if (taskState != TaskState.success) {
    //   setState(() => _msg = "Failed to upload the image file.");
    //   return;
    // }

    // final imgDLUrl = await imgRef.getDownloadURL();
    // await FirebaseFirestore.instance.collection("translated_results").add({
    //   "date": FieldValue.serverTimestamp(),
    //   "image_url": imgDLUrl,
    //   "src_lang_setting": _srcLang,
    //   "dest_lang_setting": _destLang,
    //   "blocks": textRecRes.blocks.map((block) {
    //     final rect = block.rect;
    //     return {
    //       "recognized_languages": block.recognizedLanguages,
    //       "src_text": block.text,
    //       "position": {
    //         "top": rect.top,
    //         "left": rect.left,
    //         "bottom": rect.bottom,
    //         "right": rect.right
    //       }
    //     };
    //   }).toList(),
    //   "translated_texts": tranTexts
    // });
  }

  @override
  Widget build(BuildContext context) {
    final uiImage = _uiImage;
    final textRecRes = _textRecRes;
    final tranTexts = _tranTexts ?? [];
    final selects = _selects ?? [];

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
                  child: uiImage != null && textRecRes != null
                      ? InteractiveViewer(
                          child: CustomPaint(
                            painter: DetectedBlockDrawer(
                                uiImage, textRecRes.blocks, selects),
                          ),
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
                          key: ObjectKey(textRecRes),
                          itemBuilder: (ctx, i) {
                            final block = textRecRes.blocks[i];
                            final tranText = tranTexts[i];
                            final select = selects[i];
                            return InkWell(
                              onTap: () {
                                setState(() => _selects?[i] = !select);
                              },
                              child: TranslateResultTile(
                                  block, tranText, "Block $i", select,
                                  key: ValueKey(block.text)),
                            );
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
  final bool selected;

  const TranslateResultTile(
      this.block, this.tranText, this.title, this.selected,
      {Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    ThemeData theme = Theme.of(context);
    theme = selected
        ? theme.copyWith(
            cardTheme:
                theme.cardTheme.copyWith(color: theme.colorScheme.primary))
        : theme;
    return Theme(
      data: theme,
      child: Card(
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
      ),
    );
  }
}

Future<ui.Image?> convToUIImage(File imgFile) async {
  try {
    ui.Codec codec = await ui.instantiateImageCodec(imgFile.readAsBytesSync());
    if (codec.frameCount < 1) return null;
    return (await codec.getNextFrame()).image;
  } catch (e) {
    return null;
  }
}

class DetectedBlockDrawer extends CustomPainter {
  final ui.Image srcImage;
  final List<TextBlock> blocks;
  final List<bool> selects;

  DetectedBlockDrawer(this.srcImage, this.blocks, this.selects);

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke
      ..color = Colors.red;

    final hasVSpace =
        size.height >= (size.width / srcImage.width * srcImage.height);
    final scale =
        hasVSpace ? size.width / srcImage.width : size.height / srcImage.height;
    final imgWidth = srcImage.width * scale;
    final imgHeight = srcImage.height * scale;
    final xOffset =
        hasVSpace ? 0.0 : (size.width - scale * srcImage.width) / 2.0;
    final yOffset =
        hasVSpace ? (size.height - scale * srcImage.height) / 2.0 : 0.0;

    canvas.drawImageRect(
        srcImage,
        ui.Rect.fromLTWH(
            0.0, 0.0, srcImage.width.toDouble(), srcImage.height.toDouble()),
        ui.Rect.fromLTWH(xOffset, yOffset, imgWidth, imgHeight),
        paint);

    for (int i = 0; i < blocks.length; i++) {
      final block = blocks[i];
      final isSelect = selects[i];
      if (!isSelect) continue;

      canvas.drawRect(
        ui.Rect.fromLTWH(
          xOffset + scale * block.rect.left,
          yOffset + scale * block.rect.top,
          scale * (block.rect.right - block.rect.left),
          scale * (block.rect.bottom - block.rect.top),
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
