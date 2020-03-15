import 'dart:typed_data';

import 'package:meta/meta.dart';

@immutable
class PixelDataMessage {
  const PixelDataMessage(
      {this.values, this.colors, this.width, this.height, this.lineSize});
  final Uint16List values;
  final Uint32List colors;
  final int width;
  final int height;
  final int lineSize;
}
