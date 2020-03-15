import 'dart:collection';
import 'dart:typed_data';

abstract class PackedUint8List extends ListBase<int> {
  Uint8List get view;
}

class SafeUint8List extends ListBase<int> implements PackedUint8List {
  SafeUint8List(this._bytes);
  final Uint8List _bytes;

  Uint8List get view => _bytes;

  int get length => _bytes.length;
  set length(int l) => _bytes.length = l;

  @override
  int operator [](int index) => _bytes[index];

  @override
  void operator []=(int index, int value) => _bytes[index] = value;
}

abstract class UnsafeUint8List extends ListBase<int>
    implements PackedUint8List {
  SafeUint8List safeCopy();
  void free();
}
