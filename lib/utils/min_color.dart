import 'package:meta/meta.dart';

@immutable
class MinColor {
  const MinColor(int value) : value = value & 0xFFFFFFFF;
  final int value;

  /// The alpha channel of this color in an 8 bit value.
  ///
  /// A value of 0 means this color is fully transparent. A value of 255 means
  /// this color is fully opaque.
  static alphaVal(int value) => (0xff000000 & value) >> 24;
  int get alpha => alphaVal(value);

  /// The red channel of this color in an 8 bit value.
  static redVal(int value) => (0x00ff0000 & value) >> 16;
  int get red => redVal(value);

  /// The green channel of this color in an 8 bit value.
  static greenVal(int value) => (0x0000ff00 & value) >> 8;
  int get green => greenVal(value);

  /// The blue channel of this color in an 8 bit value.
  static blueVal(int value) => (0x000000ff & value) >> 0;
  int get blue => blueVal(value);
}
