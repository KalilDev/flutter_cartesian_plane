import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';

import '../packed_uint8_list.dart';
import 'calloc.dart';
import 'package:ffi/ffi.dart' as ffi show free;

class _Uint8ListPointer extends UnsafeUint8List {
  factory _Uint8ListPointer._allocate(int length) {
    // Throws if it cant allocate
    final pointer = callocUint8(count: length);

    return _Uint8ListPointer._(pointer, length);
  }

  _Uint8ListPointer._(this._pointer, this._length);
  final Pointer<Uint8> _pointer;
  final int _length;
  bool wasDisposed = false;

  @override
  SafeUint8List safeCopy() {
    final safe = Uint8List(_length);
    final unsafe = view;
    for (var i = 0; i < _length; i++) {
      safe[i] = unsafe[i];
    }
    return SafeUint8List(safe);
  }

  @override
  void free() {
    ffi.free(_pointer);
    wasDisposed = true;
  }

  @override
  Uint8List get view {
    if (wasDisposed) {
      throw UnsupportedError(
          'The underlying pointer was freed! This Uint8List is unavaible');
    }
    return _pointer.asTypedList(_length);
  }

  @override
  int get length => _length;

  @override
  set length(int l) => UnsupportedError('You can\'t resize a pointer!');

  @override
  int operator [](int index) => _pointer[index];

  @override
  void operator []=(int index, int value) => _pointer[index] = value;
}

PackedUint8List createUint8ListImpl(int length) =>
    _Uint8ListPointer._allocate(length);
