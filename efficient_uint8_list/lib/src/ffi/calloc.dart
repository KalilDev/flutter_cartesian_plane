import 'dart:ffi';
import 'dart:io';

import 'package:ffi/src/allocation.dart';

typedef PosixCallocNative = Pointer Function(IntPtr, IntPtr);
typedef PosixCalloc = Pointer Function(int, int);
final PosixCalloc posixCalloc =
    stdlib.lookupFunction<PosixCallocNative, PosixCalloc>('calloc');

Pointer<T> calloc<T extends NativeType>({int count = 1}) {
  Pointer<T> result;
  if (Platform.isWindows) {
    final totalSize = count * sizeOf<T>();
    result = winHeapAlloc(processHeap, /*flags=*/ 0x8, totalSize).cast();
  } else {
    result = posixCalloc(count, sizeOf<T>()).cast();
  }
  if (result.address == 0) {
    throw ArgumentError(
        'Couldn\'t allocate $count elements of size ${sizeOf<T>()}.');
  }
  return result;
}
