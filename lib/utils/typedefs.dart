import 'package:efficient_uint8_list/efficient_uint8_list.dart' show PackedUint8List;
import 'dart:async' show FutureOr;
import '../cartesian_computation.dart' show PixelDataMessage;

typedef MathFunc = double Function(double x);
typedef PointDescriber = String Function(double x, double y);
typedef ImageConversor = FutureOr<PackedUint8List> Function(PixelDataMessage msg);