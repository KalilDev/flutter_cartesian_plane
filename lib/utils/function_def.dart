import 'package:meta/meta.dart';
import 'package:flutter/material.dart' show Color;
import 'typedefs.dart';

@immutable
class FunctionDef {
  const FunctionDef(
      {this.func, this.deriv, this.color, this.hash, this.describe, this.name});
  final MathFunc func;
  final MathFunc deriv;
  final PointDescriber describe;
  final String name;
  final Color color;
  final int hash;

  @override
  int get hashCode => hash ?? super.hashCode;

  @override
  bool operator ==(other) {
    if (other is FunctionDef) {
      if (hash != null && other.hash != null) {
        return hash == other.hash;
      }
      return identical(this, other);
    }

    return false;
  }
}
