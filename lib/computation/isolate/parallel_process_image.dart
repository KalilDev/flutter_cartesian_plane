import 'dart:isolate';
import 'isolate_wrapper.dart';

import 'package:efficient_uint8_list/efficient_uint8_list.dart';
import '../common/message.dart';
import '../sync_process_image.dart';

Future<PackedUint8List> processImageImpl(PixelDataMessage message) {
  print('Using isolate impl');
  return runOnIsolate<PackedUint8List, PixelDataMessage>(
      wrappedProcessImage, message);
}

void wrappedProcessImage(SendPort mainSink) {
  final isolateStream = ReceivePort();
  mainSink.send(isolateStream.sendPort);

  isolateStream.listen((dynamic message) {
    mainSink.send(syncProcessImage(message as PixelDataMessage));
  });
}
