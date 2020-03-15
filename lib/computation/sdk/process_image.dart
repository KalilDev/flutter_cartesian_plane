import 'dart:developer';

import '../common/message.dart';

import '../common/internal_process_image.dart';
import 'package:efficient_uint8_list/efficient_uint8_list.dart';

PackedUint8List syncProcessImage(PixelDataMessage message) {
  Timeline.startSync('processImageDart');
  final bytes = internalProcessImage(message);
  Timeline.finishSync();
  
  return bytes;
}

Future<PackedUint8List> asyncProcessImage(PixelDataMessage message) {
  return Future.microtask(() => internalProcessImage(message));
}

// Can't run in parallel without isolate or html, this is here just to satisfy the contract of
// always having this function available.
Future<PackedUint8List> parallelProcessImage(PixelDataMessage message) => asyncProcessImage(message);
