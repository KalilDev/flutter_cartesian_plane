import 'sdk/create_uint8_list.dart'
    if (dart.library.ffi) 'ffi/create_uint8_list.dart';
import 'packed_uint8_list.dart';

PackedUint8List createUint8List(int length) => createUint8ListImpl(length);