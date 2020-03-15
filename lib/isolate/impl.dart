import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode;
import 'message.dart';

import 'impl/stub_impl.dart' as stub;

// ignore: uri_does_not_exist
import 'impl/stub_impl.dart'
    // ignore: uri_does_not_exist
    if (dart.library.io) 'impl/isolate_impl.dart'
    // ignore: uri_does_not_exist
    if (dart.library.html) 'impl/worker_impl.dart';

import 'package:efficient_uint8_list/efficient_uint8_list.dart';

// Processing the image on debug is quite slow, so use an isolate.
final bool _useParallel = !kIsWeb && kDebugMode;

final Future<PackedUint8List> Function(PixelDataMessage message)
    futureProcessImage =
    _useParallel ? processImageImpl : stub.processImageImpl;
