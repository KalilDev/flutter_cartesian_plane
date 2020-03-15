import 'dart:async';
import 'dart:html';
import 'dart:typed_data';

import 'package:efficient_uint8_list/efficient_uint8_list.dart';

import '../process_image.dart';
import '../message.dart';

Map<String, dynamic> encodePixelData(PixelDataMessage msg) {
  print('encoded');
  return {
    'vals': msg.values,
    'lineSize': msg.lineSize,
    'width': msg.width,
    'height': msg.height,
    'colors': msg.colors
  };
}

PixelDataMessage decodePixelData(Map<dynamic, dynamic> msg) => PixelDataMessage(
    values: Uint16List.fromList((msg['vals'] as List).cast<int>()),
    lineSize: msg['lineSize'] as int,
    width: msg['width'] as int,
    height: msg['height'] as int,
    colors: Uint32List.fromList((msg['colors'] as List).cast<int>()));

void main() {
  // This is ran only on the worker!
  final dws = DedicatedWorkerGlobalScope.instance;
  MessagePort mainPort;
  dws.onMessage.listen((MessageEvent evt) {
    if (mainPort == null) {
      mainPort = evt.data['port'];
      mainPort.postMessage('ready');
      return;
    }
    if (!(evt.data is Map)) {
      print('WTF on Worker: ${evt.data}, ${evt.data.runtimeType}');
      return;
    }
    final msg = decodePixelData(evt.data);
    final bytes = processImage(msg);
    mainPort.postMessage(bytes.view);
  });
}

Future<PackedUint8List> processImageImpl(PixelDataMessage message) {
  print('Using worker impl');
  // This is ran only on main!
  final completer = Completer<PackedUint8List>();
  final w = Worker('worker_impl.dart.js');
  final msgChn = MessageChannel();
  w.postMessage({'port': msgChn.port1}, [msgChn.port1]);
  msgChn.port2.onMessage.listen((MessageEvent m) {
    // Messages received in main from the worker
    if (m.data is String && m.data as String == 'ready') {
      w.postMessage(encodePixelData(message));
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
