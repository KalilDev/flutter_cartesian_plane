import 'package:meta/meta.dart';

@immutable
class Coordinates {
  const Coordinates(this.xMin, this.yMin, this.xMax, this.yMax);
  const Coordinates.named(this.xMin, this.yMin, this.xMax, this.yMax);

  static const Coordinates def = Coordinates(-1, -1, 1, 1);

  final double xMin;
  final double yMin;
  final double xMax;
  final double yMax;
  double get xSize => xMin.abs() + xMax.abs();
  double get ySize => yMin.abs() + yMax.abs();
  double get aspectRatio => xSize/ySize;
}