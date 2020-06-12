import 'package:camera/camera.dart';
import 'package:tflite/tflite.dart';

abstract class ObjectRecognizer {
  detectObjectsInFrame(CameraImage img);
}

class SsdCocoMobileNetObjectRecognizer extends ObjectRecognizer {
  bool _isDetecting = false;

  @override
  detectObjectsInFrame(CameraImage img) {
    int startTime = new DateTime.now().millisecondsSinceEpoch;
    if (!_isDetecting) {
      _isDetecting = true;
      Tflite.detectObjectOnFrame(
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
      ).then((recognitions) {
        int endTime = new DateTime.now().millisecondsSinceEpoch;
        print("Detection took ${endTime - startTime}");
        _isDetecting = false;
      });
    }
  }
}
