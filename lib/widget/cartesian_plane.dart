import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:efficient_uint8_list/efficient_uint8_list.dart';
import '../cartesian_computation.dart';
import '../cartesian_utils.dart';
import 'package:tuple/tuple.dart';

extension on Size {
  IntSize round() => IntSize(width.round(), height.round());
  IntSize floor() => IntSize(width.floor(), height.floor());
  IntSize ceil() => IntSize(width.ceil(), height.ceil());
}

extension CoordinatesRect on Rect {
  Coordinates toCoords() => Coordinates(left, bottom, right, top);
}

@visibleForTesting
String defaultDescription(double x, double y) =>
    '(x: ${x.toStringAsFixed(2)}, y: ${y.toStringAsFixed(2)})';

class CartesianPlane extends StatefulWidget {
  const CartesianPlane(
      {Coordinates coords,
      this.currentX,
      this.lineSize = 2,
      this.aspectRatio,
      this.defs})
      : coords = coords ?? Coordinates.def;
  final Coordinates coords;
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
    final bytes = await getFutureImage(size, defs, coords, lineSize * 2);

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
              widget.coords.xMin, widget.coords.xMax, widget.currentX) *
          s.width;
      final yPos =
          inverseLerp(widget.coords.yMax, widget.coords.yMin, y) * s.height;
      final description = describe(widget.currentX, y);
      yield Tuple3(Offset(xPos, yPos), description, Color(c));
    }
  }

  Iterable<Tuple3<Offset, double, Color>> getDerivatives(Size s) sync* {
    for (var i = 0; i < widget.defs.length; i++) {
      final F = widget.defs[i].func;
      final D = widget.defs[i].deriv;
      if (D == null) continue;
      final c = widget.defs[i].color;
      final xPos = inverseLerp(
              widget.coords.xMin, widget.coords.xMax, widget.currentX) *
          s.width;
      final yPos = inverseLerp(
              widget.coords.yMax, widget.coords.yMin, F(widget.currentX)) *
          s.height;
      // The derivative works for an 1:1 cartesian plane, which isn't the case always
      // We need to scale it accordingly
      final xSize = s.width / widget.coords.xSize;
      final ySize = s.height / widget.coords.ySize;
      final d = D(widget.currentX) * (ySize / xSize);
      yield Tuple3(Offset(xPos, yPos), d, Color(c));
    }
  }

  Iterable<Tuple3<Offset, String, Color>> getNames(Size s) sync* {
    for (var i = 0; i < widget.defs.length; i++) {
      final F = widget.defs[i].func;
      final name = widget.defs[i].name;
      if (name == null) continue;
      final c = widget.defs[i].color;
      final yPos = inverseLerp(
              widget.coords.yMax, widget.coords.yMin, F(widget.coords.yMin)) *
          s.height;
      yield Tuple3(Offset(0, yPos), name, Color(c));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
        aspectRatio: widget.aspectRatio ??
            widget.coords.aspectRatio,
        child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
          currentSize = (constraints.biggest * 2).ceil();
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
