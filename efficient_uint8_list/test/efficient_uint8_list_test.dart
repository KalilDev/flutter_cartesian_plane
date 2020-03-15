import 'dart:typed_data';

import 'package:efficient_uint8_list/efficient_uint8_list.dart';
import 'package:test/test.dart';

void main() {
  group('A group of tests', () {
    setUp(() {
    });

    test('First Test', () {
      final list = createUint8List(1000);
      expect(list.view is Uint8List, true);
      print(list.view);
    });
  });
}
