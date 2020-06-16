import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:mobile_objects_recognition/dl_models_enum.dart';
import 'package:mobile_objects_recognition/object_recognizer.dart';
import 'package:mobile_objects_recognition/object_recognizer_factory.dart';

import 'package:tflite/tflite.dart';
import 'package:camera/camera.dart';

List<CameraDescription> cameras;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  cameras = await availableCameras();
  runApp(MainApp());
}

class MainApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Objects Recognizer",
      home: ObjectRecognizerWidget(),
    );
  }
}

class ObjectRecognizerWidget extends StatefulWidget {
  @override
  _ObjectRecognizerState createState() => _ObjectRecognizerState();
}

class _ObjectRecognizerState extends State<ObjectRecognizerWidget> {
  CameraController _cameraController;
  ObjectRecognizer _recognizer;
  ObjectRecognizerFactory _factory;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_cameraController.value.isInitialized) {
      return Container();
    }
    return AspectRatio(
        aspectRatio: _cameraController.value.aspectRatio,
        child: CameraPreview(_cameraController));
  }

  void _initializeCamera() async {
    _factory = new ObjectRecognizerFactory();
    _recognizer = _factory.createRecognizer(DLModelsEnum.SSD_COCO_MOBILE_NET);

    _cameraController =
        new CameraController(cameras[0], ResolutionPreset.veryHigh);

    _cameraController.initialize().then((_) async {
      await _cameraController
          .startImageStream((CameraImage image) => _processCameraImage(image));

      setState(() {});
    });
  }

  void _processCameraImage(CameraImage img) async {
    List recognitions = await _recognizer.detectObjectsInFrame(img);

    if (recognitions != null) {
      print(recognitions.length);
    }
  }
}

class _MyAppState extends State<ObjectRecognizerWidget> {
  File _image;
  List _recognitions;
  String _model = mobile;
  double _imageHeight;
  double _imageWidth;
  bool _busy = false;

  Uint8List imageToByteListFloat32(
      img.Image image, int inputSize, double mean, double std) {
    var convertedBytes = Float32List(1 * inputSize * inputSize * 3);
    var buffer = Float32List.view(convertedBytes.buffer);
    int pixelIndex = 0;
    for (var i = 0; i < inputSize; i++) {
      for (var j = 0; j < inputSize; j++) {
        var pixel = image.getPixel(j, i);
        buffer[pixelIndex++] = (img.getRed(pixel) - mean) / std;
        buffer[pixelIndex++] = (img.getGreen(pixel) - mean) / std;
        buffer[pixelIndex++] = (img.getBlue(pixel) - mean) / std;
      }
    }
    return convertedBytes.buffer.asUint8List();
  }

  Uint8List imageToByteListUint8(img.Image image, int inputSize) {
    var convertedBytes = Uint8List(1 * inputSize * inputSize * 3);
    var buffer = Uint8List.view(convertedBytes.buffer);
    int pixelIndex = 0;
    for (var i = 0; i < inputSize; i++) {
      for (var j = 0; j < inputSize; j++) {
        var pixel = image.getPixel(j, i);
        buffer[pixelIndex++] = img.getRed(pixel);
        buffer[pixelIndex++] = img.getGreen(pixel);
        buffer[pixelIndex++] = img.getBlue(pixel);
      }
    }
    return convertedBytes.buffer.asUint8List();
  }

  List<Widget> renderBoxes(Size screen) {
    if (_recognitions == null) return [];
    if (_imageHeight == null || _imageWidth == null) return [];

    double factorX = screen.width;
    double factorY = _imageHeight / _imageWidth * screen.width;
    Color blue = Color.fromRGBO(37, 213, 253, 1.0);
    return _recognitions.map((re) {
      return Positioned(
        left: re["rect"]["x"] * factorX,
        top: re["rect"]["y"] * factorY,
        width: re["rect"]["w"] * factorX,
        height: re["rect"]["h"] * factorY,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.all(Radius.circular(8.0)),
            border: Border.all(
              color: blue,
              width: 2,
            ),
          ),
          child: Text(
            "${re["detectedClass"]} ${(re["confidenceInClass"] * 100).toStringAsFixed(0)}%",
            style: TextStyle(
              background: Paint()..color = blue,
              color: Colors.white,
              fontSize: 12.0,
            ),
          ),
        ),
      );
    }).toList();
  }

  List<Widget> renderKeypoints(Size screen) {
    if (_recognitions == null) return [];
    if (_imageHeight == null || _imageWidth == null) return [];

    double factorX = screen.width;
    double factorY = _imageHeight / _imageWidth * screen.width;

    var lists = <Widget>[];
    _recognitions.forEach((re) {
      var color = Color((Random().nextDouble() * 0xFFFFFF).toInt() << 0)
          .withOpacity(1.0);
      var list = re["keypoints"].values.map<Widget>((k) {
        return Positioned(
          left: k["x"] * factorX - 6,
          top: k["y"] * factorY - 6,
          width: 100,
          height: 12,
          child: Text(
            "● ${k["part"]}",
            style: TextStyle(
              color: color,
              fontSize: 12.0,
            ),
          ),
        );
      }).toList();

      lists..addAll(list);
    });

    return lists;
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    List<Widget> stackChildren = [];

    if (_model == deeplab && _recognitions != null) {
      stackChildren.add(Positioned(
        top: 0.0,
        left: 0.0,
        width: size.width,
        child: _image == null
            ? Text('No image selected.')
            : Container(
                decoration: BoxDecoration(
                    image: DecorationImage(
                        alignment: Alignment.topCenter,
                        image: MemoryImage(_recognitions),
                        fit: BoxFit.fill)),
                child: Opacity(opacity: 0.3, child: Image.file(_image))),
      ));
    } else {
      stackChildren.add(Positioned(
        top: 0.0,
        left: 0.0,
        width: size.width,
        child: _image == null ? Text('No image selected.') : Image.file(_image),
      ));
    }

    if (_model == mobile) {
      stackChildren.add(Center(
        child: Column(
          children: _recognitions != null
              ? _recognitions.map((res) {
                  return Text(
                    "${res["index"]} - ${res["label"]}: ${res["confidence"].toStringAsFixed(3)}",
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 20.0,
                      background: Paint()..color = Colors.white,
                    ),
                  );
                }).toList()
              : [],
        ),
      ));
    } else if (_model == ssd || _model == yolo) {
      stackChildren.addAll(renderBoxes(size));
    } else if (_model == posenet) {
      stackChildren.addAll(renderKeypoints(size));
    }

    if (_busy) {
      stackChildren.add(const Opacity(
        child: ModalBarrier(dismissible: false, color: Colors.grey),
        opacity: 0.3,
      ));
      stackChildren.add(const Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('tflite example app'),
        actions: <Widget>[
          PopupMenuButton<String>(
            itemBuilder: (context) {
              List<PopupMenuEntry<String>> menuEntries = [
                const PopupMenuItem<String>(
                  child: Text(mobile),
                  value: mobile,
                ),
                const PopupMenuItem<String>(
                  child: Text(ssd),
                  value: ssd,
                ),
                const PopupMenuItem<String>(
                  child: Text(yolo),
                  value: yolo,
                ),
                const PopupMenuItem<String>(
                  child: Text(deeplab),
                  value: deeplab,
                ),
                const PopupMenuItem<String>(
                  child: Text(posenet),
                  value: posenet,
                )
              ];
              return menuEntries;
            },
          )
        ],
      ),
      body: Stack(
        children: stackChildren,
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Pick Image',
        child: Icon(Icons.image),
      ),
    );
  }
}
