import 'package:meta/meta.dart';
import 'package:flutter/material.dart' show Size;

@immutable
class IntSize {
  const IntSize(int width, int height)
      : width = width ?? 0,
        height = height ?? 0;
  final int width;
  final int height;
  factory IntSize.round(Size s) => IntSize(s.width.round(), s.height.round());
  factory IntSize.floor(Size s) => IntSize(s.width.floor(), s.height.floor());
  factory IntSize.ceil(Size s) => IntSize(s.width.ceil(), s.height.ceil());

  @override
  int get hashCode {
    var result = 17;

    result = 31 * result + width.hashCode;
    result = 31 * result + height.hashCode;

    return result;
  }

  @override
  bool operator ==(other) {
    if (other is IntSize) return width == other.width && height == other.height;
    return false;
  }
}
