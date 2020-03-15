import 'dart:typed_data';
import 'package:ffi/ffi.dart';
import 'dart:ffi' as ffi;

import '../message.dart';

typedef _process_image_c = ffi.Pointer<ffi.Uint8> Function(
    ffi.Uint16 width,
    ffi.Uint16 height,
    ffi.Pointer<ffi.Uint32> colors,
    ffi.Uint8 defCount,
    ffi.Pointer<ffi.Uint16> values,
    ffi.Uint32 valueCount,
    ffi.Uint8 lineSize);
typedef _process_image_dart = ffi.Pointer<ffi.Uint8> Function(
    int width,
    int height,
    ffi.Pointer<ffi.Uint32> colors,
    int defCount,
    ffi.Pointer<ffi.Uint16> values,
    int valueCount,
    int lineSize);

extension on Uint8List {
  ffi.Pointer<ffi.Uint8> alloc() {
    final ptr = allocate<ffi.Uint8>(count: length);
    for (var i = 0; i < length; i++) {
      ptr[i] = this[i];
    }
    return ptr;
  }
}

extension on Uint16List {
  ffi.Pointer<ffi.Uint16> alloc() {
    final ptr = allocate<ffi.Uint16>(count: length);
    for (var i = 0; i < length; i++) {
      ptr[i] = this[i];
    }
    return ptr;
  }
}

extension on Uint32List {
  ffi.Pointer<ffi.Uint32> alloc() {
    final ptr = allocate<ffi.Uint32>(count: length);
    for (var i = 0; i < length; i++) {
      ptr[i] = this[i];
    }
    return ptr;
  }
}

Uint8List cProcessImage(PixelDataMessage data) {
  final dylib = ffi.DynamicLibrary.open('libprocessImage.so');
  final process_image = dylib
      .lookupFunction<_process_image_c, _process_image_dart>('process_image');
  final colors = data.colors.alloc();
  final values = data.values.alloc();

  final timer = Stopwatch()..start();
  final bytes = process_image(data.width, data.height, colors,
      data.colors.length, values, data.values.length, data.lineSize);
  timer.stop();
  print('C impl took ${timer.elapsedMicroseconds}');

  return bytes.asTypedList(4 * data.width * data.height);
}
