import '../message.dart';

import '../process_image.dart';
import 'package:efficient_uint8_list/efficient_uint8_list.dart';

Future<PackedUint8List> processImageImpl(PixelDataMessage message) {
  print('Using stub impl');
  return Future.microtask(() => processImage(message));
}
