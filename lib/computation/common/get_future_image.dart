import 'dart:developer';
import 'dart:typed_data';
import 'package:efficient_uint8_list/efficient_uint8_list.dart';
import '../../cartesian_utils.dart' show FunctionDef, IntSize, Coordinates, lerpDouble;
import 'dart:async';
import 'message.dart';
import '../async_process_image.dart';

Future<PackedUint8List> getFutureImage(
    IntSize sizePx, List<FunctionDef> defs, Coordinates coords, int lineSize,
    {FutureOr<PackedUint8List> Function(PixelDataMessage msg)
        imageConverter}) async {
  // Use the async implementation by default
  imageConverter ??= asyncProcessImage;

  Timeline.startSync('calculateYValues');
  // We will make an List with all the x values as the idx and the y values and then we will add
  // those to the image.
  // This is an flattened 2d array basically. Its more performant than an
  // array[sizePx.width] of arrays[defs.length].
  final width = sizePx.width & 0xffff;
  final height = sizePx.height & 0xffff;
  final values = Uint16List(width * defs.length);

  // Lerp inside the loop takes about 5415us,
  // while the lerp here takes about 4396us.
  final xPx = lerpDouble(coords.xMin, coords.xMax, 1 / width) -
      coords.xMin;
  final yPx = lerpDouble(coords.yMax, coords.yMin, 1 / height) -
      coords.yMax;

  var xValue = coords.xMin;
  for (var x = 0; x < width; x++, xValue += xPx) {
    var arrayIndex = x;
    for (var i = 0; i < defs.length; i++, arrayIndex += width) {
      final F = defs[i].func;
      final yValue = F(xValue);
      // With ~/ truncating this takes about 8161us,
      // while with toInt it takes about 1371us.
      final yPixelDouble = (yValue - coords.yMax) / yPx;
      try {
        values[arrayIndex] = yPixelDouble.toInt();
      } on UnsupportedError {
        // Testing this condition for every value takes about 3000us,
        // while throwing and catching takes about 2700us.
        if (((!yPixelDouble.isNegative) && yPixelDouble.isInfinite) ||
            yPixelDouble.isNaN) {
          values[arrayIndex] = height;
        }
      }
    }
  }
  
  Timeline.finishSync();

  // Let there be an async gap, this will avoid dropping frames.
  await Future.value(null);

  final colors = Uint32List.fromList(defs
      .map<int>((e) => e.color ?? 0xFFFFFFFF).toList(growable: false));
  // Now we convert the Ys into an actual image.
  final bytes = await imageConverter(PixelDataMessage(
      values: values,
      width: width,
      height: height,
      lineSize: lineSize,
      colors: colors));

  return bytes;
}