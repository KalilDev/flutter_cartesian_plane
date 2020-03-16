import 'dart:isolate';
import 'isolate_wrapper.dart';

import 'package:efficient_uint8_list/efficient_uint8_list.dart';
import '../common/message.dart';
import '../common/internal_process_image.dart' as sdk;

Future<PackedUint8List> parallelProcessImage(PixelDataMessage message) {
  return runOnIsolate<PackedUint8List, PixelDataMessage>(
      wrappedProcessImage, message);
}

void wrappedProcessImage(SendPort mainSink) {
  final isolateStream = ReceivePort();
  mainSink.send(isolateStream.sendPort);

  isolateStream.listen((dynamic message) {
    // We cannot pass native types between isolates yet :/
    mainSink.send(sdk.internalProcessImage(message as PixelDataMessage, false));
  });
}
