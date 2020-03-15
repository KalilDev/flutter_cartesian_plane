import 'package:flutter_cartesian_plane/cartesian_utils.dart' show MinColor;

import 'message.dart';
import 'package:efficient_uint8_list/efficient_uint8_list.dart';

PackedUint8List internalProcessImage(PixelDataMessage data) {
  final byteCount = 4 * data.width * data.height;
  final bytes = createUint8List(byteCount);

  final sizeOfRow = 4 * data.width;
  final defCount = data.colors.length;
  

  final initialY = List<int>.generate(defCount, (int i) => i * data.width);

  // There are two loops because data.values is an 2d array
  for (var x = 0; x < data.width; x++) {
    for (var i = 0; i < defCount; i++) {
      final y = data.values[x + initialY[i]];
      final c = data.colors[i];
      final initialByteIdx = y * sizeOfRow + x * 4;
      for (var py = 0; py < data.lineSize; py++) {
        // Least Significant Bit
        final lsb = py & 0x1;
        // Table of truth:
        // lsb  | out
        //  0x0 |  1
        //  0x1 | -1
        final signBit = -1 * lsb + (~lsb & 0x1);
        // Multiply by the sign and divide by two.
        // py + lsb is there so 0 does not appear twice.
        // Table of truth:
        //  py     |  (py + lsb) >> 0x1 | int | lsb | signBit
        //  0x0000 | 0x0000             | 0   | 0x0 |  1
        //  0x0001 | 0x0001             | 1   | 0x1 | -1
        //  0x0010 | 0x0001             | 1   | 0x0 |  1
        //  0x0011 | 0x0010             | 2   | 0x1 | -1
        //  0x0100 | 0x0010             | 2   | 0x0 |  1
        //  0x0101 | 0x0011             | 3   | 0x1 | -1
        //  0x0110 | 0x0011             | 3   | 0x0 |  1
        //  0x0111 | 0x0100             | 4   | 0x1 | -1
        //  0x1000 | 0x0100             | 4   | 0x0 |  1
        //  0x1001 | 0x0101             | 5   | 0x1 | -1
        //  0x1010 | 0x0101             | 5   | 0x0 |  1
        //  0x1011 | 0x0110             | 6   | 0x1 | -1
        //  0x1100 | 0x0110             | 6   | 0x0 |  1
        //  0x1101 | 0x0111             | 7   | 0x1 | -1
        //  0x1110 | 0x0111             | 7   | 0x0 |  1
        //  0x1111 | 0x1000             | 8   | 0x1 | -1
        final pyOffset = signBit * ((py + lsb) >> 0x1);
        final byteIdx = initialByteIdx + pyOffset * sizeOfRow;
        if (byteIdx < 0 || byteIdx + 3 >= byteCount) continue;
        // Ok, now that we have the byte index we will set the color.
        bytes[byteIdx] = MinColor.redVal(c);
        bytes[byteIdx + 1] = MinColor.greenVal(c);
        bytes[byteIdx + 2] = MinColor.blueVal(c);
        bytes[byteIdx + 3] = MinColor.alphaVal(c);
      }
    }
  }
  return bytes;
}
