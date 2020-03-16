import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';
import 'package:ffi/ffi.dart';
import 'dart:ffi' as ffi;
// ignore: undefined_shown_name
import 'package:efficient_uint8_list/efficient_uint8_list.dart' show calloc, Uint8ListPointer, PackedUint8List;

import '../sdk/process_image.dart' as sdk_impl;
import '../common/message.dart';

typedef _processImageNative = ffi.Pointer<ffi.Uint8> Function(
    ffi.Uint16 width,
    ffi.Uint16 height,
    ffi.Pointer<ffi.Uint32> colors,
    ffi.Uint8 defCount,
    ffi.Pointer<ffi.Uint16> values,
    ffi.Uint32 valueCount,
    ffi.Uint8 lineSize,
    ffi.Pointer<ffi.Uint8> bytes);
typedef _processImageDart = ffi.Pointer<ffi.Uint8> Function(
    int width,
    int height,
    ffi.Pointer<ffi.Uint32> colors,
    int defCount,
    ffi.Pointer<ffi.Uint16> values,
    int valueCount,
    int lineSize,
    ffi.Pointer<ffi.Uint8> bytes);

ffi.Pointer<ffi.Uint32> _allocUint32(Uint32List l) {
  final ptr = allocate<ffi.Uint32>(count: l.length);
  for (var i = 0; i < l.length; i++) {
    ptr[i] = l[i];
  }
  return ptr;
}

ffi.Pointer<ffi.Uint16> _allocUint16(Uint16List l) {
  final ptr = allocate<ffi.Uint16>(count: l.length);
  for (var i = 0; i < l.length; i++) {
    ptr[i] = l[i];
  }
  return ptr;
}

ffi.DynamicLibrary _libprocessImage() {
  try {
    return ffi.DynamicLibrary.open('libprocessImage.so');
  } on ArgumentError {
    print('The library could not be loaded, so the dart fallback will be used');
    return null;
  }
}
final _processImageDart _processImage = _libprocessImage()?.lookupFunction<_processImageNative, _processImageDart>('process_image');

PackedUint8List syncProcessImage(PixelDataMessage data) {
  if (_processImage == null) {
    return sdk_impl.syncProcessImage(data);
  }

  final colors = _allocUint32(data.colors);
  final values = _allocUint16(data.values);
  final byteCount = 4 * data.width * data.height;

  ffi.Pointer<ffi.Uint8> pointer = calloc<ffi.Uint8>(count: byteCount);

  Timeline.startSync('processImageNative');
  
  _processImage(data.width, data.height, colors,
      data.colors.length, values, data.values.length, data.lineSize, pointer);
  
  Timeline.finishSync();

  free(colors);
  free(values);
  // ignore: undefined_function
  final packed = Uint8ListPointer(pointer, byteCount);

  return packed;
}

// There isn't anything that can be delayed on the native implementation
Future<PackedUint8List> asyncProcessImage(PixelDataMessage data) => _processImage == null ? sdk_impl.asyncProcessImage(data) : Future<PackedUint8List>.microtask(()=>syncProcessImage(data));
