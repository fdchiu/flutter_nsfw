import 'dart:async';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_nsfw/flutter_nsfw.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:io' show Directory, File, Platform;
import 'package:path_provider/path_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

void main() {
  runApp(MyApp());
}

class NSFWDetector {
  NSFWDetector(this.modelPath, this.enableLog, this.isOpenGPU, this.numThreads);

  final String modelPath;
  final bool enableLog;
  final bool isOpenGPU;
  final int numThreads;

  bool isInitialized = false;

  Future<dynamic> detectInPhoto(String photoPath) async {
    if (!isInitialized) {
      Directory appDocDir = await getApplicationDocumentsDirectory();
      String appDocPath = appDocDir.path;
      var file = File(appDocPath + "/nsfw.tflite");
      if (!file.existsSync()) {
        var data = await rootBundle.load("assets/nsfw.tflite");
        final buffer = data.buffer;
        await file.writeAsBytes(
            buffer.asUint8List(data.offsetInBytes, data.lengthInBytes));
      }
      await FlutterNsfw.initNsfw(
        file.path,
      );
      isInitialized = true;
    }

    return FlutterNsfw.getPhotoNSFWScore(photoPath);
  }

  Future<dynamic> detectVideo(
    String videoPath,
    double nsfwThreshold,
    int width,
    int height,
  ) async {
    if (!isInitialized) {
      Directory appDocDir = await getApplicationDocumentsDirectory();
      String appDocPath = appDocDir.path;
      var file = File(appDocPath + "/nsfw.tflite");
      if (!file.existsSync()) {
        var data = await rootBundle.load("assets/nsfw.tflite");
        final buffer = data.buffer;
        await file.writeAsBytes(
            buffer.asUint8List(data.offsetInBytes, data.lengthInBytes));
      }
      await FlutterNsfw.initNsfw(
        file.path,
      );
      isInitialized = true;
    }
    final result = await FlutterNsfw.detectNSFWVideo(
        videoPath: videoPath,
        nsfwThreshold: nsfwThreshold,
        frameWidth: width,
        frameHeight: height,
        durationPerFrame: 1000);
    if (result != null) {
      print('the result is true');
      return result as bool;
    } else {
      print('this result is false');
      return false;
    }
  }
}

class MyApp extends StatefulWidget {
  const MyApp({
    Key? key,
  }) : super(key: key);
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  NSFWDetector _nsfwDetector =
      NSFWDetector('assets/model/nsfw.tflite', true, true, 2);
  Future<dynamic> detectNSFWImage(String photo) async {
    final nsfwStatus = await _nsfwDetector.detectInPhoto(photo);
    if (nsfwStatus > 0.80) {
      return true;
    } else {
      return false;
    }
  }

  Future<dynamic> detectNSFWVideo(String video, int width, int height) async {
    final nsfwStatus =
        await _nsfwDetector.detectVideo(video, 0.70, width, height);
    return nsfwStatus ?? false;
  }

  String imgPath = '';
  bool _isNSFW = false;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (imgPath.isNotEmpty)
                Center(
                    child: Image.file(
                  File(imgPath),
                  width: 300,
                  height: 300,
                  fit: BoxFit.cover,
                )),
              Text('The result is : $_isNSFW'),
              ElevatedButton(
                child: Text('Pick image'),
                onPressed: () async {
                  if(Platform.isMacOS) {
                    FilePickerResult? filePick = await FilePicker.platform.pickFiles();
                    if (filePick != null) {
                      final imageFile = filePick.files.single.path;
                      //final imageFile = '/Volumes/Macintosh HD/Users/david/Library/Containers/B0419353-BEDE-4806-90C8-EE5D5933DEAF/Data/Documents/sd_output383389.jpeg';
                      if(imageFile != null) {
                        setState(() {
                          imgPath = imageFile;
                        });

                      }
                      final result = await detectNSFWImage(imgPath);
                      setState((){
                      _isNSFW = result;
                      });
                    }
                  } else {
                    final ImagePicker _picker = ImagePicker();
                    final XFile? image =
                    await _picker.pickImage(source: ImageSource.gallery);

                    if (image != null) {
                      setState(() {
                        imgPath = image.path;
                      });

                      final result = await detectNSFWImage(imgPath);
                      setState((){
                        _isNSFW = result;
                      });
                    }
                  }
                },
              ),
              Text('The video is $_isNSFW'),
              ElevatedButton(
                child: Text('Pick Video'),
                onPressed: () {
                  final ImagePicker _picker = ImagePicker();
                  _picker
                      .pickVideo(source: ImageSource.gallery)
                      .then((videoFile) {
                    if (videoFile != null) {
                      String videoPath = '';
                      setState(() {
                        videoPath = videoFile.path;
                      });
                      detectNSFWVideo(videoPath, 300, 200).then((isNSFW) {
                        setState(() {
                          _isNSFW = isNSFW;
                        });
                      });
                    }
                  });
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
