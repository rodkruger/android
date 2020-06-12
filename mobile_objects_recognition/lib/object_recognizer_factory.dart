import 'package:tflite/tflite.dart';
import 'package:mobile_objects_recognition/dl_models_enum.dart';
import 'package:mobile_objects_recognition/object_recognizer.dart';

class ObjectRecognizerFactory {
  ObjectRecognizer createRecognizer(DLModelsEnum model) {
    Tflite.close();

    switch (model) {
      case DLModelsEnum.SSD_COCO_MOBILE_NET:
        Tflite.loadModel(
                model: "assets/coco_ssd_mobilenet_v1_1.0_quant.tflite",
                labels: "assets/coco_ssd_mobilenet_v1_1.0_quant.txt")
            .then((value) => print(value));
        return new SsdCocoMobileNetObjectRecognizer();

      case DLModelsEnum.YOLOV2:
        Tflite.loadModel(
                model: "assets/yolov2_tiny.tflite",
                labels: "assets/yolov2_tiny.txt")
            .then((value) => print(value));
        break;

      case DLModelsEnum.MOBILE_NET:
        Tflite.loadModel(
                model: "assets/mobilenet_v1_1.0_224_quant.tflite",
                labels: "assets/mobilenet_v1_1.0_224_quant.txt")
            .then((value) => print(value));
        break;

        Tflite.loadModel(
          model: "assets/yolov2_tiny.tflite",
          labels: "assets/yolov2_tiny.txt",
        );
    }

    /*
    Tflite.loadModel(
        model: "assets/coco_ssd_mobilenet_v1_1.0_quant.tflite",
        labels: "assets/coco_ssd_mobilenet_v1_1.0_quant.txt");

    Tflite.loadModel(model: "assets/deeplabv3_257_mv_gpu.tflite");

    Tflite.loadModel(
        model:
            "assets/posenet_mobilenet_v1_100_257x257_multi_kpt_stripped.tflite");

    Tflite.loadModel(
      model: "assets/mobilenet_v1_1.0_224_quant.tflite",
      labels: "assets/mobilenet_v1_1.0_224_quant.txt",
    );
    */
  }
}
