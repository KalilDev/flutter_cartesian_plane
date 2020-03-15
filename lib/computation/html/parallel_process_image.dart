import 'dart:async';
import 'dart:html';
import 'dart:typed_data';

import 'package:efficient_uint8_list/efficient_uint8_list.dart';

import '../common/message.dart';

Map<String, dynamic> _encodePixelData(PixelDataMessage msg) {
  print('encoded');
  return {
    'vals': msg.values,
    'lineSize': msg.lineSize,
    'width': msg.width,
    'height': msg.height,
    'colors': msg.colors
  };
}

Future<PackedUint8List> asyncProcessImage(PixelDataMessage message) {
  final completer = Completer<PackedUint8List>();
  final w = Worker('process_image_worker.dart.js');
  final msgChn = MessageChannel();
  w.postMessage({'port': msgChn.port1}, [msgChn.port1]);
  msgChn.port2.onMessage.listen((MessageEvent m) {
    // Messages received in main from the worker
    if (m.data is String && m.data as String == 'ready') {
      w.postMessage(_encodePixelData(message));
      return;
    }
    if (m.data is List) {
      completer
          .complete(SafeUint8List(Uint8List.fromList(m.data as List<int>)));
      w.terminate();
      return;
    }
    print('WTF on main: $m, ${m.runtimeType}');
  });
  return completer.future;
}
