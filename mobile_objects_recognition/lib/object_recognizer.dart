import 'package:camera/camera.dart';
import 'package:tflite/tflite.dart';

abstract class ObjectRecognizer {
  Future<List> detectObjectsInFrame(CameraImage img);
}

class SsdCocoMobileNetObjectRecognizer extends ObjectRecognizer {
  bool _isDetecting = false;

  @override
  Future<List> detectObjectsInFrame(CameraImage img) async {
    int startTime = new DateTime.now().millisecondsSinceEpoch;
    if (!_isDetecting) {
      _isDetecting = true;
      var recognitions = await Tflite.detectObjectOnFrame(
        bytesList: img.planes.map((plane) {
          return plane.bytes;
        }).toList(),
        model: "SSDMobileNet",
        imageHeight: img.height,
        imageWidth: img.width,
        imageMean: 127.5,
        imageStd: 127.5,
        numResultsPerClass: 1,
        threshold: 0.4,
      );

      int endTime = new DateTime.now().millisecondsSinceEpoch;
      print("Detection took ${endTime - startTime}");
      _isDetecting = false;

      return recognitions;
    } else {
      return null;
    }
  }
}
