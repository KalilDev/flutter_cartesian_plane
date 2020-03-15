import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cartesian_plane/isolate/impl/stub_impl.dart';
import 'package:efficient_uint8_list/efficient_uint8_list.dart';
import '../cartesian_isolate.dart';
import '../cartesian_utils.dart';
import 'package:tuple/tuple.dart';

@visibleForTesting
Future<PackedUint8List> getFutureImage(
    IntSize sizePx, List<FunctionDef> defs, Rect coordinates, int lineSize,
    {FutureOr<PackedUint8List> Function(PixelDataMessage msg)
        imageConverter}) async {
  final timer = Stopwatch()..start();
  final valAllocTimer = Stopwatch();
  // Use the isolate/worker implementation by default
  imageConverter ??= futureProcessImage;
// We will make an List with all the x values as the idx and the y values and then we will add
// those to the image.
// This is an flattened 2d array basically. Its more performant than an
// array[sizePx.width] of arrays[defs.length].
  final width = sizePx.width & 0xffff;
  final height = sizePx.height & 0xffff;
  valAllocTimer.start();
  final values = Uint16List(width * defs.length);
  valAllocTimer.stop();
  print('took ${valAllocTimer.elapsedMicroseconds}us to alloc vals');

  // This was benchmarked on my Moto G5:
  // Lerp inside the loop:
  //     Average: 5415
  //     Median: 5770
  //     Max-Min Delta: 4501
  //     Times: [6556, 5728, 8277, 5812, 6182, 5878, 3861, 3849, 4231, 3776]
  // Lerp outside the loop (here):
  //     Average: 4691
  //     Median: 4396
  //     Max-Min Delta: 3817
  //     Times: [5670, 5212, 6937, 4295, 4498, 6864, 3948, 3120, 3130, 3245]
  final xPx = ui.lerpDouble(coordinates.left, coordinates.right, 1 / width) -
      coordinates.left;
  final yPx = ui.lerpDouble(coordinates.top, coordinates.bottom, 1 / height) -
      coordinates.top;

  var xValue = coordinates.left;
  for (var x = 0; x < width; x++) {
    var arrayIndex = x;
    for (var i = 0; i < defs.length; i++) {
      final F = defs[i].func;
      final yValue = F(xValue);
      // Reason: It simply isn't true (At least in this case)
      // Benchmark with ~/:
      //     Average: 8161
      //     Median: 8100
      //     Max-Min Delta: 6158
      // Benchmark with toInt():
      //     Average: 1371
      //     Median: 1344
      //     Max-Min Delta: 4320
      final yPixelDouble = (yValue - coordinates.top) / yPx;
      try {
        // ignore: division_optimization
        values[arrayIndex] = yPixelDouble.toInt();
      } on UnsupportedError catch (e) {
        if (((!yPixelDouble.isNegative) && yPixelDouble.isInfinite) ||
            yPixelDouble.isNaN) {
          print(yPixelDouble);
          values[arrayIndex] = height;
          continue;
        }
      }
      arrayIndex += width;
    }
    xValue += xPx;
  }
  timer.stop();
  print('Calculating every Y took ${timer.elapsedMicroseconds}');
  //print('Calculating every func took ${functionTimer.elapsedMicroseconds}');

// Let there be an async gap, this will avoid dropping frames.
  await Future.value(null);

  timer.reset();
  final colors = Uint32List.fromList(defs
      .map<int>((e) => e.color?.value ?? 0xFFFFFFFF)
      .toList(growable: false));
// Now we convert the Ys into an actual image.
  timer.start();
  final bytes = imageConverter(PixelDataMessage(
      values: values,
      width: width,
      height: height,
      lineSize: lineSize,
      colors: colors));
  timer.stop();
  print('Creating the image took ${timer.elapsedMicroseconds}');

  return bytes;
}

@visibleForTesting
String defaultDescription(double x, double y) =>
    '(x: ${x.toStringAsFixed(2)}, y: ${y.toStringAsFixed(2)})';

class CartesianPlane extends StatefulWidget {
  const CartesianPlane(
      {Rect coords,
      this.currentX,
      this.lineSize = 2,
      this.aspectRatio,
      this.defs})
      : coords = coords ?? const Rect.fromLTRB(-1, 1, 1, -1);
  final Rect coords;
  final double currentX;
  final double aspectRatio;
  final int lineSize;
  final List<FunctionDef> defs;

  @override
  _CartesianPlaneState createState() => _CartesianPlaneState();
}

Future<ui.Image> futurizedDecodeImagePixels(
    Uint8List bytes, int width, int height, ui.PixelFormat format) {
  final completer = Completer<ui.Image>();
  void callback(ui.Image result) {
    completer.complete(result);
  }

  try {
    ui.decodeImageFromPixels(bytes, width, height, format, callback);
  } catch (e) {
    completer.completeError(e);
  }
  return completer.future;
}

class _CartesianPlaneState extends State<CartesianPlane> {
  Tuple2<List<FunctionDef>, IntSize> currentProcessing;
  Tuple3<ui.Image, List<FunctionDef>, IntSize> currentImage;
  IntSize currentSize;

  Future<void> maybeUpdateImage() async {
    // The wanted image is already being processed
    if (currentProcessing != null &&
        listEquals<FunctionDef>(currentProcessing.item1, widget.defs) &&
        currentProcessing.item2 == currentSize) return;
    // The current image is already the wanted image
    if (currentImage != null &&
        listEquals<FunctionDef>(currentImage.item2, widget.defs) &&
        currentImage.item3 == currentSize) return;

    final defs = widget.defs;
    final size = currentSize;
    final coords = widget.coords;
    final lineSize = widget.lineSize;
    // We will need to process the image now
    final processing = Tuple2<List<FunctionDef>, IntSize>(defs, size);
    currentProcessing = processing;
    final bytes = await getFutureImage(size, defs, coords, lineSize * 4,
        imageConverter: processImageImpl);

    // Exit if a new image was scheduled
    if (processing != currentProcessing) return;

    final image = await futurizedDecodeImagePixels(
            bytes.view, size.width, size.height, ui.PixelFormat.rgba8888)
        .whenComplete(() {
      if (bytes is UnsafeUint8List) {
        // With ffi, bytes is an _Uint8ListPointer, which is implemented
        // with an pointer, therefore it is not managed by dart GC, so i need
        // to cleanup myself
        bytes.free();
      }
    });

    // Exit if a new image was scheduled
    if (processing != currentProcessing) {
      return image.dispose();
    }

    // Finally we update the widget
    currentProcessing = null;
    if (currentImage != null) {
      currentImage.item1.dispose();
    }
    if (mounted) {
      setState(() {
        currentImage = Tuple3(image, widget.defs, currentSize);
      });
    } else {
      image.dispose();
    }
  }

  @override
  void dispose() {
    if (currentImage != null) {
      currentImage.item1.dispose();
      currentImage = null;
    }
    super.dispose();
  }

  Iterable<Tuple3<Offset, String, Color>> getPoints(Size s) sync* {
    for (var i = 0; i < widget.defs.length; i++) {
      final F = widget.defs[i].func;
      final c = widget.defs[i].color;
      final describe = widget.defs[i].describe ?? defaultDescription;
      final y = F(widget.currentX);
      final xPos = inverseLerp(
              widget.coords.left, widget.coords.right, widget.currentX) *
          s.width;
      final yPos =
          inverseLerp(widget.coords.top, widget.coords.bottom, y) * s.height;
      final description = describe(widget.currentX, y);
      yield Tuple3(Offset(xPos, yPos), description, c);
    }
  }

  Iterable<Tuple3<Offset, double, Color>> getDerivatives(Size s) sync* {
    for (var i = 0; i < widget.defs.length; i++) {
      final F = widget.defs[i].func;
      final D = widget.defs[i].deriv;
      if (D == null) continue;
      final c = widget.defs[i].color;
      final xPos = inverseLerp(
              widget.coords.left, widget.coords.right, widget.currentX) *
          s.width;
      final yPos = inverseLerp(
              widget.coords.top, widget.coords.bottom, F(widget.currentX)) *
          s.height;
      // The derivative works for an 1:1 cartesian plane, which isn't the case always
      // We need to scale it accordingly
      final xSize = s.width / widget.coords.width.abs();
      final ySize = s.height / widget.coords.height.abs();
      final d = D(widget.currentX) * (ySize / xSize);
      yield Tuple3(Offset(xPos, yPos), d, c);
    }
  }

  Iterable<Tuple3<Offset, String, Color>> getNames(Size s) sync* {
    for (var i = 0; i < widget.defs.length; i++) {
      final F = widget.defs[i].func;
      final name = widget.defs[i].name;
      if (name == null) continue;
      final c = widget.defs[i].color;
      final yPos = inverseLerp(
              widget.coords.top, widget.coords.bottom, F(widget.coords.left)) *
          s.height;
      yield Tuple3(Offset(0, yPos), name, c);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
        aspectRatio: widget.aspectRatio ??
            widget.coords.width.abs() / widget.coords.height.abs(),
        child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
          print(constraints);
          currentSize = IntSize.ceil(constraints.biggest * 4);
          maybeUpdateImage();
          return Stack(
            children: <Widget>[
              if (widget.currentX != null)
                ClipRect(
                  child: CustomPaint(
                    painter: _CartesianScalePaint(
                        points: getPoints(constraints.biggest),
                        derivatives: getDerivatives(constraints.biggest),
                        names: getNames(constraints.biggest),
                        lineSize: widget.lineSize * 1.0,
                        textStyle: DefaultTextStyle.of(context).style),
                    size: constraints.biggest,
                  ),
                ),
              if (currentImage != null)
                CustomPaint(
                  painter: UiImagePainter(currentImage.item1),
                  size: constraints.biggest,
                )
            ],
          );
        }));
  }
}

class UiImagePainter extends CustomPainter {
  UiImagePainter(this.image);
  final ui.Image image;
  @override
  void paint(ui.Canvas canvas, ui.Size size) {
    canvas.drawImageRect(
        image,
        Rect.fromLTRB(0, 0, image.width * 1.0, image.height * 1.0),
        Rect.fromPoints(Offset.zero, size.bottomRight(Offset.zero)),
        Paint());
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    if (oldDelegate is UiImagePainter) {
      return oldDelegate.image == image;
    }
    return false;
  }
}

class _CartesianScalePaint extends CustomPainter {
  _CartesianScalePaint(
      {this.points,
      this.derivatives,
      this.names,
      this.lineSize,
      this.textStyle});
  final Iterable<Tuple3<Offset, String, Color>> points;
  final Iterable<Tuple3<Offset, double, Color>> derivatives;
  final Iterable<Tuple3<Offset, String, Color>> names;
  final double lineSize;
  final TextStyle textStyle;

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;

  @override
  void paint(Canvas canvas, Size size) {
    void drawText(Offset start, String text, [Color color]) {
      final tp = TextPainter(
          text: TextSpan(
              text: text,
              style:
                  color != null ? textStyle.copyWith(color: color) : textStyle),
          textDirection: TextDirection.ltr);

      tp.layout();
      final dy =
          (start.dy + tp.height).clamp(tp.height, size.height) - tp.height;
      final dx = (start.dx + tp.width).clamp(tp.width, size.width) - tp.width;
      tp.paint(canvas, Offset(dx, dy));
    }

    for (var point in derivatives) {
      final yStart = point.item1.dx * point.item2 + point.item1.dy;
      final yEnd = point.item1.dy - (size.width - point.item1.dx) * point.item2;
      canvas.drawLine(
          Offset(0, yStart),
          Offset(size.width, yEnd),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = lineSize / 2
            ..color = point.item3);
    }
    for (var point in points) {
      canvas.drawCircle(point.item1, lineSize, Paint()..color = point.item3);
      drawText(point.item1, point.item2);
    }
    for (var point in names) {
      drawText(point.item1, point.item2, point.item3);
    }
  }
}
