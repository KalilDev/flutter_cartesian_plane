import '../common/message.dart';
import 'dart:typed_data';
import 'dart:html';
import '../sync_process_image.dart';

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
    final bytes = syncProcessImage(msg);
    mainPort.postMessage(bytes.view);
  });
}

PixelDataMessage decodePixelData(Map<dynamic, dynamic> msg) => PixelDataMessage(
    values: Uint16List.fromList((msg['vals'] as List).cast<int>()),
    lineSize: msg['lineSize'] as int,
    width: msg['width'] as int,
    height: msg['height'] as int,
    colors: Uint32List.fromList((msg['colors'] as List).cast<int>()));