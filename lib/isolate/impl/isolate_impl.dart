import 'dart:isolate';
import '../isolate_wrapper.dart';

import '../process_image.dart';
import 'package:efficient_uint8_list/efficient_uint8_list.dart';
import '../message.dart';

Future<PackedUint8List> processImageImpl(PixelDataMessage message) {
  print('Using isolate impl');
  return runOnIsolate<PackedUint8List, PixelDataMessage>(
      wrappedProcessImage, message);
}

void wrappedProcessImage(SendPort mainSink) {
  final isolateStream = ReceivePort();
  mainSink.send(isolateStream.sendPort);

  isolateStream.listen((dynamic message) {
    mainSink.send(processImage(message as PixelDataMessage));
  });
}
