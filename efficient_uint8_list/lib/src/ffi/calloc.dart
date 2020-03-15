import 'dart:ffi';
import 'dart:io';

import 'package:ffi/src/allocation.dart';

typedef PosixCallocNative = Pointer Function(IntPtr, IntPtr);
typedef PosixCalloc = Pointer Function(int, int);
final PosixCalloc posixCalloc =
    stdlib.lookupFunction<PosixCallocNative, PosixCalloc>("calloc");

Pointer<Uint8> callocUint8({int count = 1}) {
  Pointer<Uint8> result;
  if (Platform.isWindows) {
    final int totalSize = count * sizeOf<Uint8>();
    result = winHeapAlloc(processHeap, /*flags=*/ 0x8, totalSize).cast();
  } else {
    result = posixCalloc(count, sizeOf<Uint8>()).cast();
  }
  if (result.address == 0) {
    throw ArgumentError(
        "Could not allocate $count elements of size ${sizeOf<Uint8>()}.");
  }
  return result;
}
