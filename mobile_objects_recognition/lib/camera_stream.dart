import 'dart:async';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';

class CameraStream extends StatefulWidget {
  @override
  CameraStreamState createState() => CameraStreamState();
}

class CameraStreamState extends State<CameraStream> {
  List<CameraDescription> cameras;
  CameraController controller;

  @override
  void initState() async {
    super.initState();
    cameras = await availableCameras();
    controller = CameraController(cameras[0], ResolutionPreset.medium);
    controller.initialize().then((_) {
      if (!mounted) {
        return;
      }
      setState(() {});
    });
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!controller.value.isInitialized) {
      return Container();
    }
    return AspectRatio(
        aspectRatio: controller.value.aspectRatio,
        child: CameraPreview(controller));
  }
}
