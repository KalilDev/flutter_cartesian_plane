import 'dart:typed_data';
import '../packed_uint8_list.dart';

PackedUint8List createUint8List(int length) =>
    SafeUint8List(Uint8List(length));
