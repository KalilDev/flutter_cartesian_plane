import 'package:efficient_uint8_list/efficient_uint8_list.dart';
import 'dart:typed_data';
import 'dart:async';
import 'dart:io';
import 'dart:convert';

Stream<String> readLine() =>
    stdin.transform(utf8.decoder).transform(const LineSplitter());

void main(List<String> args) async {
  var size;
  if (args != null && args.isEmpty) {
    print('How big should the Uint8List be?');
    var line = await readLine().first;
    size = int.parse(line);
  } else {
    size = int.parse(args.first);
    print('The Uint8List will be $size bytes');
  }
  final timer = Stopwatch()..start();
  var list = createUint8List(size);
  timer.stop();
  if (list is UnsafeUint8List) {
    (list as UnsafeUint8List).free();
    print(
        'This platform has ffi, so the efficient ${list.runtimeType} was used, and took: ${timer.elapsedMicroseconds}us');
    timer
      ..reset()
      ..start();
    list = SafeUint8List(Uint8List(size));
    timer.stop();
    print(
        'Using the regular ${list.runtimeType} impl would take ${timer.elapsedMicroseconds}us on this platform');
  } else {
    print(
        'This platform does not have ffi, so the regular ${list.runtimeType} was used, and took: ${timer.elapsedMicroseconds}us');
  }
}
